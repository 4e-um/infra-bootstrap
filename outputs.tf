# =============================================================================
# Project Outputs
# =============================================================================

output "project_id" {
  description = "The created GCP project ID"
  value       = google_project.main.project_id
}

output "project_number" {
  description = "The created GCP project number"
  value       = google_project.main.number
}

output "project_name" {
  description = "The created GCP project name"
  value       = google_project.main.name
}

# =============================================================================
# State Bucket Output
# =============================================================================

output "terraform_state_bucket" {
  description = "GCS bucket for Terraform state (if created)"
  value       = var.create_state_bucket ? google_storage_bucket.terraform_state[0].name : null
}

# =============================================================================
# VPC Outputs
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.main.name
}

output "vpc_self_link" {
  description = "VPC self link"
  value       = google_compute_network.main.self_link
}

output "main_subnet_id" {
  description = "Main subnet ID"
  value       = google_compute_subnetwork.main.id
}

output "main_subnet_name" {
  description = "Main subnet name"
  value       = google_compute_subnetwork.main.name
}

output "main_subnet_self_link" {
  description = "Main subnet self link"
  value       = google_compute_subnetwork.main.self_link
}

output "serverless_subnet_id" {
  description = "Serverless subnet ID"
  value       = google_compute_subnetwork.serverless.id
}

output "serverless_subnet_name" {
  description = "Serverless subnet name"
  value       = google_compute_subnetwork.serverless.name
}

output "region" {
  description = "GCP region"
  value       = var.region
}

# =============================================================================
# Enabled APIs
# =============================================================================

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = [for api in google_project_service.apis : api.service]
}

# =============================================================================
# Next Steps
# =============================================================================

output "next_steps" {
  description = "Instructions for next steps"
  value       = <<-EOT
    Project and VPC created successfully!

    Next steps:
    1. Run infra-application (uses remote state from this workspace)
    2. Run infra-monitor (uses remote state from this workspace)

    GKE credentials command (after infra-application apply):
       gcloud container clusters get-credentials telecom-app-cluster --region ${var.region} --project ${google_project.main.project_id}
  EOT
}
