output "instance_id" {
  description = "ID de l'instance RDS"
  value       = aws_db_instance.main.id
}

output "endpoint" {
  description = "Endpoint de connexion RDS"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "Adresse hostname RDS"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "Port de connexion"
  value       = aws_db_instance.main.port
}

output "arn" {
  description = "ARN de l'instance RDS"
  value       = aws_db_instance.main.arn
}

output "db_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.main.db_name
}

output "secret_arn" {
  description = "ARN du secret Secrets Manager"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "kms_key_id" {
  description = "ID de la clé KMS"
  value       = aws_kms_key.rds.id
}

output "backup_vault_name" {
  description = "Nom du backup vault"
  value       = aws_backup_vault.rds.name
}
