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

#Cola de ventas pagadas
resource "aws_sqs_queue" "ventas" {
  name                       = "${local.prefijo}-cola-ventas"
  visibility_timeout_seconds = 180 # 6 veces el timeout de registrar venta (30 s)
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ventas_fallidos.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name = "${local.prefijo}-cola-ventas"
  }
}
#Cola de avisos de venta
resource "aws_sqs_queue" "avisos" {
  name                      = "${local.prefijo}-cola-avisos"
  message_retention_seconds = 345600 # 4 días exactos (RNF-13)
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "${local.prefijo}-cola-avisos"
  }
}