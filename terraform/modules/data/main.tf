# Prefijo de nombres
locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# Grupo de subredes de Aurora
resource "aws_db_subnet_group" "aurora" {
  name        = "${local.prefijo}-aurora"
  description = "Grupo de subredes privadas para Aurora MySQL"
  subnet_ids  = var.subredes_datos_ids

  tags = {
    Name = "${local.prefijo}-aurora"
  }
}

#  AURORA

# Clúster Aurora MySQL

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${local.prefijo}-aurora"

  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.08.0"

  database_name   = "cineandes"
  master_username = "admin_cineandes"

  manage_master_user_password = true

  storage_encrypted                   = true
  backup_retention_period             = 30
  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [var.sg_aurora_id]

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }

  # Entorno dev: permite destruir la infraestructura desde el pipeline.
  skip_final_snapshot = true
  deletion_protection = false
}

# Instancia writer de Aurora en la primera zona

resource "aws_rds_cluster_instance" "writer" {
  identifier           = "${local.prefijo}-aurora-writer"
  cluster_identifier   = aws_rds_cluster.aurora.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora.engine
  engine_version       = aws_rds_cluster.aurora.engine_version
  availability_zone    = var.zonas[0]
  db_subnet_group_name = aws_db_subnet_group.aurora.name
  publicly_accessible  = false

  tags = {
    Name = "${local.prefijo}-aurora-writer"
  }
}

# Instancia reader de Aurora en la segunda zona

resource "aws_rds_cluster_instance" "reader" {
  identifier           = "${local.prefijo}-aurora-reader"
  cluster_identifier   = aws_rds_cluster.aurora.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora.engine
  engine_version       = aws_rds_cluster.aurora.engine_version
  availability_zone    = var.zonas[1]
  db_subnet_group_name = aws_db_subnet_group.aurora.name
  publicly_accessible  = false

  depends_on = [aws_rds_cluster_instance.writer]

  tags = {
    Name = "${local.prefijo}-aurora-reader"
  }
}

# RDS PROXY

# Rol IAM para RDS Proxy

resource "aws_iam_role" "rds_proxy" {
  name = "${local.prefijo}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

# Política IAM para leer el secreto de Aurora

resource "aws_iam_role_policy" "rds_proxy_secrets" {
  name = "${local.prefijo}-rds-proxy-secrets"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
      }
    ]
  })
}

# RDS Proxy

resource "aws_db_proxy" "aurora" {
  name                   = "${local.prefijo}-rds-proxy"
  engine_family          = "MYSQL"
  debug_logging          = false
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = var.subredes_datos_ids
  vpc_security_group_ids = [var.sg_rds_proxy_id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
  }

  depends_on = [
    aws_iam_role_policy.rds_proxy_secrets
  ]

  tags = {
    Name = "${local.prefijo}-rds-proxy"
  }
}

# Grupo de destino de RDS Proxy

resource "aws_db_proxy_default_target_group" "aurora" {
  db_proxy_name = aws_db_proxy.aurora.name

  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

# Asociar el clúster Aurora como destino de RDS Proxy

resource "aws_db_proxy_target" "aurora" {
  db_proxy_name         = aws_db_proxy.aurora.name
  target_group_name     = aws_db_proxy_default_target_group.aurora.name
  db_cluster_identifier = aws_rds_cluster.aurora.id
}

# REDIS

# Grupo de subredes de Redis

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${local.prefijo}-redis"
  description = "Grupo de subredes privadas para Redis"
  subnet_ids  = var.subredes_datos_ids

  tags = {
    Name = "${local.prefijo}-redis"
  }
}

# Clúster de replicación Redis

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.prefijo}-redis"
  description          = "Clúster Redis para CineAndes"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t3.micro"

  num_cache_clusters = 2

  port                 = 6379
  parameter_group_name = "default.redis7"

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [var.sg_redis_id]

  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Name = "${local.prefijo}-redis"
  }
}