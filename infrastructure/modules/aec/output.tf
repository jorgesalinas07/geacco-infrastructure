output "redis_endpoint" {
  description = "The endpoint of redis"
  value       = aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address
}
