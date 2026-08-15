variable "domain_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "billing_mode" {
  type        = string
  default     = "PAY_PER_REQUEST"
  description = "PAY_PER_REQUEST (POC) ou PROVISIONED (produção)"
}

variable "read_capacity" {
  type    = number
  default = 5
}

variable "write_capacity" {
  type    = number
  default = 5
}

variable "gsi_read_capacity" {
  type    = number
  default = 5
}

variable "gsi_write_capacity" {
  type    = number
  default = 5
}

variable "enable_ttl" {
  type        = bool
  default     = true
  description = "Auto-expira registros antigos (custo)"
}
