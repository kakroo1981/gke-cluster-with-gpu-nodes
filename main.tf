resource "google_container_cluster" "default" {
  provider       = google-beta
  project        = var.project_id
  name           = var.name
  location       = "europe-west2"
  node_locations = ["europe-west2-a", "europe-west2-b"]
  network        = var.network
  subnetwork     = var.subnetwork

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.ip_cidr.cluster
    services_ipv4_cidr_block = var.ip_cidr.services
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }

    http_load_balancing {
      disabled = false
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
  
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  workload_identity_config {
    identity_namespace = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "default" {
  provider = google-beta

  project            = google_container_cluster.default.project
  name               = var.pool_name
  location           = google_container_cluster.default.location
  node_locations     = ["europe-west2-a", "europe-west2-b"]
  cluster            = google_container_cluster.default.name
  initial_node_count = 2

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }

  node_config {
    machine_type    = "n1-standard-4"
    image_type      = "COS"
    disk_size_gb    = 100
    disk_type       = "pd-standard"
    local_ssd_count = 0
    preemptible     = false
    service_account = var.node_service_account
    guest_accelerator {
      type  = "nvidia-tesla-p4"
      count = 1
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
