# Outputs exposed by the RDS module

output "db_endpoint" {
  description = "DB connection endpoint (address:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "DB hostname (without port)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "DB port"
  value       = aws_db_instance.main.port
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}
