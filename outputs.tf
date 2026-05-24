# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OUTPUTS GLOBALES - SERVICES MANAGÉS (G5)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

output "rds_endpoint" {
  description = "Endpoint de connexion pour la base de données PostgreSQL"
  value       = module.database.endpoint
}

output "rds_secret_arn" {
  description = "ARN du secret stocké dans AWS Secrets Manager contenant les identifiants"
  value       = module.database.secret_arn
}

output "ecr_repository_url" {
  description = "URL du registre de conteneurs ECR pour héberger les images Docker"
  value       = aws_ecr_repository.api.repository_url
}

output "s3_buckets" {
  description = "Informations sur les buckets S3 créés pour chaque CDNU"
  value = {
    for k, v in module.storage : k => {
      bucket_id          = v.bucket_id
      bucket_arn         = v.bucket_arn
      bucket_domain_name = v.bucket_domain_name
    }
  }
}
