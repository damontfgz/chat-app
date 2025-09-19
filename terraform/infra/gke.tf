data "google_project" "project" {
}

resource "google_service_account" "cluster" {
  create_ignore_already_exists = true
  account_id                   = "gke-cluster"
}

resource "google_project_iam_member" "artifactry_reader" {
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cluster.email}"
  project = local.project_id
}

# resource "google_container_cluster" "main" {
#   name                      = "demo-gke-cluster"
#   location                  = var.region
#   network                   = google_compute_network.region.self_link
#   subnetwork                = google_compute_subnetwork.main.self_link
#   datapath_provider         = "ADVANCED_DATAPATH"
#   deletion_protection = false
#   remove_default_node_pool = true
#
#   initial_node_count       = 1
#
#
#   workload_identity_config {
#     workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
#   }
#
#   # SBC-GCP-3011
#   enable_intranode_visibility = true
#
#   release_channel {
#     channel = "STABLE"
#   }
#
#   master_auth {
#     client_certificate_config {
#       issue_client_certificate = false
#     }
#   }
#
#     # SBC-GCP-3013
#   master_authorized_networks_config {
#   }
#
#   control_plane_endpoints_config {
#     dns_endpoint_config {
#       allow_external_traffic = true
#     }
#   }
#
#   private_cluster_config {
#     # SBC-GCP-3015
#     enable_private_endpoint = true
#     # SBC-GCP-3014
#     enable_private_nodes = true
#
#     private_endpoint_subnetwork = google_compute_subnetwork.main.self_link
#   }
#
#   node_config {
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     service_account = google_service_account.cluster.email
#     workload_metadata_config {
#       mode = "GKE_METADATA"
#     }
#
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#     shielded_instance_config {
#       # SBC-GCP-4025
#       enable_secure_boot = true
#       # SBC-GCP-4024
#       enable_integrity_monitoring = true
#     }
#
#     metadata = {
#       # SBC-GCP-4017
#       disable-legacy-endpoints = "true"
#     }
#   }
#
# }
#
# resource "google_container_node_pool" "main" {
#   name_prefix       = "api-knp-"
#   location          = var.region
#   cluster           = google_container_cluster.main.name
#   autoscaling {
#     min_node_count = 1
#     max_node_count = 1
#   }
#
#   node_config {
#     # preemptible  = true
#     machine_type = "e2-standard-2"
#
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     service_account = google_service_account.cluster.email
#     workload_metadata_config {
#       mode = "GKE_METADATA"
#     }
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#
#     shielded_instance_config {
#       # SBC-GCP-4025
#       enable_secure_boot = true
#       # SBC-GCP-4024
#       enable_integrity_monitoring = true
#     }
#
#   }
# }

# resource "google_container_node_pool" "gpu" {
#   name_prefix       = "gpu-knp-"
#   location          = var.region
#   cluster           = google_container_cluster.main.name
#   autoscaling {
#     total_min_node_count = "1"
#     total_max_node_count = "1"
#   }
#
#   node_config {
#     image_type   = "cos_containerd"
#     machine_type = "n1-standard-4"
#
#     disk_size_gb = "100"
#     disk_type    = "pd-standard"
#
#     guest_accelerator {
#       type  = "nvidia-tesla-t4"
#       count = 1
#     }
#
#     # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
#     service_account = google_service_account.cluster.email
#     # service_account = "gke-cluster@gcp-home-dtian01.iam.gserviceaccount.com"
#     workload_metadata_config {
#       mode = "GKE_METADATA"
#     }
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#
#     shielded_instance_config {
#       # SBC-GCP-4025
#       enable_secure_boot = true
#       # SBC-GCP-4024
#       enable_integrity_monitoring = true
#     }
#
#     metadata = {
#       disable-legacy-endpoints = "true"
#     }
#
#   }
# }