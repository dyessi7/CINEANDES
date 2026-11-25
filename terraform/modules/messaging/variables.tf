variable "proyecto" {
  description = "Nombre del proyecto, usado en nombres y etiquetas de los recursos"
  type        = string
}

variable "entorno" {
  description = "Nombre del entorno: dev o prod"
  type        = string
}

variable "correo_ses" {
  description = "Correo del remitente verificado en SES (se pasa desde el pipeline, nunca hardcodeado)"
  type        = string
}
