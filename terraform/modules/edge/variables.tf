variable "proyecto" {
  description = "Nombre del proyecto, para el prefijo de los recursos"
  type        = string
}

variable "entorno" {
  description = "Entorno de despliegue, para el prefijo de los recursos"
  type        = string
}

variable "funciones_invoke_arn" {
  description = "ARN de invocación de cada función Lambda, para las integraciones de API Gateway"
  type        = map(string)
}

variable "funciones_nombre" {
  description = "Nombre de cada función Lambda, para el permiso de invocación de API Gateway"
  type        = map(string)
}
