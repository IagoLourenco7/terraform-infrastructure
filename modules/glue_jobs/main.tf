# ============================================================
# Module: glue_jobs
# Cria o bucket de scripts + os AWS Glue Jobs (extratores e
# transformações Bronze->Silver->Gold). Os scripts em si são
# enviados pro S3 pelo CI/CD do repo data-lake-batch-pipeline
# (não pelo Terraform) - aqui só criamos os recursos AWS Glue
# apontando pro local onde o script vai estar.
#
# POC sizing (FinOps): G.2X, 2 workers, timeout 15 min -
# revise conforme o volume de dados crescer.
# ============================================================

resource "aws_s3_bucket" "scripts" {
  bucket = "glue-scripts-${var.domain_name}-${var.environment}"

  tags = {
    Domain      = var.domain_name
    Environment = var.environment
    Purpose     = "glue-job-scripts"
  }
}

resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  script_base_url = "s3://${aws_s3_bucket.scripts.id}/scripts"
  shared_libs_url = "s3://${aws_s3_bucket.scripts.id}/scripts/shared_libs.zip"

  # Argumentos comuns a todo job: bookmark habilitado (evita
  # reprocessar dados já lidos) e libs compartilhadas
  # (quality_checks.py + client_config.py empacotados pelo
  # workflow de deploy do data-lake-batch-pipeline).
  common_arguments = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--job-language"        = "python"
    "--extra-py-files"      = local.shared_libs_url
    "--TempDir"             = "s3://${aws_s3_bucket.scripts.id}/temp/"
  }
}

# --------------------------------------------------------------
# Extratores (Bronze)
# --------------------------------------------------------------
resource "aws_glue_job" "extract_rds" {
  name              = "${var.domain_name}-extract-rds-${var.environment}"
  role_arn          = var.pipeline_role_arn
  glue_version      = "4.0"
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type
  timeout           = var.job_timeout_minutes

  command {
    name            = "glueetl"
    script_location = "${local.script_base_url}/generic_extractors/extract_rds.py"
    python_version  = "3"
  }

  default_arguments = merge(local.common_arguments, {
    "--bronze_bucket" = var.bronze_bucket
  })

  tags = { Domain = var.domain_name, Layer = "bronze", Source = "rds" }
}

resource "aws_glue_job" "extract_api" {
  name              = "${var.domain_name}-extract-api-${var.environment}"
  role_arn          = var.pipeline_role_arn
  glue_version      = "4.0"
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type
  timeout           = var.job_timeout_minutes

  command {
    name            = "glueetl"
    script_location = "${local.script_base_url}/generic_extractors/extract_api.py"
    python_version  = "3"
  }

  default_arguments = merge(local.common_arguments, {
    "--bronze_bucket" = var.bronze_bucket
  })

  tags = { Domain = var.domain_name, Layer = "bronze", Source = "api" }
}

resource "aws_glue_job" "extract_dynamodb" {
  name              = "${var.domain_name}-extract-dynamodb-${var.environment}"
  role_arn          = var.pipeline_role_arn
  glue_version      = "4.0"
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type
  timeout           = var.job_timeout_minutes

  command {
    name            = "glueetl"
    script_location = "${local.script_base_url}/generic_extractors/extract_dynamodb.py"
    python_version  = "3"
  }

  default_arguments = merge(local.common_arguments, {
    "--bronze_bucket" = var.bronze_bucket
  })

  tags = { Domain = var.domain_name, Layer = "bronze", Source = "dynamodb" }
}

# --------------------------------------------------------------
# Transformações
# --------------------------------------------------------------
resource "aws_glue_job" "bronze_to_silver" {
  name              = "${var.domain_name}-bronze-to-silver-${var.environment}"
  role_arn          = var.pipeline_role_arn
  glue_version      = "4.0"
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type
  timeout           = var.job_timeout_minutes

  command {
    name            = "glueetl"
    script_location = "${local.script_base_url}/bronze_to_silver.py"
    python_version  = "3"
  }

  default_arguments = merge(local.common_arguments, {
    "--bronze_bucket"     = var.bronze_bucket
    "--silver_bucket"     = var.silver_bucket
    "--audit_logs_bucket" = var.audit_logs_bucket
  })

  tags = { Domain = var.domain_name, Layer = "silver" }
}

resource "aws_glue_job" "silver_to_gold" {
  name              = "${var.domain_name}-silver-to-gold-${var.environment}"
  role_arn          = var.pipeline_role_arn
  glue_version      = "4.0"
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type
  timeout           = var.job_timeout_minutes

  command {
    name            = "glueetl"
    script_location = "${local.script_base_url}/silver_to_gold.py"
    python_version  = "3"
  }

  default_arguments = merge(local.common_arguments, {
    "--silver_bucket"     = var.silver_bucket
    "--gold_bucket"       = var.gold_bucket
    "--audit_logs_bucket" = var.audit_logs_bucket
  })

  tags = { Domain = var.domain_name, Layer = "gold" }
}

# --------------------------------------------------------------
# Orquestração básica: Silver depende do sucesso do Bronze,
# Gold depende do sucesso do Silver. Os extratores continuam
# disparados manualmente/por schedule externo (variam por fonte).
# --------------------------------------------------------------
resource "aws_glue_trigger" "bronze_to_silver_trigger" {
  name     = "${var.domain_name}-trigger-bronze-to-silver-${var.environment}"
  type     = "CONDITIONAL"
  enabled  = true

  predicate {
    conditions {
      job_name = aws_glue_job.extract_rds.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.bronze_to_silver.name
  }
}

resource "aws_glue_trigger" "silver_to_gold_trigger" {
  name    = "${var.domain_name}-trigger-silver-to-gold-${var.environment}"
  type    = "CONDITIONAL"
  enabled = true

  predicate {
    conditions {
      job_name = aws_glue_job.bronze_to_silver.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.silver_to_gold.name
  }
}
