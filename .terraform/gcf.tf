# Cloud Run Functions requires a zip file of the function source code
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/xml-to-json-converter"
  output_path = "${path.module}/../functions/xml-to-json-converter.zip"
}

# Upload the zip file to the functions bucket
resource "google_storage_bucket_object" "function_archive" {
  name   = "functions/xml-to-json-converter-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.gigawatt_functions_bucket.name
  source = data.archive_file.function_source.output_path

  # Add content hash to force update only when zip content changes
  content_type = "application/zip"
  metadata = {
    source_hash = data.archive_file.function_source.output_base64sha256
  }
}

# Create the Cloud Run Function
resource "google_cloudfunctions2_function" "xml_to_json_function" {
  name        = "xml-to-json-converter"
  location    = var.region
  description = "Function to convert XML files to JSON"

  build_config {
    runtime     = "python310"
    entry_point = "convert_xml_to_json"
    source {
      storage_source {
        bucket = google_storage_bucket.gigawatt_functions_bucket.name
        object = google_storage_bucket_object.function_archive.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds      = 60
    service_account_email = "terraform-test@fourth-walker-449914-t1.iam.gserviceaccount.com"
  }

  # Trigger the function when a new file is uploaded to the raw data bucket
  event_trigger {
    trigger_region = var.region
    event_type    = "google.cloud.storage.object.v1.finalized"
    event_filters {
      attribute = "bucket"
      value    = "gigawatt-raw-data"
    }
  }

  # Add source code hash to trigger updates only when code changes
  labels = {
    deployment = substr(data.archive_file.function_source.output_md5, 0, 63)
  }
}  