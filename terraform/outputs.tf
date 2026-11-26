output "funciones_nombre" {
  description = "Nombre en AWS de cada función Lambda, que Ansible usa para desplegar y verificar el código"
  value       = module.compute.funciones_nombre
}