provider "google" {
  project = "clauks-188222"
  region  = "us-central1"
}

# Create a VPC
resource "google_compute_network" "gke_network" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

# Create a Subnet
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  network       = google_compute_network.gke_network.self_link
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
}

# Create a GKE Cluster with only default node pool
resource "google_container_cluster" "gke_cluster" {
  name     = "cluster-1"
  location = "us-central1"

  network    = google_compute_network.gke_network.self_link
  subnetwork = google_compute_subnetwork.gke_subnet.self_link

  # Set to 1 for a single node in default pool
  initial_node_count = 1
  
  # Disable autopilot
  enable_autopilot = false

  # Enable logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Enable private cluster (Optional)
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }

  # Additional configurations
  release_channel {
    channel = "REGULAR"
  }
  
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.4.0.0/14"
    services_ipv4_cidr_block = "10.8.0.0/20"
  }
  
  node_config {
    machine_type = "e2-micro"
    disk_size_gb = 20
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}

# IAM Permissions for GKE
resource "google_project_iam_member" "gke_roles" {
  for_each = toset([
    "roles/container.admin",
    "roles/container.clusterAdmin",
    "roles/container.developer"
  ])
  project = "clauks-188222"
  role    = each.value
  member  = "user:taufique@gmail.com"
}