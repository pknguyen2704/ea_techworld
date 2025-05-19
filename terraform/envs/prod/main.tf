provider "google" {
  credentials = file("/Users/andrew/Dev/EnterpriseApp/enterprise-452702-9a94ea6202ce.json")
  project = "enterprise-452702"
  region      = "asia-southeast1"
  zone        = "asia-southeast1-a"
}
resource "google_compute_network" "vpc" {
  name                    = "techworld-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "techworld-subnet"
  ip_cidr_range = "10.10.0.0/16"
  region        = "asia-southeast1"
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  version    = "~> 30.0"

  project_id = "enterprise-452702"
  name       = "techworld-cluster"
  region     = "asia-southeast1"     # 👉 Bổ sung dòng này
  zones      = ["asia-southeast1-a"]


  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  ip_range_pods     = "pods"         # 👉 Tên của secondary range
  ip_range_services = "services"     # 👉 Tên của secondary range

  node_pools = [
    {
      name         = "default-node-pool"
      machine_type = "e2-medium"
      min_count    = 3
      max_count    = 3
      disk_size_gb = 100
      auto_upgrade = true
      auto_repair  = true
      preemptible  = false
    }
  ]
}