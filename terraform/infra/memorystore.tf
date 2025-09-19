resource "google_network_connectivity_service_connection_policy" "memorystore" {
  name          = "nsp-memorystore"
  location      = var.region
  service_class = "gcp-memorystore"
  network       = google_compute_network.region.id

  psc_config {
    subnetworks = [google_compute_subnetwork.google_services.id]
  }
}

resource "google_memorystore_instance" "rag" {
  instance_id = "msi-rag"
  shard_count = 1
  location    = var.region

  deletion_protection_enabled = false
  replica_count               = 0
  node_type                   = "STANDARD_SMALL"
  engine_version              = "VALKEY_8_0"
  mode                        = "CLUSTER"

  desired_auto_created_endpoints {
    network    = google_compute_network.region.id
    project_id = local.project_id
  }

  depends_on = [
    google_network_connectivity_service_connection_policy.memorystore
  ]
}