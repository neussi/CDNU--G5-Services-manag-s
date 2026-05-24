# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECURITY (G5)
# Sécurité additionnelle pour RDS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Secrets Manager pour credentials RDS
resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${var.project_name}/rds/master-credentials"
  description = "Credentials master pour RDS PostgreSQL"

  kms_key_id = aws_kms_key.rds.id
  recovery_window_in_days = 0
  tags = {
    Name = "${var.project_name}-rds-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  secret_string = jsonencode({
    username = var.master_username
    password = var.master_password
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = "cdnu_db"
  })
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLOUDWATCH LOG GROUPS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name              = "/aws/rds/instance/${var.project_name}-postgres/postgresql"
  retention_in_days = 30
  #  kms_key_id        = aws_kms_key.rds.arn

  tags = {
    Name = "${var.project_name}-rds-postgresql-logs"
  }
}

resource "aws_cloudwatch_log_group" "rds_upgrade" {
  name              = "/aws/rds/instance/${var.project_name}-postgres/upgrade"
  retention_in_days = 30
  #  kms_key_id        = aws_kms_key.rds.arn

  tags = {
    Name = "${var.project_name}-rds-upgrade-logs"
  }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLOUDWATCH ALARMS SÉCURITÉ
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Alarme connexions anormales
resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.project_name}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alerte si trop de connexions à la base"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-connections-alarm"
  }
}

# Alarme CPU élevé
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alerte si CPU RDS > 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

# Alarme stockage faible
resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5368709120" # 5 GB en bytes
  alarm_description   = "Alerte si stockage < 5GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-storage-alarm"
  }
}
