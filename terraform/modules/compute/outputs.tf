output "funciones_arn" {
  description = "ARN de cada función, para las colas, EventBridge y las alarmas"
  value       = { for k, f in aws_lambda_function.funcion : k => f.arn }
}

output "funciones_invoke_arn" {
  description = "ARN de invocación de cada función, para API Gateway"
  value       = { for k, f in aws_lambda_function.funcion : k => f.invoke_arn }
}

output "funciones_nombre" {
  description = "Nombre de cada función en AWS"
  value       = { for k, f in aws_lambda_function.funcion : k => f.function_name }
}

output "roles_nombre" {
  description = "Rol de cada función, para agregarle permisos específicos"
  value       = { for k, r in aws_iam_role.funcion : k => r.name }
}