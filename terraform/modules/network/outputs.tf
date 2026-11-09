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

output "sg_lambdas_id" {
  description = "Grupo de seguridad general de las Lambdas"
  value       = aws_security_group.lambdas.id
}

output "sg_lambda_cartelera_id" {
  description = "Grupo de seguridad de la Lambda Consultar cartelera"
  value       = aws_security_group.lambda_cartelera.id
}

output "sg_rds_proxy_id" {
  description = "Grupo de seguridad de RDS Proxy"
  value       = aws_security_group.rds_proxy.id
}

output "sg_aurora_id" {
  description = "Grupo de seguridad de Aurora"
  value       = aws_security_group.aurora.id
}

output "sg_redis_id" {
  description = "Grupo de seguridad de ElastiCache Redis"
  value       = aws_security_group.redis.id
}