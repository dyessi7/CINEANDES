output "vpc_id" {
  description = "Identificador de la VPC"
  value       = aws_vpc.principal.id
}

output "vpc_cidr" {
  description = "Rango de direcciones de la VPC"
  value       = aws_vpc.principal.cidr_block
}

output "subredes_publicas_ids" {
  description = "Identificadores de las subredes públicas, una por zona"
  value       = aws_subnet.publica[*].id
}

output "subredes_aplicacion_ids" {
  description = "Identificadores de las subredes de aplicación, una por zona"
  value       = aws_subnet.aplicacion[*].id
}

output "subredes_datos_ids" {
  description = "Identificadores de las subredes de datos, una por zona"
  value       = aws_subnet.datos[*].id
}