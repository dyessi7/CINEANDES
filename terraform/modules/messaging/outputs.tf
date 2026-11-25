output "cola_ventas_arn" {
  description = "ARN de la cola de ventas pagadas: permisos de confirmar venta y registrar venta, y disparador de registrar venta"
  value       = aws_sqs_queue.ventas.arn
}

output "cola_ventas_url" {
  description = "URL de la cola de ventas pagadas, a la que confirmar venta envía los mensajes"
  value       = aws_sqs_queue.ventas.url
}

output "cola_avisos_arn" {
  description = "ARN de la cola de avisos de venta: permisos de registrar venta y notificar, y disparador de notificar"
  value       = aws_sqs_queue.avisos.arn
}

output "cola_avisos_url" {
  description = "URL de la cola de avisos de venta, a la que registrar venta envía los avisos"
  value       = aws_sqs_queue.avisos.url
}

output "cola_ventas_fallidos_nombre" {
  description = "Nombre de la cola de fallidos de ventas, para la alarma de CloudWatch del módulo operations"
  value       = aws_sqs_queue.ventas_fallidos.name
}

output "ses_identidad_arn" {
  description = "ARN de la identidad de SES, para el permiso de notificar de enviar correos"
  value       = aws_ses_email_identity.remitente.arn
}