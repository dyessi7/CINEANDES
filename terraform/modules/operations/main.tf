# 1. Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# 2. SNS
# 2.1 Tema de alarmas
resource "aws_sns_topic" "alarmas" {
  name = "${local.prefijo}-alarmas"
}

resource "aws_sns_topic_subscription" "correo" {
  topic_arn = aws_sns_topic.alarmas.arn
  protocol  = "email"
  endpoint  = var.correo_alarmas
}

# 2.2 Tema de alarmas en us-east-1, solo para la alarma de WAF
resource "aws_sns_topic" "alarmas_waf" {
  provider = aws.us_east_1
  name     = "${local.prefijo}-alarmas-waf"
}

resource "aws_sns_topic_subscription" "correo_waf" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alarmas_waf.arn
  protocol  = "email"
  endpoint  = var.correo_alarmas
}