# 1. Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# 2. Grupo de seguridad de las Lambdas
resource "aws_security_group" "lambdas" {
  name        = "${local.prefijo}-sg-lambdas"
  description = "Conexiones de salida permitidas para las funciones Lambda"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.prefijo}-sg-lambdas"
  }
}

# 2.1 Salida HTTPS: pasarela de pagos (por el NAT) y colas SQS (por el VPC Endpoint)
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.lambdas.id
  description       = "HTTPS hacia la pasarela de pagos y servicios de AWS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# 2.2 Salida a la base de datos: solo hacia RDS Proxy dentro de la VPC
resource "aws_vpc_security_group_egress_rule" "mysql" {
  security_group_id = aws_security_group.lambdas.id
  description       = "MySQL hacia RDS Proxy dentro de la VPC"
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = var.vpc_cidr
}

# 2.3 Salida al caché: solo hacia Redis dentro de la VPC
resource "aws_vpc_security_group_egress_rule" "redis" {
  security_group_id = aws_security_group.lambdas.id
  description       = "Redis hacia ElastiCache dentro de la VPC"
  ip_protocol       = "tcp"
  from_port         = 6379
  to_port           = 6379
  cidr_ipv4         = var.vpc_cidr
}