variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "poc"
}

variable "domain_name" {
  type        = string
  default     = "customers"
  description = "Domínio/setor de exemplo para o POC. Duplique este ambiente por domínio."
}

variable "domain_analysts" {
  type        = list(string)
  default     = []
  description = "Lista de usernames que terão workspace de analyst no domínio"
}

variable "trusted_principal_arns" {
  type        = list(string)
  default     = []
  description = "ARNs de usuários/roles autorizados a assumir as roles do domínio"
}
