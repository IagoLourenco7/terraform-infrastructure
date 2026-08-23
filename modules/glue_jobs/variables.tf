variable "domain_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "pipeline_role_arn" {
  type        = string
  description = "ARN da role de pipeline (do módulo domain_iam) - única com permissão de escrita"
}

variable "bronze_bucket" {
  type = string
}

variable "silver_bucket" {
  type = string
}

variable "gold_bucket" {
  type = string
}

variable "audit_logs_bucket" {
  type = string
}

# --- FinOps: dimensionamento POC ---
variable "worker_type" {
  type    = string
  default = "G.2X"
}

variable "number_of_workers" {
  type    = number
  default = 2
}

variable "job_timeout_minutes" {
  type    = number
  default = 15
}
