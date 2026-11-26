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

# 3. Alarmas de las Lambdas
resource "aws_cloudwatch_metric_alarm" "lambda_errores" {
  for_each = var.funciones_nombre

  alarm_name          = "${local.prefijo}-${each.key}-errores"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarmas.arn]

  # porcentaje de errores en 5 minutos
  metric_query {
    id          = "porcentaje"
    expression  = "100 * errores / llamadas"
    return_data = true
  }

  metric_query {
    id = "errores"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      period      = 300
      stat        = "Sum"
      dimensions  = { FunctionName = each.value }
    }
  }

  metric_query {
    id = "llamadas"
    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Invocations"
      period      = 300
      stat        = "Sum"
      dimensions  = { FunctionName = each.value }
    }
  }
}

# 4. Alarmas de la API
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.prefijo}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarmas.arn]

  # porcentaje de errores 5xx en 5 minutos
  metric_query {
    id          = "porcentaje"
    expression  = "100 * errores / peticiones"
    return_data = true
  }

  metric_query {
    id = "errores"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "5xx"
      period      = 300
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }

  metric_query {
    id = "peticiones"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      period      = 300
      stat        = "Sum"
      dimensions  = { ApiId = var.api_id }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "api_4xx" {
  alarm_name          = "${local.prefijo}-api-4xx"
  namespace           = "AWS/ApiGateway"
  metric_name         = "4xx"
  dimensions          = { ApiId = var.api_id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 20
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarmas.arn]
}