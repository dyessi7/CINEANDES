variable "proyecto" {
  description = "Nombre del proyecto, usado en los nombres de las funciones"
  type        = string
}

variable "entorno" {
  description = "Entorno en el que se crean las funciones: dev o prod"
  type        = string
}

variable "vpc_id" {
  description = "VPC donde se crea el grupo de seguridad de las Lambdas"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango de la VPC, para limitar las conexiones internas de las Lambdas"
  type        = string
}

variable "subredes_aplicacion_ids" {
  description = "Subredes privadas de aplicación donde se ejecutan las Lambdas"
  type        = list(string)
}