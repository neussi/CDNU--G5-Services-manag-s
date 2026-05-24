# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CROSS-REGION REPLICATION (optionnel)
# Réplication vers région de backup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# IAM Role pour réplication
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0

  name = "${var.project_name}-${var.cdnu_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cdnu_name}-replication-role"
  }
}

# Policy pour réplication
resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0

  name = "s3-replication-policy"
  role = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.main.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = [
          "${var.replication_destination_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Configuration de réplication
resource "aws_s3_bucket_replication_configuration" "main" {
  count = var.enable_replication ? 1 : 0

  depends_on = [aws_s3_bucket_versioning.main]

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    # Répliquer tous les objets
    filter {}

    destination {
      bucket        = var.replication_destination_bucket_arn
      storage_class = "STANDARD_IA"

      # Réplication des delete markers
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      # Métriques de réplication
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    # Suppression des objets aussi répliquée
    delete_marker_replication {
      status = "Enabled"
    }
  }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLOUDWATCH ALARM - Réplication Lag
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  count = var.enable_replication ? 1 : 0

  alarm_name          = "${var.project_name}-${var.cdnu_name}-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Maximum"
  threshold           = 900 # 15 minutes
  alarm_description   = "S3 replication lag trop élevé"
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.main.id
    RuleId     = "replicate-all"
  }
}
