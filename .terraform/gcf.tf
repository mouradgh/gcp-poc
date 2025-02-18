# Cloud Run Functions requires a zip file of the function source code
data "archive_file" "function-source" {
  type        = "zip"
  output_path = "../functions/xml-to-json-converter/function-source.zip"
  source_dir = "../functions/xml-to-json-converter/"
}

# Upload the zip file to the functions bucket
resource "google_storage_bucket_object" "xml_to_json_converter_function_source" {
  name   = "xml-to-json-converter/function-source.zip"
  source = "../functions/xml-to-json-converter/function-source.zip"
  bucket = "gigawatt-functions-bucket"
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
        bucket = "gigawatt-functions-bucket"
        object = "xml-to-json-converter/function-source.zip"
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
}  