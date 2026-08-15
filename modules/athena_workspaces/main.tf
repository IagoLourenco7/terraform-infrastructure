# ============================================================
# Module: athena_workspaces
# Bucket de workspaces (1 pasta por usuário/domínio), workgroups
# do Athena isolados e lifecycle agressivo (FinOps: query results
# não precisam viver muito tempo).
# ============================================================

resource "aws_s3_bucket" "athena_workspaces" {
  bucket = "athena-workspaces-${var.environment}"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "athena-query-results"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_workspaces" {
  bucket                  = aws_s3_bucket.athena_workspaces.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "workspace_cleanup" {
  bucket = aws_s3_bucket.athena_workspaces.id

  rule {
    id     = "cleanup-old-results"
    status = "Enabled"

    expiration {
      days = var.results_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Um workgroup isolado por usuário dentro do domínio
resource "aws_athena_workgroup" "user_workgroup" {
  for_each = toset(var.usernames)

  name = "wg-${var.domain_name}-${each.value}-${var.environment}"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false # custo: desligado no POC

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_workspaces.id}/${var.domain_name}/${each.value}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Domain = var.domain_name
    User   = each.value
  }
}
