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
resource "google_alloydb_instance" "gigawatt" {
  cluster       = google_alloydb_cluster.gigawatt.name
  instance_id   = "alloydb-instance"
  instance_type = "PRIMARY"

  machine_config {
    cpu_count = 2
  }

  depends_on = [google_alloydb_cluster.gigawatt]
}

