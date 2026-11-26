output "funciones_nombre" {
  description = "Nombre en AWS de cada función Lambda, que Ansible usa para desplegar y verificar el código"
  value       = module.compute.funciones_nombre
}
output "api_url" {
  description = "Dirección directa de la API, para pruebas"
  value       = module.edge.api_url
}

output "cloudfront_dominio" {
  description = "Dirección pública de la web"
  value       = module.edge.cloudfront_dominio
}
