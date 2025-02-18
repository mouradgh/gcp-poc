resource "google_storage_bucket" "gigawatt_functions_bucket" {
  name          = "gigawatt-functions-bucket"
  location      = var.region
  project       = var.project
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "gigawatt_raw_data" {
  name          = "gigawatt-raw-data"
  location      = var.region
  project       = var.project
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "gigawatt_processed_data" {
  name          = "gigawatt-processed-data"
  location      = var.region
  project       = var.project
  uniform_bucket_level_access = true
}


