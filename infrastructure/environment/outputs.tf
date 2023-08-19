output "base_ecr_ui" {
  value = module.base_project_ECR.ecr_uri
}

output "web_public_ip" {
  description = "The public IP address of the web server"
  value       = aws_eip.geacco_EC2_eip[0].public_ip

  depends_on = [aws_eip.geacco_EC2_eip]
}

output "web_public_dns" {
  description = "The public DNS address of the web server"
  value       = aws_eip.geacco_EC2_eip[0].public_dns

  depends_on = [aws_eip.geacco_EC2_eip]
}

output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.geacco_db_instance.address
}

output "redis_endpoint" {
  description = "The endpoint of redis"
  value       = aws_elasticache_replication_group.base_project_EC_replication_group.primary_endpoint_address
}

// This will output the database port
output "database_port" {
  description = "The port of the database"
  value       = aws_db_instance.geacco_db_instance.port
}

# base_ecr_ui = "388813176377.dkr.ecr.us-east-1.amazonaws.com/geacco_app_stg"
# database_endpoint = "geaccodbstg.ciutmnlgyney.us-east-1.rds.amazonaws.com"
# database_port = 5432
# web_public_dns = "ec2-44-198-243-84.compute-1.amazonaws.com"
# web_public_ip = "44.198.243.84"

# Ip publica de github
