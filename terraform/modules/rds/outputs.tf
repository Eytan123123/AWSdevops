# Outputs exposed by the RDS module

# Consumed by: module.ec2 (the application needs the DB endpoint to connect).
# The EC2 user_data will inject this into the container as DB_HOST.
output "db_endpoint" {
  description = "DB connection endpoint (address:port)"
  value       = aws_db_instance.main.endpoint
}

# Consumed by: nothing right now — alternate form of db_endpoint, exposed for flexibility.
output "db_address" {
  description = "DB hostname (without port)"
  value       = aws_db_instance.main.address
}

# Consumed by: nothing right now — alternate form, exposed for flexibility.
output "db_port" {
  description = "DB port"
  value       = aws_db_instance.main.port
}

# Consumed by: nothing in Terraform — informational (used by humans in AWS Console).
output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}
