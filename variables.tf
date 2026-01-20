# =============================================================================
# Organization Configuration
# =============================================================================

variable "org_id" {
  description = "GCP Organization ID (mutually exclusive with folder_id)"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "GCP Folder ID (mutually exclusive with org_id)"
  type        = string
  default     = ""
}

variable "billing_account_id" {
  description = "GCP Billing Account ID"
  type        = string
}

# =============================================================================
# Project Configuration
# =============================================================================

variable "project_name" {
  description = "Project name (used as prefix for project ID)"
  type        = string
  default     = "telecom-app"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "asia-northeast3"
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "main_subnet_cidr" {
  description = "CIDR for main subnet (GKE, VMs)"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR for GKE pods secondary range"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "CIDR for GKE services secondary range"
  type        = string
  default     = "10.8.0.0/20"
}

variable "serverless_subnet_cidr" {
  description = "CIDR for serverless VPC connector subnet"
  type        = string
  default     = "10.1.0.0/28"
}

# =============================================================================
# Optional Features
# =============================================================================

variable "create_state_bucket" {
  description = "Create GCS bucket for Terraform state (set false if using Terraform Cloud)"
  type        = bool
  default     = false
}
