output "test_db_endpoint" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.test-db.endpoint
}
