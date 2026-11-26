variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Nombre del entorno"
  type        = string
}

variable "correo_alarmas" {
  description = "Correo que recibe los avisos de las alarmas"
  type        = string
  sensitive   = true
}

variable "funciones_nombre" {
  description = "Nombres de las Lambdas, una alarma por cada una"
  type        = map(string)
}

variable "aurora_cluster_arn" {
  description = "ARN del cluster Aurora para el respaldo"
  type        = string
}

variable "aurora_cluster_id" {
  description = "ID del cluster Aurora para sus alarmas"
  type        = string
}

variable "cola_ventas_fallidos_nombre" {
  description = "Nombre de la cola de ventas fallidas"
  type        = string
}

variable "api_id" {
  description = "ID de la API"
  type        = string
}

variable "waf_nombre" {
  description = "Nombre del WAF de CloudFront"
  type        = string
}