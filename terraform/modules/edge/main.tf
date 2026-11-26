# 1. Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"

  # Grupos de usuarios de Cognito y para qué sirve cada uno
  grupos_cognito = {
    clientes       = "Clientes de la web y la app móvil"
    cajeros        = "Cajeros de las sedes"
    administracion = "Administración: reportes y auditoría"
  }
}

# 2. COGNITO: inicio de sesión de clientes, cajeros y administración
# 2.1 Grupo de usuarios: inicio de sesión por correo
resource "aws_cognito_user_pool" "principal" {
  name = "${local.prefijo}-usuarios"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # En desarrollo debe poder destruirse con el pipeline
  deletion_protection = "INACTIVE"
}

# 2.2 Cliente de aplicación: lo usan la web, la app y las cajas
# Sin secreto: son clientes públicos que no pueden guardarlo
resource "aws_cognito_user_pool_client" "web" {
  name         = "${local.prefijo}-cliente"
  user_pool_id = aws_cognito_user_pool.principal.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  # No revelar si un correo existe o no al fallar el inicio de sesión
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# 2.3 Grupos: clientes, cajeros y administración
resource "aws_cognito_user_group" "grupo" {
  for_each = local.grupos_cognito

  name         = each.key
  description  = each.value
  user_pool_id = aws_cognito_user_pool.principal.id
}

# 3. API GATEWAY: puerta de entrada de la API (HTTP API)
# 3.1 Región actual, para armar la dirección del emisor de tokens de Cognito
data "aws_region" "actual" {}

# 3.2 Registros de acceso: base para detectar accesos anómalos (RNF-20)
resource "aws_cloudwatch_log_group" "api_acceso" {
  name              = "/aws/apigateway/${local.prefijo}-api"
  retention_in_days = 30
}

# 3.3 API
resource "aws_apigatewayv2_api" "principal" {
  name          = "${local.prefijo}-api"
  protocol_type = "HTTP"
}

# 3.4 Autorizador JWT: valida los tokens de Cognito en cada petición protegida
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.principal.id
  name             = "${local.prefijo}-cognito"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.web.id]
    issuer   = "https://cognito-idp.${data.aws_region.actual.region}.amazonaws.com/${aws_cognito_user_pool.principal.id}"
  }
}

# 3.5 Etapa por defecto: publica los cambios solo y guarda los registros de acceso
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.principal.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_acceso.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      path             = "$context.path"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      authorizerError  = "$context.authorizer.error"
    })
  }
}

# 4. RUTAS DE LA API
# 4.1 Rutas expuestas: las demás funciones las activan colas y EventBridge
# CloudFront no quita el prefijo /api, por eso todas las rutas lo incluyen
locals {
  rutas = {
    consultar_cartelera = { metodo = "GET", ruta = "/api/cartelera", publica = true }
    consultar_mapa      = { metodo = "GET", ruta = "/api/mapa", publica = true }
    bloquear_butaca     = { metodo = "POST", ruta = "/api/butacas/bloquear", publica = false }
    confirmar_venta     = { metodo = "POST", ruta = "/api/ventas/confirmar", publica = false }
    reportes            = { metodo = "GET", ruta = "/api/reportes", publica = false }
  }
}

# 4.2 Integraciones: conectan cada ruta con su función
resource "aws_apigatewayv2_integration" "funcion" {
  for_each = local.rutas

  api_id                 = aws_apigatewayv2_api.principal.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = var.funciones_invoke_arn[each.key]
  payload_format_version = "2.0"
}

# 4.3 Rutas: las públicas sin autorizador, las demás exigen token de Cognito
resource "aws_apigatewayv2_route" "ruta" {
  for_each = local.rutas

  api_id    = aws_apigatewayv2_api.principal.id
  route_key = "${each.value.metodo} ${each.value.ruta}"
  target    = "integrations/${aws_apigatewayv2_integration.funcion[each.key].id}"

  authorization_type = each.value.publica ? "NONE" : "JWT"
  authorizer_id      = each.value.publica ? null : aws_apigatewayv2_authorizer.cognito.id
}

# 4.4 Permiso para que API Gateway invoque cada función, solo desde su ruta
resource "aws_lambda_permission" "api" {
  for_each = local.rutas

  statement_id  = "PermitirApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.funciones_nombre[each.key]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.principal.execution_arn}/*/${each.value.metodo}${each.value.ruta}"
}

# 5. S3: bucket privado de la web y los pósters
# 5.1 Bucket: el prefijo evita escribir un nombre fijo (S3 exige nombres únicos en todo el mundo)
resource "aws_s3_bucket" "web" {
  bucket_prefix = "${local.prefijo}-web-"

  # Solo desarrollo: permite que destroy borre el bucket aunque tenga archivos
  force_destroy = true
}

# 5.2 Bloqueo total de acceso público
resource "aws_s3_bucket_public_access_block" "web" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5.3 Cifrado en reposo con claves administradas por S3
resource "aws_s3_bucket_server_side_encryption_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 5.4 Sin ACL: el único control de acceso es la política del bucket
resource "aws_s3_bucket_ownership_controls" "web" {
  bucket = aws_s3_bucket.web.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 6. WAF: firewall asociado a CloudFront (debe crearse en us-east-1)
# 6.1 Lista de control web con reglas administradas y límite por IP
resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1

  name  = "${local.prefijo}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Límite de peticiones por IP en 5 minutos: frena abusos y fuerza bruta
  rule {
    name     = "limite-por-ip"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefijo}-limite-por-ip"
      sampled_requests_enabled   = true
    }
  }

  # Conjunto común: scripts maliciosos y ataques frecuentes (RNF-19)
  rule {
    name     = "conjunto-comun"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefijo}-conjunto-comun"
      sampled_requests_enabled   = true
    }
  }

  # Inyección SQL (RNF-19)
  rule {
    name     = "inyeccion-sql"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefijo}-inyeccion-sql"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.prefijo}-waf"
    sampled_requests_enabled   = true
  }
}

# 6.2 Registros de WAF: AWS exige el prefijo aws-waf-logs- y la región us-east-1 (RNF-20)
resource "aws_cloudwatch_log_group" "waf" {
  provider = aws.us_east_1

  name              = "aws-waf-logs-${local.prefijo}"
  retention_in_days = 30
}

# 6.3 Solo se guardan las peticiones bloqueadas, que son las que sirven para detectar accesos anómalos
resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  provider = aws.us_east_1

  resource_arn            = aws_wafv2_web_acl.cloudfront.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  logging_filter {
    default_behavior = "DROP"

    filter {
      behavior    = "KEEP"
      requirement = "MEETS_ANY"

      condition {
        action_condition {
          action = "BLOCK"
        }
      }
    }
  }
}

# 7. CLOUDFRONT: única entrada de la web, los pósters y la API
# 7.1 Políticas administradas por AWS, buscadas por nombre
data "aws_cloudfront_cache_policy" "con_cache" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "sin_cache" {
  name = "Managed-CachingDisabled"
}

# Reenvía lo que envía el navegador (incluido Authorization) menos Host, que API Gateway rechazaría
data "aws_cloudfront_origin_request_policy" "todo_menos_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

# 7.2 OAC: CloudFront firma sus peticiones a S3, así el bucket puede ser privado
resource "aws_cloudfront_origin_access_control" "web" {
  name                              = "${local.prefijo}-oac"
  description                       = "Acceso de CloudFront al bucket de la web"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 7.3 Distribución con dos orígenes: S3 (web y pósters) y API Gateway
resource "aws_cloudfront_distribution" "principal" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.prefijo} web y api"
  default_root_object = "index.html"

  # Incluye puntos de presencia en Sudamérica, cerca de los clientes (RNF-21, RNF-25)
  price_class = "PriceClass_All"

  web_acl_id = aws_wafv2_web_acl.cloudfront.arn

  origin {
    origin_id                = "s3-web"
    domain_name              = aws_s3_bucket.web.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.web.id
  }

  origin {
    origin_id = "api-gateway"
    # La API entrega https://dominio: CloudFront espera solo el dominio
    domain_name = replace(aws_apigatewayv2_api.principal.api_endpoint, "https://", "")

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Por defecto todo va a S3, con caché y redirigiendo HTTP a HTTPS (RNF-16)
  default_cache_behavior {
    target_origin_id       = "s3-web"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.con_cache.id
  }

  # Las rutas /api/* van a API Gateway, sin caché y con el encabezado Authorization
  ordered_cache_behavior {
    path_pattern             = "/api/*"
    target_origin_id         = "api-gateway"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.sin_cache.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.todo_menos_host.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Certificado por defecto de CloudFront: no permite exigir TLS 1.2 como mínimo
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
