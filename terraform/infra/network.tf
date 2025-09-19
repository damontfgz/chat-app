resource "google_compute_network" "region" {
  name                    = "demo-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "main" {
  name                       = "main-subnet"
  ip_cidr_range              = "10.2.0.0/16"
  region                     = var.region
  network                    = google_compute_network.region.self_link
  private_ip_google_access   = true
}

resource "google_compute_subnetwork" "google_services" {
  name                     = "google-services-subnet"
  ip_cidr_range            = "10.3.0.0/16"
  region                   = var.region
  network                  = google_compute_network.region.id
  private_ip_google_access = true
}

resource "google_compute_address" "nat" {
  name         = "nat-address"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_router" "main" {
  name    = "nat-router"
  network = google_compute_network.region.self_link
  region  = var.region
}

resource "google_compute_router_nat" "main" {
  name                               = "main-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
  nat_ips                            = [google_compute_address.nat.self_link]
}