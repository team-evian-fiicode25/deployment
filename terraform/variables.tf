variable "app_name" {
  description = "Base name used to derive the name of all resources"
  type        = string
  default     = "rideme"
}

variable "document_db_password" {
  description = "Password for the Mongo compatible DB"
  type        = string
  sensitive   = true
}
