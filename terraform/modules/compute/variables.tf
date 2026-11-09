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