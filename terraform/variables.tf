variable "proyecto" {
  description = "Nombre del proyecto, usado en nombres y etiquetas de los recursos"
  type        = string
  default     = "andes"
}

variable "entorno" {
  description = "Nombre del entorno: dev o prod"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "zonas" {
  description = "Zonas de disponibilidad donde se reparten los recursos"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}