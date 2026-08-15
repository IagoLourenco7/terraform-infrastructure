variable "domain_name" {
  type        = string
  description = "Nome do domínio (ex: customers, orders)"
}

variable "environment" {
  type        = string
  description = "poc, dev, staging, production"
}

variable "trusted_principal_arns" {
  type        = list(string)
  description = "ARNs de usuários/roles que podem assumir as roles deste domínio"
}

variable "layer_bucket_arns" {
  type        = list(string)
  description = "Lista de ARNs dos buckets bronze/silver/gold do domínio"
}

variable "layer_bucket_arns_by_layer" {
  type        = map(string)
  description = "Map layer -> bucket ARN, ex: { bronze = arn, silver = arn, gold = arn }"
}

variable "audit_logs_bucket_arn" {
  type        = string
  description = "ARN do bucket central de audit logs"
}
