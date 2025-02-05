# variables.tf - Terraform Variables for Secure Configuration

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "East US"
}

variable "subscription_id_connectivity" {
  description = "Azure Subscription ID for Connectivity"
  type        = string
}

variable "subscription_id_prod" {
  description = "Azure Subscription ID for Production"
  type        = string
}

variable "subscription_id_nonprod" {
  description = "Azure Subscription ID for NonProduction"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 365
}
