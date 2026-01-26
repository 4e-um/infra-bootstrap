terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
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
  project = var.project_id
  region  = var.region

  default_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
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
    "cloudtasks.googleapis.com",
    "workflows.googleapis.com",
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

  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

# =============================================================================
# Terraform State Bucket (for infra-application if not using Terraform Cloud)
# =============================================================================

resource "google_storage_bucket" "terraform_state" {
  count = var.create_state_bucket ? 1 : 0

  name          = "${var.project_id}-terraform-state"
  project       = var.project_id
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
