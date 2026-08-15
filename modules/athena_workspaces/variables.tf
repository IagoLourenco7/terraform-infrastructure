variable "domain_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "usernames" {
  type        = list(string)
  description = "Usuários que terão workspace próprio no Athena"
}

variable "results_retention_days" {
  type        = number
  default     = 30
  description = "Dias até apagar resultados antigos de query (FinOps)"
}
