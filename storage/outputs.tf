# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OUTPUTS - MODULE STORAGE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

output "bucket_id" {
  description = "ID du bucket S3"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Domain name du bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name du bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "logs_bucket_id" {
  description = "ID du bucket de logs"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "ARN du bucket de logs"
  value       = aws_s3_bucket.logs.arn
}
