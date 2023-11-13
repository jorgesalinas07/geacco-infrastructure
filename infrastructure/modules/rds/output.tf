output "database_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.geacco_db_instance.address
}

output "database_port" {
  description = "The port of the database"
  value       = aws_db_instance.geacco_db_instance.port
}
