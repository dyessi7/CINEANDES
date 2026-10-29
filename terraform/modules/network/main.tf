# 1. Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# 2. VPC
resource "aws_vpc" "principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefijo}-vpc"
  }
}

# 3. Internet Gateway: puerta entre la VPC e internet
resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-igw"
  }
}

# Subredes
# Rangos resultantes con vpc_cidr = 10.0.0.0/16

# 4. Subredes Públicas: 10.0.0.0/24 (zona A), 10.0.1.0/24 (zona B)
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

# 5. Subredes de Aplicación: 10.0.10.0/24 (zona A), 10.0.11.0/24 (zona B)
resource "aws_subnet" "aplicacion" {
  count             = length(var.zonas)
  vpc_id            = aws_vpc.principal.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.zonas[count.index]

  tags = {
    Name = "${local.prefijo}-aplicacion-${var.zonas[count.index]}"
  }
}

# 6. Subredes de Datos: 10.0.20.0/24 (zona A), 10.0.21.0/24 (zona B)
resource "aws_subnet" "datos" {
  count             = length(var.zonas)
  vpc_id            = aws_vpc.principal.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.zonas[count.index]

  tags = {
    Name = "${local.prefijo}-datos-${var.zonas[count.index]}"
  }
}

# 7. IP pública fija para cada NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.zonas)
  domain = "vpc"

  tags = {
    Name = "${local.prefijo}-eip-nat-${var.zonas[count.index]}"
  }

  depends_on = [aws_internet_gateway.principal]
}

# 8. Un NAT Gateway por zona, ubicado en la subred pública
resource "aws_nat_gateway" "principal" {
  count         = length(var.zonas)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.publica[count.index].id #Aqui se ponen las NATs dentro de la subnet publica

  tags = {
    Name = "${local.prefijo}-nat-${var.zonas[count.index]}"
  }

  depends_on = [aws_internet_gateway.principal]
}

# 9. TABLAS
# 9.1 Tabla de rutas pública: salida a internet por el Internet Gateway
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal.id
  }

  tags = {
    Name = "${local.prefijo}-rt-publica"
  }
}

resource "aws_route_table_association" "publica" {
  count          = length(var.zonas)
  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}

# 9.2 Tablas de rutas de aplicación: cada zona sale a internet por el NAT de su misma zona
resource "aws_route_table" "aplicacion" {
  count  = length(var.zonas)
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.principal[count.index].id
  }

  tags = {
    Name = "${local.prefijo}-rt-aplicacion-${var.zonas[count.index]}"
  }
}

resource "aws_route_table_association" "aplicacion" {
  count          = length(var.zonas)
  subnet_id      = aws_subnet.aplicacion[count.index].id
  route_table_id = aws_route_table.aplicacion[count.index].id
}

# 9.3 Tablas de rutas de datos: sin ruta a internet, solo tráfico dentro de la VPC
resource "aws_route_table" "datos" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-rt-datos"
  }
}

resource "aws_route_table_association" "datos" {
  count          = length(var.zonas)
  subnet_id      = aws_subnet.datos[count.index].id
  route_table_id = aws_route_table.datos.id
}