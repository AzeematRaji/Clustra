variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for the bootstrap state storage"
  type        = string
  default     = "canadacentral"
}

variable "resource_group_name" {
  description = "Resource group owning the Terraform state storage"
  type        = string
  default     = "rg-clustra-tfstate-cac"
}

variable "storage_account_name" {
  description = "Globally unique storage account name (no hyphens), e.g. stclustratfstatecac or with suffix"
  type        = string
}

variable "allowed_principal_ids" {
  description = "Entra ID Object IDs for the two engineers and CI"
  type        = list(string)
}