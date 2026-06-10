# Outputs exposed by the RDS module — only values consumed elsewhere in the code.

# Consumed by: root outputs.tf (project spec requires exposing the RDS endpoint).
# Will also be consumed by module.ec2 — the user_data injects this as DB_HOST.
output "db_endpoint" {
  description = "DB connection endpoint (address:port)"
  value       = aws_db_instance.main.endpoint
}
