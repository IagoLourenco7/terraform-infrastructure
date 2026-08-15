# ============================================================
# Environment: POC
# Junta todos os módulos para um domínio de exemplo.
# Para outro domínio/cliente, duplique esta pasta e troque
# apenas as variáveis (arquitetura genérica).
# ============================================================

module "audit_logging" {
  source      = "../../modules/audit_logging"
  environment = var.environment
}

module "lake_layers" {
  source      = "../../modules/s3_lake_layers"
  domain_name = var.domain_name
  environment = var.environment
}

module "domain_iam" {
  source = "../../modules/domain_iam"

  domain_name             = var.domain_name
  environment             = var.environment
  trusted_principal_arns  = var.trusted_principal_arns
  layer_bucket_arns       = values(module.lake_layers.bucket_arns)
  layer_bucket_arns_by_layer = module.lake_layers.bucket_arns
  audit_logs_bucket_arn   = module.audit_logging.audit_logs_bucket_arn
}

module "athena_workspaces" {
  source = "../../modules/athena_workspaces"

  domain_name = var.domain_name
  environment = var.environment
  usernames   = var.domain_analysts
}

module "kinesis_stream" {
  source = "../../modules/kinesis_stream"

  domain_name = var.domain_name
  environment = var.environment
  shard_count = 1
}

module "dynamodb_online" {
  source = "../../modules/dynamodb_online"

  domain_name  = var.domain_name
  environment  = var.environment
  billing_mode = "PAY_PER_REQUEST"
}

module "workspace_cleanup" {
  source = "../../modules/workspace_cleanup"

  environment            = var.environment
  workspace_bucket_name  = module.athena_workspaces.workspaces_bucket_name
  workspace_bucket_arn   = "arn:aws:s3:::${module.athena_workspaces.workspaces_bucket_name}"
}
