locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

resource "aws_vpc" "principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefijo}-vpc"
  }
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-igw"
  }
}

# Subredes
# Rangos resultantes con vpc_cidr = 10.0.0.0/16

# Pública:    10.0.0.0/24 (zona A), 10.0.1.0/24 (zona B)
resource "aws_subnet" "publica" {
  count                   = length(var.zonas)
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.zonas[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefijo}-publica-${var.zonas[count.index]}"
  }
}

# Aplicación: 10.0.10.0/24 (zona A), 10.0.11.0/24 (zona B)
resource "aws_subnet" "aplicacion" {
  count             = length(var.zonas)
  vpc_id            = aws_vpc.principal.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.zonas[count.index]

  tags = {
    Name = "${local.prefijo}-aplicacion-${var.zonas[count.index]}"
  }
}

# Datos:      10.0.20.0/24 (zona A), 10.0.21.0/24 (zona B)
resource "aws_subnet" "datos" {
  count             = length(var.zonas)
  vpc_id            = aws_vpc.principal.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.zonas[count.index]

  tags = {
    Name = "${local.prefijo}-datos-${var.zonas[count.index]}"
  }
}

# IP pública fija para cada NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.zonas)
  domain = "vpc"

  tags = {
    Name = "${local.prefijo}-eip-nat-${var.zonas[count.index]}"
  }

  depends_on = [aws_internet_gateway.principal]
}

# Un NAT Gateway por zona, ubicado en la subred pública
resource "aws_nat_gateway" "principal" {
  count         = length(var.zonas)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.publica[count.index].id #Aqui se ponen las NATs dentro de la subnet publica

  tags = {
    Name = "${local.prefijo}-nat-${var.zonas[count.index]}"
  }

  depends_on = [aws_internet_gateway.principal]
}