# Enable required APIs
resource "google_project_service" "composer_apis" {
  for_each = toset([
    "composer.googleapis.com",
    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# Create service account for Composer
resource "google_service_account" "composer_sa" {
  account_id   = "composer-service-account"
  display_name = "Service Account for Cloud Composer"
  depends_on   = [google_project_service.composer_apis]
}

# Grant necessary roles to the service account
resource "google_project_iam_member" "composer_roles" {
  for_each = toset([
    "roles/composer.worker",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ])
  project = var.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.composer_sa.email}"
}

# Create Composer environment
resource "google_composer_environment" "composer" {
  name   = "gigawatt-composer"
  region = var.region
  
  config {
    software_config {
      image_version = "composer-3-airflow-2.10.2"
      
      env_variables = {
        ENVIRONMENT = "test"
      }
    }

    node_config {
      network    = "default"
      subnetwork = "default"
      service_account = google_service_account.composer_sa.email
    }

    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 2
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 2
        storage_gb = 1
      }
      worker {
        cpu        = 0.5
        memory_gb  = 4
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"
  }

  depends_on = [
    google_project_service.composer_apis,
    google_project_iam_member.composer_roles
  ]
}

# # Output the Airflow web UI URL
# output "airflow_uri" {
#   value = google_composer_environment.composer.config[0].dag_gcs_prefix
#   description = "The URI of the Apache Airflow web UI"
# }
