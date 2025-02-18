# Enable required APIs
resource "google_project_service" "alloydb" {
  for_each = toset([
    "alloydb.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "alloydb_network" {
  name                    = "alloydb-network"
  auto_create_subnetworks = false
  depends_on = [google_project_service.alloydb]
}

# Subnet
resource "google_compute_subnetwork" "alloydb_subnet" {
  name          = "alloydb-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.alloydb_network.id
}

# Private IP range
resource "google_compute_global_address" "private_ip_alloydb" {
  name          = "alloydb-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.alloydb_network.id
}

# VPC Peering
resource "google_service_networking_connection" "alloydb_vpc_connection" {
  network                 = google_compute_network.alloydb_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloydb.name]
}

# AlloyDB Cluster
resource "google_alloydb_cluster" "default" {
  cluster_id = "alloydb-cluster"
  location   = var.region
  network_config {
    network = google_compute_network.alloydb_network.id
  }

  initial_user {
    user     = var.database_user
    password = var.database_password
  }

  depends_on = [google_service_networking_connection.alloydb_vpc_connection]
}

# Primary Instance
resource "google_alloydb_instance" "primary" {
  cluster       = google_alloydb_cluster.default.name
  instance_id   = "alloydb-instance"
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = 2
  }

  depends_on = [google_alloydb_cluster.default]
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

