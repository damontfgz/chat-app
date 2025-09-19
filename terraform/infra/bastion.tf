locals {
  bastion = {
    bastion_image = "yahoo-el-8-v202503132355"
    key_rotation_period = {
      disk = "7776000s" # 90 days
    }
  }
}

data "google_compute_image" "pcp" {
  name    = local.bastion.bastion_image
  project = "gcp-pcp-gcp-image-sharing-prod"
}

resource "google_compute_firewall" "bastion_iap_ssh" {
  name          = "cfw-bastion-iap"
  direction     = "INGRESS"
  network       = google_compute_network.region.self_link
  description   = "Allow ssh access to bastion host through IAP"
  source_ranges = ["35.235.240.0/20"] # Google IAP ingress IP range
  target_tags   = ["bastion"]

  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
}

resource "google_compute_instance_template" "bastion" {
  name_prefix  = "cit-bastion-"
  machine_type = "e2-small"
  tags         = ["bastion"]

  disk {
    source_image = data.google_compute_image.pcp.id
    boot         = true
    auto_delete  = true
    disk_size_gb = 20

  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.self_link
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  # SBC-GCP-4006
  can_ip_forward = false

  # SBC-GCP-4008
  shielded_instance_config {
    enable_secure_boot          = true
    enable_integrity_monitoring = true
  }

  metadata = {
    # SBC-GCP-4003
    block-project-ssh-keys = "TRUE"
    # SBC-GCP-4004
    enable-oslogin = "TRUE"
    # https://git.ouryahoo.com/pages/athens/athenz-guide/service_x509_credentials_gcp_gce/#specify-calypso-profile-while-launching-the-instances-through-metadata-item
    accessProfile = "udp-bastion"
  }
}

resource "google_compute_region_instance_group_manager" "bastion" {
  name                      = "cgm-bastion"
  base_instance_name        = "cin-bastion"
  region                    = var.region
  target_size               = 1
  wait_for_instances        = true
  wait_for_instances_status = "UPDATED"

  version {
    instance_template = google_compute_instance_template.bastion.self_link
    name              = "primary"
  }

  update_policy {
    minimal_action        = "REPLACE"
    type                  = "PROACTIVE"
    max_unavailable_fixed = 3
  }

  timeouts {
    create = "5m"
  }

  lifecycle {
    replace_triggered_by = [
      google_compute_instance_template.bastion
    ]
  }
}

resource "google_service_account" "bastion" {
  create_ignore_already_exists = true
  account_id                   = data.athenz_service.bastion.name
}

data "athenz_service" "bastion" {
  domain = "home.dtian01"
  name   = "udp-bastion"
}
