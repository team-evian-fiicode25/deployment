variable "app_name" {
  description = "Base name used to derive the name of all resources"
  type        = string
  default     = "rideme"
}

variable "my_ip" {
  description = "Your public IP address in CIDR notation (e.g., 123.45.67.89/32)"
  type        = string
}

variable "ssh_key_public" {
  description = "Public SSH key for instance access"
  type        = string
}

variable "document_db_password" {
  description = "Password for the Mongo compatible DB"
  type        = string
  sensitive   = true
}
