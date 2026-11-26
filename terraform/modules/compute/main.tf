# 1. Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# 2. Funciones del sistema: una por responsabilidad
locals {
  funciones = {
    confirmar_venta     = { grupo = "general", tiempo_max = 30, memoria = 256 }
    registrar_venta     = { grupo = "general", tiempo_max = 30, memoria = 256 }
    bloquear_butaca     = { grupo = "general", tiempo_max = 10, memoria = 256 }
    liberar_bloqueos    = { grupo = "general", tiempo_max = 60, memoria = 256 }
    reportes            = { grupo = "general", tiempo_max = 60, memoria = 512 }
    consultar_mapa      = { grupo = "general", tiempo_max = 10, memoria = 256 }
    consultar_cartelera = { grupo = "cartelera", tiempo_max = 10, memoria = 256 }
    notificar           = { grupo = null, tiempo_max = 30, memoria = 128 }
  }

  grupos_seguridad = {
    general   = var.sg_lambdas_id
    cartelera = var.sg_lambda_cartelera_id
  }
}

# 2.1 Variables de entorno: cada función recibe solo las direcciones que usa
locals {
  variables_entorno = {
    confirmar_venta = {
      RDS_PROXY_ENDPOINT = var.rds_proxy_endpoint
      COLA_VENTAS_URL    = var.cola_ventas_url
    }
    registrar_venta = {
      RDS_PROXY_ENDPOINT = var.rds_proxy_endpoint
      COLA_AVISOS_URL    = var.cola_avisos_url
    }
    bloquear_butaca = {
      RDS_PROXY_ENDPOINT = var.rds_proxy_endpoint
    }
    liberar_bloqueos = {
      RDS_PROXY_ENDPOINT = var.rds_proxy_endpoint
    }
    reportes = {
      RDS_PROXY_ENDPOINT = var.rds_proxy_endpoint
    }
    consultar_mapa = {
      RDS_PROXY_ENDPOINT = var.rds_proxy_endpoint
    }
    consultar_cartelera = {
      RDS_PROXY_ENDPOINT_LECTURA = var.rds_proxy_endpoint_lectura
      REDIS_ENDPOINT             = var.redis_endpoint
    }
    notificar = {}
  }
}

# 3. ROLES DE IAM: uno por función, para que cada una tenga solo sus permisos
# 3.1 Rol: solo el servicio de Lambda puede usarlo
resource "aws_iam_role" "funcion" {
  for_each = local.funciones

  name = "${local.prefijo}-${replace(each.key, "_", "-")}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 3.2 Permisos básicos: escribir registros y, si va en la VPC, conectarse a ella
resource "aws_iam_role_policy_attachment" "basico" {
  for_each = local.funciones

  role = aws_iam_role.funcion[each.key].name
  policy_arn = (
    each.value.grupo == null
    ? "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    : "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  )
}

# 3.3 Permisos específicos
locals {
  # El permiso rds-db:connect se escribe con el identificador del proxy (prx-...),
  # que es la última parte de su ARN: arn:aws:rds:region:cuenta:db-proxy:prx-...
  partes_proxy  = split(":", var.rds_proxy_arn)
  conexion_base = "arn:aws:rds-db:${local.partes_proxy[3]}:${local.partes_proxy[4]}:dbuser:${local.partes_proxy[6]}/*"

  usar_base = {
    Effect   = "Allow"
    Action   = "rds-db:connect"
    Resource = local.conexion_base
  }

  permisos = {
    confirmar_venta = [
      local.usar_base,
      { Effect = "Allow", Action = "sqs:SendMessage", Resource = var.cola_ventas_arn },
    ]
    registrar_venta = [
      local.usar_base,
      { Effect = "Allow", Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], Resource = var.cola_ventas_arn },
      { Effect = "Allow", Action = "sqs:SendMessage", Resource = var.cola_avisos_arn },
    ]
    bloquear_butaca     = [local.usar_base]
    liberar_bloqueos    = [local.usar_base]
    reportes            = [local.usar_base]
    consultar_mapa      = [local.usar_base]
    consultar_cartelera = [local.usar_base]
    notificar = [
      { Effect = "Allow", Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], Resource = var.cola_avisos_arn },
      { Effect = "Allow", Action = ["ses:SendEmail", "ses:SendRawEmail"], Resource = var.ses_identidad_arn },
    ]
  }
}

resource "aws_iam_role_policy" "especifico" {
  for_each = local.permisos

  name = "${local.prefijo}-${replace(each.key, "_", "-")}-permisos"
  role = aws_iam_role.funcion[each.key].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value
  })
}

# 4. Empaquetado del código de arranque, compartido por todas las funciones
data "archive_file" "codigo_comun" {
  type        = "zip"
  source_dir  = "${path.root}/../lambdas/comun"
  output_path = "${path.root}/.build/comun.zip"
}

# 5. Registros de cada función en CloudWatch, con retención de 30 días
# Mismo horizonte que los respaldos incrementales
# los datos que deben conservarse más tiempo están en los respaldos de Aurora
resource "aws_cloudwatch_log_group" "funcion" {
  for_each = local.funciones

  name              = "/aws/lambda/${local.prefijo}-${replace(each.key, "_", "-")}"
  retention_in_days = 30
}

# 6. Funciones Lambda: una por cada elemento de la lista
resource "aws_lambda_function" "funcion" {
  for_each = local.funciones

  function_name    = "${local.prefijo}-${replace(each.key, "_", "-")}"
  role             = aws_iam_role.funcion[each.key].arn
  runtime          = "python3.12"
  handler          = "app.handler"
  filename         = data.archive_file.codigo_comun.output_path
  source_code_hash = data.archive_file.codigo_comun.output_base64sha256
  timeout          = each.value.tiempo_max
  memory_size      = each.value.memoria

  environment {
    variables = merge({
      NOMBRE_FUNCION = each.key },
    local.variables_entorno[each.key])
  }

  # Solo las funciones con grupo de seguridad van dentro de la VPC
  dynamic "vpc_config" {
    for_each = each.value.grupo == null ? [] : [each.value.grupo]
    content {
      subnet_ids         = var.subredes_aplicacion_ids
      security_group_ids = [local.grupos_seguridad[vpc_config.value]]
    }
  }

  # Terraform crea la función con el código de arranque y no vuelve a cambiarlo:
  # las actualizaciones del código las hace Ansible
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  depends_on = [
    aws_cloudwatch_log_group.funcion,
    aws_iam_role_policy_attachment.basico,
  ]
}