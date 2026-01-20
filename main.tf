terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Terraform Cloud/Scalr backend
  cloud {
    # organization = "your-org"  # Set via CLI or env: TF_CLOUD_ORGANIZATION
    workspaces {
      name = "telecom-app-bootstrap"
    }
  }
}

provider "google" {
  # Uses ADC or service account with org-level permissions
  # No project specified - this creates the project
}

# =============================================================================
# Random suffix for globally unique project ID
# =============================================================================

resource "random_id" "project" {
  byte_length = 2
}

# =============================================================================
# GCP Project
# =============================================================================

resource "google_project" "main" {
  name            = "${var.project_name}-${var.environment}"
  project_id      = "${var.project_name}-${var.environment}-${random_id.project.hex}"
  org_id          = var.org_id != "" ? var.org_id : null
  folder_id       = var.folder_id != "" ? var.folder_id : null
  billing_account = var.billing_account_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Enable Required APIs
# =============================================================================

resource "google_project_service" "apis" {
  for_each = toset([
    # Compute & Container
    "compute.googleapis.com",
    "container.googleapis.com",

    # Database
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",

    # Serverless
    "run.googleapis.com",
    "cloudscheduler.googleapis.com",
    "vpcaccess.googleapis.com",

    # Security
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",

    # Storage
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",

    # Monitoring
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
  ])

  project                    = google_project.main.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

# =============================================================================
# Terraform State Bucket (for infra-application if not using Terraform Cloud)
# =============================================================================

resource "google_storage_bucket" "terraform_state" {
  count = var.create_state_bucket ? 1 : 0

  name          = "${google_project.main.project_id}-terraform-state"
  project       = google_project.main.project_id
  location      = var.region
  force_destroy = false

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.apis["storage.googleapis.com"]]
}
