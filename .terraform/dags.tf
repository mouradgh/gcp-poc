# Get the DAGs bucket from the Composer environment
data "google_composer_environment" "composer_env" {
  name    = google_composer_environment.composer.name
  region  = var.region
  project = var.project
}

# Upload DAGs to the Composer environment
resource "google_storage_bucket_object" "dag_files" {
  for_each = fileset("${path.module}/../dags/", "*.py")

  name   = "dags/${each.value}"
  source = "${path.module}/../dags/${each.value}"
  bucket = split("/", data.google_composer_environment.composer_env.config.0.dag_gcs_prefix)[2]

  # Add content-based hash to force update when DAG content changes
  content_type = "application/x-python"
  detect_md5hash = true
} 