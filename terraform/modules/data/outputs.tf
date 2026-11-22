# AURORA

output "aurora_cluster_endpoint" {
  description = "Endpoint de escritura del cluster Aurora"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Endpoint de lectura del cluster Aurora"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "aurora_cluster_id" {
  description = "Identificador del cluster Aurora"
  value       = aws_rds_cluster.aurora.id
}

output "aurora_cluster_arn" {
  description = "ARN del clúster Aurora"
  value       = aws_rds_cluster.aurora.arn
}

output "aurora_secret_arn" {
  description = "ARN del secreto maestro de Aurora"
  value       = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
}

# RDS PROXY

output "rds_proxy_endpoint" {
  description = "Endpoint de conexion del RDS Proxy"
  value       = aws_db_proxy.aurora.endpoint
}

output "rds_proxy_arn" {
  description = "ARN del RDS Proxy"
  value       = aws_db_proxy.aurora.arn
}

output "rds_proxy_endpoint_lectura" {
  description = "Endpoint de lectura del RDS Proxy"
  value       = aws_db_proxy_endpoint.aurora_lectura.endpoint
}

# REDIS

output "redis_endpoint" {
  description = "Endpoint principal del cluster Redis"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Puerto de conexion de Redis"
  value       = aws_elasticache_replication_group.redis.port
}