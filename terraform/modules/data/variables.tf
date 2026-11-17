variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno de despliegue: dev o prod"
  type        = string
}

variable "subredes_datos_ids" {
  description = "Identificadores de las subredes privadas de datos"
  type        = list(string)
}

variable "sg_aurora_id" {
  description = "Identificador del grupo de seguridad de Aurora"
  type        = string
}

variable "sg_rds_proxy_id" {
  description = "Identificador del grupo de seguridad de RDS Proxy"
  type        = string
}

variable "sg_redis_id" {
  description = "Identificador del grupo de seguridad de ElastiCache Redis"
  type        = string
}

variable "zonas" {
  description = "Zonas de disponibilidad para las instancias de Aurora"
  type        = list(string)
}