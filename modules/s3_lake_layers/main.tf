# ============================================================
# Module: s3_lake_layers
# Cria os buckets Bronze / Silver / Gold para um domínio,
# já com lifecycle policies pensadas em FinOps.
# ============================================================

locals {
  layers = ["bronze", "silver", "gold"]
}

resource "aws_s3_bucket" "layer" {
  for_each = toset(local.layers)

  bucket = "${var.domain_name}-${each.key}-${var.environment}"

  tags = {
    Domain      = var.domain_name
    Layer       = each.key
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "layer" {
  for_each = aws_s3_bucket.layer

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "layer" {
  for_each = aws_s3_bucket.layer

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "layer" {
  for_each = aws_s3_bucket.layer

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------------------
# Lifecycle policies por camada (FinOps)
# Bronze: dados brutos, retenção longa mas em storage barato
# Silver: dados limpos, retenção média
# Gold: pronto para BI, giro mais rápido pra Intelligent Tiering
# --------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "bronze" {
  bucket = aws_s3_bucket.layer["bronze"].id

  rule {
    id     = "bronze-tiering"
    status = "Enabled"

    transition {
      days          = var.bronze_standard_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.bronze_glacier_days
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = var.bronze_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "silver" {
  bucket = aws_s3_bucket.layer["silver"].id

  rule {
    id     = "silver-tiering"
    status = "Enabled"

    transition {
      days          = var.silver_standard_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.silver_glacier_days
      storage_class = "GLACIER_IR"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "gold" {
  bucket = aws_s3_bucket.layer["gold"].id

  rule {
    id     = "gold-tiering"
    status = "Enabled"

    transition {
      days          = var.gold_intelligent_tiering_days
      storage_class = "INTELLIGENT_TIERING"
    }

    expiration {
      days = var.gold_expiration_days
    }
  }
}
