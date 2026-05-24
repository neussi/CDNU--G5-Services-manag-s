# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BACKUP & RECOVERY (G5)
# Configuration des sauvegardes automatiques et snapshots
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Snapshot manuel initial
#resource "aws_db_snapshot" "initial" {
#  db_instance_identifier = aws_db_instance.main.id
#  db_snapshot_identifier = "${var.project_name}-initial-snapshot"

# tags = {
#   Name        = "${var.project_name}-initial-snapshot"
#   Type        = "Manual"
#    Environment = "production"
# }

#  depends_on = [aws_db_instance.main]
#}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AWS BACKUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Backup Vault
resource "aws_backup_vault" "rds" {
  name        = "${var.project_name}-rds-backup-vault"
  kms_key_arn = aws_kms_key.rds.arn

  tags = {
    Name = "${var.project_name}-backup-vault"
  }
}

# Backup Plan
resource "aws_backup_plan" "rds" {
  name = "${var.project_name}-rds-backup-plan"

  # Backup quotidien
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.rds.name
    schedule          = "cron(0 3 * * ? *)" # 3h du matin UTC

    lifecycle {
      delete_after = 30 # Garder 30 jours
    }

    recovery_point_tags = {
      Type        = "Daily"
      Environment = "production"
    }
  }

  # Backup hebdomadaire (conservation longue)
  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.rds.name
    schedule          = "cron(0 4 ? * SUN *)" # Dimanche 4h

    lifecycle {
      delete_after = 90 # Garder 90 jours
    }

    recovery_point_tags = {
      Type        = "Weekly"
      Environment = "production"
    }
  }

  tags = {
    Name = "${var.project_name}-backup-plan"
  }
}

# IAM Role pour AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-backup-role"
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Selection (quelle ressource sauvegarder)
resource "aws_backup_selection" "rds" {
  name         = "${var.project_name}-rds-selection"
  plan_id      = aws_backup_plan.rds.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    aws_db_instance.main.arn
  ]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLOUDWATCH ALARMS POUR BACKUPS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Alarme si backup échoue
resource "aws_cloudwatch_metric_alarm" "backup_failed" {
  alarm_name          = "${var.project_name}-rds-backup-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alerte si un backup RDS échoue"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ResourceType = "RDS"
  }

  tags = {
    Name = "${var.project_name}-backup-alarm"
  }
}
