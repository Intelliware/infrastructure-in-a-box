output "master_db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.master.db_instance_address
}
