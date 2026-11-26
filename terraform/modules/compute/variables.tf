variable "proyecto" {
  description = "Nombre del proyecto, usado en los nombres de las funciones"
  type        = string
}

variable "entorno" {
  description = "Entorno en el que se crean las funciones: dev o prod"
  type        = string
}

variable "subredes_aplicacion_ids" {
  description = "Subredes privadas de aplicación donde se ejecutan las Lambdas"
  type        = list(string)
}

variable "sg_lambdas_id" {
  description = "Grupo de seguridad general de las Lambdas, creado en el módulo de red"
  type        = string
}

variable "sg_lambda_cartelera_id" {
  description = "Grupo de seguridad de la Lambda Consultar cartelera, creado en el módulo de red"
  type        = string
}

# Salidas del módulo data: para que las funciones lleguen a la base y al caché

variable "rds_proxy_endpoint" {
  description = "Endpoint de lectura y escritura de RDS Proxy, para todas las funciones que usan la base"
  type        = string
}

variable "rds_proxy_endpoint_lectura" {
  description = "Endpoint de solo lectura de RDS Proxy, para leer el catálogo desde la réplica"
  type        = string
}

variable "rds_proxy_arn" {
  description = "ARN de RDS Proxy, para el permiso rds-db:connect de los roles"
  type        = string
}

variable "redis_endpoint" {
  description = "Dirección de ElastiCache Redis, para consultar cartelera"
  type        = string
}

# Salidas del módulo messaging: para que las funciones usen las colas y SES

variable "cola_ventas_arn" {
  description = "ARN de la cola de ventas pagadas"
  type        = string
}

variable "cola_ventas_url" {
  description = "URL de la cola de ventas pagadas, a la que confirmar venta envía los mensajes"
  type        = string
}

variable "cola_avisos_arn" {
  description = "ARN de la cola de avisos de venta"
  type        = string
}

variable "cola_avisos_url" {
  description = "URL de la cola de avisos, a la que registrar venta envía los avisos"
  type        = string
}

variable "ses_identidad_arn" {
  description = "ARN de la identidad de SES, para el permiso de notificar"
  type        = string
}