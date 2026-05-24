# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MODULE: DATABASE (G5)
# RDS PostgreSQL Multi-AZ partagé entre tous les CDNU
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Subnet Group RDS (utilise subnets privés de tous les VPC)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# KMS Key pour encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key pour encryption RDS ${var.project_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-rds-kms"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# Parameter Group RDS
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project_name}-postgres-params"
  family = "postgres15"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name = "${var.project_name}-postgres-params"
  }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RDS INSTANCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres"

  # Engine
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # Database
  db_name  = "cdnu_db"
  username = var.master_username
  password = var.master_password
  port     = 5432

  # High Availability
  multi_az            = var.multi_az
  publicly_accessible = false

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.vpc_security_group_ids

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = "mon:04:00-mon:05:00"

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Deletion Protection
  deletion_protection       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  tags = {
    Name        = "${var.project_name}-postgres"
    Environment = "production"
    Backup      = "daily"
  }

  depends_on = [aws_db_subnet_group.main]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# IAM ROLE POUR MONITORING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
