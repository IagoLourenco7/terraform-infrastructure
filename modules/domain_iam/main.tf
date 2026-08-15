# ============================================================
# Module: domain_iam
# Governança de acesso por domínio:
#  - Owner: aprova acessos, SELECT total no próprio domínio
#  - Analyst: SELECT em Silver/Gold apenas (não vê Bronze)
#  - Pipeline: única role com permissão de escrita (Glue/Lambda)
#  - Ninguém tem INSERT/UPDATE/DELETE manual
# ============================================================

# --------- Trust policy padrão (assumida por usuários federados/SSO) ---------
data "aws_caller_identity" "current" {}

locals {
  # Fallback: se nenhum principal confiavel for informado, usa a conta root
  # (evita erro de "policy sem principals" em testes iniciais do POC)
  effective_trusted_principals = length(var.trusted_principal_arns) > 0 ? var.trusted_principal_arns : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
            identifiers = local.effective_trusted_principals
    }
  }
}

# --------- Role: Domain Owner ---------
resource "aws_iam_role" "domain_owner" {
  name               = "domain-owner-${var.domain_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "domain_owner" {
  statement {
    sid     = "SelectOwnDomain"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = concat(
      [for arn in var.layer_bucket_arns : arn],
      [for arn in var.layer_bucket_arns : "${arn}/*"]
    )
  }

  statement {
    sid       = "AthenaWorkspace"
    effect    = "Allow"
    actions   = ["athena:*"]
    resources = ["*"]
  }

  statement {
    sid       = "DenyWrite"
    effect    = "Deny"
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:PutObjectAcl"]
    resources = [for arn in var.layer_bucket_arns : "${arn}/*"]
  }
}

resource "aws_iam_role_policy" "domain_owner" {
  name   = "domain-owner-policy"
  role   = aws_iam_role.domain_owner.id
  policy = data.aws_iam_policy_document.domain_owner.json
}

# --------- Role: Domain Analyst ---------
resource "aws_iam_role" "domain_analyst" {
  name               = "domain-analyst-${var.domain_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "domain_analyst" {
  statement {
    sid    = "SelectSilverGoldOnly"
    effect = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = concat(
      [for k, arn in var.layer_bucket_arns_by_layer : arn if k != "bronze"],
      [for k, arn in var.layer_bucket_arns_by_layer : "${arn}/*" if k != "bronze"]
    )
  }

  statement {
    sid       = "AthenaOwnWorkspace"
    effect    = "Allow"
    actions   = ["athena:StartQueryExecution", "athena:GetQueryResults", "athena:GetQueryExecution", "athena:StopQueryExecution"]
    resources = ["*"]
  }

  statement {
    sid       = "DenyWrite"
    effect    = "Deny"
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:PutObjectAcl"]
    resources = [for arn in var.layer_bucket_arns : "${arn}/*"]
  }
}

resource "aws_iam_role_policy" "domain_analyst" {
  name   = "domain-analyst-policy"
  role   = aws_iam_role.domain_analyst.id
  policy = data.aws_iam_policy_document.domain_analyst.json
}

# --------- Role: Pipeline (única com escrita - usada por Glue/Lambda) ---------
resource "aws_iam_role" "pipeline" {
  name = "data-engineer-pipeline-${var.domain_name}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = ["glue.amazonaws.com", "lambda.amazonaws.com"]
      }
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "pipeline" {
  statement {
    sid    = "ReadWriteLakeLayers"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"
    ]
    resources = concat(
      [for arn in var.layer_bucket_arns : arn],
      [for arn in var.layer_bucket_arns : "${arn}/*"]
    )
  }

  statement {
    sid       = "ReadSourceRDSDynamo"
    effect    = "Allow"
    actions   = ["rds-db:connect", "dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan"]
    resources = ["*"]
  }

  statement {
    sid       = "GlueCatalog"
    effect    = "Allow"
    actions   = ["glue:*"]
    resources = ["*"]
  }

  statement {
    sid       = "LogsToS3Only"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${var.audit_logs_bucket_arn}/pipeline-logs/*"]
  }
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "pipeline-policy"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline.json
}
