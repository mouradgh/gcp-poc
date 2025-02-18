# AlloyDB Cluster
resource "google_alloydb_cluster" "gigawatt" {
  cluster_id = "alloydb-cluster"
  location   = var.region
  network_config {
    network = "default"
  }

  initial_user {
    user     = var.database_user
    password = var.database_password
  }

}

# Primary Instance
resource "google_alloydb_instance" "primary" {
  cluster       = google_alloydb_cluster.gigawatt.name
  instance_id   = "alloydb-instance"
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = 2
  }

  depends_on = [google_alloydb_cluster.gigawatt]
}

# Create a local file with SQL commands
resource "local_file" "init_db" {
  filename = "${path.module}/init.sql"
  content  = <<-EOT
    CREATE SCHEMA IF NOT EXISTS gigawatt;
    
    CREATE TABLE IF NOT EXISTS gigawatt.raw_files (
      id SERIAL PRIMARY KEY,
      filename VARCHAR(255) NOT NULL,
      content jsonb NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  EOT
}

