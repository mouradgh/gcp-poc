resource "google_storage_bucket" "poc_test" {
  name          = "poc_test"
  location      = var.region
  project       = var.project
  uniform_bucket_level_access = true
}


