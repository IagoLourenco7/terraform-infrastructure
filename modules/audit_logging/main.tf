# ============================================================
# Module: audit_logging
# Bucket central de auditoria: query history do Athena,
# access requests (cross-domain) e logs de pipeline.
# Tudo em S3 (custo) - sem CloudWatch Logs.
# ============================================================

resource "aws_s3_bucket" "audit_logs" {
  bucket = "data-platform-audit-logs-${var.environment}"

  tags = {
    Environment = var.environment
    Purpose     = "audit-trail"
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Prefixos usados por convenção:
#   athena-query-history/year=YYYY/month=MM/day=DD/
#   access-requests/{pending,approved,denied}/
#   pipeline-logs/
resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "audit-retention"
    status = "Enabled"

    transition {
      days          = var.standard_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.glacier_days
      storage_class = "GLACIER_IR"
    }
  }
}

# Bucket de fila de solicitações de acesso cruzado (v1: aprovação manual)
resource "aws_s3_bucket" "access_requests" {
  bucket = "data-platform-access-requests-${var.environment}"

  tags = {
    Environment = var.environment
    Purpose     = "cross-domain-access-requests"
  }
}

resource "aws_s3_bucket_public_access_block" "access_requests" {
  bucket                  = aws_s3_bucket.access_requests.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
