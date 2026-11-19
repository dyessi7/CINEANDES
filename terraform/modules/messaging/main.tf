#Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

#Cola de mensajes fallidos de ventas pagadas
resource "aws_sqs_queue" "ventas_fallidos" {
  name                      = "${local.prefijo}-cola-ventas-fallidos"
  message_retention_seconds = 1209600 # 14 días: máximo de SQS
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "${local.prefijo}-cola-ventas-fallidos"
  }
}