variable "domain_name" {
  description = "Nome do domínio/setor dono deste lake (ex: customers, orders)"
  type        = string
}

variable "environment" {
  description = "Ambiente: poc, dev, staging, production"
  type        = string
}

# Bronze - retenção longa, custo mínimo
variable "bronze_standard_ia_days" {
  type    = number
  default = 30
}
variable "bronze_glacier_days" {
  type    = number
  default = 90
}
variable "bronze_deep_archive_days" {
  type    = number
  default = 365
}

# Silver - retenção média
variable "silver_standard_ia_days" {
  type    = number
  default = 60
}
variable "silver_glacier_days" {
  type    = number
  default = 180
}

# Gold - analytics-ready
variable "gold_intelligent_tiering_days" {
  type    = number
  default = 90
}
variable "gold_expiration_days" {
  type    = number
  default = 730
}
