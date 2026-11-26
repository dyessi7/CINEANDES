output "tema_alarmas_arn" {
  description = "ARN del tema SNS de alarmas, por si otro modulo quiere enviar avisos"
  value       = aws_sns_topic.alarmas.arn
}

output "plan_respaldo_id" {
  description = "ID del plan de AWS Backup"
  value       = aws_backup_plan.aurora.id
}