output "api_id" {
  description = "ID de la API, para las alarmas de CloudWatch"
  value       = aws_apigatewayv2_api.principal.id
}

output "api_url" {
  description = "Dirección directa de la API, para pruebas"
  value       = aws_apigatewayv2_api.principal.api_endpoint
}

output "cloudfront_dominio" {
  description = "Dirección pública de la web"
  value       = aws_cloudfront_distribution.principal.domain_name
}

output "cloudfront_id" {
  description = "ID de la distribución de CloudFront, para alarmas o invalidaciones de caché"
  value       = aws_cloudfront_distribution.principal.id
}

output "cognito_user_pool_id" {
  description = "ID del grupo de usuarios de Cognito, para la configuración de la web, la app y las cajas"
  value       = aws_cognito_user_pool.principal.id
}

output "cognito_cliente_id" {
  description = "ID del cliente de aplicación de Cognito, para la configuración de la web, la app y las cajas"
  value       = aws_cognito_user_pool_client.web.id
}

output "waf_nombre" {
  description = "Nombre de la lista de control web de WAF, para la alarma de peticiones bloqueadas"
  value       = aws_wafv2_web_acl.cloudfront.name
}
