# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LIFECYCLE POLICIES
# Optimisation des coûts (70% des coûts = S3)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # RÈGLE 1: Transition fichiers anciens vers Glacier
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    filter {}

    # Fichiers de plus de 30 jours → Glacier Instant Retrieval
    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }

    # Fichiers de plus de 90 jours → Glacier Flexible Retrieval
    transition {
      days          = 120
      storage_class = "GLACIER"
    }

    # Fichiers de plus de 180 jours → Deep Archive
    transition {
      days          = 210
      storage_class = "DEEP_ARCHIVE"
    }
  }

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # RÈGLE 2: Suppression anciennes versions
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # RÈGLE 3: Nettoyage uploads incomplets
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # RÈGLE 4: Suppression fichiers temporaires
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  rule {
    id     = "delete-temp-files"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 7
    }
  }

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # RÈGLE 5: Logs (conservation 365 jours)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    # Transition vers IA après 30 jours
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition vers Glacier après 90 jours
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Suppression après 1 an
    expiration {
      days = 365
    }
  }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LIFECYCLE LOGS BUCKET (plus court)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {}

    # Transition vers IA après 30 jours
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Suppression après 90 jours
    expiration {
      days = 90
    }
  }
}