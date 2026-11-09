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

# 10. GRUPOS DE SEGURIDAD
# 10.1 Grupos: uno por cada componente que se conecta por la red
resource "aws_security_group" "lambdas" {
  name        = "${local.prefijo}-sg-lambdas"
  description = "Funciones Lambda: solo conexiones de salida permitidas"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-sg-lambdas"
  }
}

resource "aws_security_group" "lambda_cartelera" {
  name        = "${local.prefijo}-sg-lambda-cartelera"
  description = "Lambda Consultar cartelera: unica funcion que usa ElastiCache Redis"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-sg-lambda-cartelera"
  }
}

resource "aws_security_group" "rds_proxy" {
  name        = "${local.prefijo}-sg-rds-proxy"
  description = "RDS Proxy: recibe conexiones de las Lambdas"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-sg-rds-proxy"
  }
}

resource "aws_security_group" "aurora" {
  name        = "${local.prefijo}-sg-aurora"
  description = "Aurora: recibe conexiones solo de RDS Proxy"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-sg-aurora"
  }
}

resource "aws_security_group" "redis" {
  name        = "${local.prefijo}-sg-redis"
  description = "ElastiCache Redis: recibe conexiones solo de la Lambda Consultar cartelera"
  vpc_id      = aws_vpc.principal.id

  tags = {
    Name = "${local.prefijo}-sg-redis"
  }
}

# 10.2 Reglas de las Lambdas: salida a la pasarela, a SQS y a RDS Proxy
resource "aws_vpc_security_group_egress_rule" "lambdas_https" {
  security_group_id = aws_security_group.lambdas.id
  description       = "Salida HTTPS a la pasarela de pagos y servicios de AWS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "lambdas_a_proxy" {
  security_group_id            = aws_security_group.lambdas.id
  description                  = "Salida a RDS Proxy por el puerto MySQL"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.rds_proxy.id
}

# 10.3 Reglas de la Lambda Consultar cartelera: salida a Redis y a RDS Proxy
resource "aws_vpc_security_group_egress_rule" "cartelera_a_redis" {
  security_group_id            = aws_security_group.lambda_cartelera.id
  description                  = "Salida a ElastiCache Redis por el puerto 6379 para la cartelera"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.redis.id
}

resource "aws_vpc_security_group_egress_rule" "cartelera_a_proxy" {
  security_group_id            = aws_security_group.lambda_cartelera.id
  description                  = "Salida a RDS Proxy por el puerto MySQL cuando el catalogo no esta en cache"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.rds_proxy.id
}

# 10.4 Reglas de RDS Proxy: entrada desde las Lambdas y salida a Aurora
resource "aws_vpc_security_group_ingress_rule" "proxy_desde_lambdas" {
  security_group_id            = aws_security_group.rds_proxy.id
  description                  = "Entrada desde las Lambdas por el puerto MySQL"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.lambdas.id
}

resource "aws_vpc_security_group_ingress_rule" "proxy_desde_cartelera" {
  security_group_id            = aws_security_group.rds_proxy.id
  description                  = "Entrada desde la Lambda Consultar cartelera por el puerto MySQL"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.lambda_cartelera.id
}

resource "aws_vpc_security_group_egress_rule" "proxy_a_aurora" {
  security_group_id            = aws_security_group.rds_proxy.id
  description                  = "Salida a Aurora por el puerto MySQL"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.aurora.id
}

# 10.5 Reglas de Aurora y Redis: solo reciben de su origen autorizado
resource "aws_vpc_security_group_ingress_rule" "aurora_desde_proxy" {
  security_group_id            = aws_security_group.aurora.id
  description                  = "Entrada solo desde RDS Proxy por el puerto MySQL"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.rds_proxy.id
}

resource "aws_vpc_security_group_ingress_rule" "redis_desde_cartelera" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Entrada solo desde la Lambda Consultar cartelera por el puerto 6379"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.lambda_cartelera.id
}