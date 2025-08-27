# For K8s objects: export KUBE_CONFIG_PATH=~/.kube/config

##########################################################################
## VARIABLES
###########################################################################

variable "project" {
  description = "The Google project to create resources in."
  default     = "paramify-mycompany-gke"
}

variable "region" {
  description = "The Google region to create resources in."
  default     = "us-west3"
}

variable "zone" {
  description = "The Google zone to create resources in."
  default     = "us-west3-a"
}

variable "dns_name" {
  description = "The DNS name to use for the app."
  default     = "paramify.mycompany.com"
}

variable "db_password" {
  description = "Database password used by Paramify."
  default     = "password"
}

variable "google_prefix" {
  description = "Prefix for naming the created Google resources."
  default     = "paramify-gke"
}

variable "namespace" {
  description = "Kubernetes namespace to use for the Paramify installation."
  default     = "paramify"
}


###########################################################################
## CORE
###########################################################################

provider "google" {
  region  = var.region
  project = var.project
}


###########################################################################
## OUTPUT
###########################################################################

output "db_ip" {
  description = "DB endpoint to configure for application"
  value       = google_sql_database_instance.paramify_gke_db.private_ip_address
}

output "google_bucket" {
  description = "Google Storage bucket created to store documents"
  value       = google_storage_bucket.paramify_gke_bucket.name
}

output "iam_sa" {
  description = "IAM service account email address"
  value       = google_service_account.paramify_gke_sa.email
}


###########################################################################
## NETWORK
###########################################################################

resource "google_compute_network" "paramify_gke_net" {
  name                    = "${var.google_prefix}-net"
  project                 = var.project
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "paramify_gke_subnet" {
  name          = "${var.google_prefix}-subnet"
  project       = var.project
  region        = var.region
  network       = google_compute_network.paramify_gke_net.self_link
  ip_cidr_range = "10.0.0.0/24"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.128.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.0.0/20"
  }
}

resource "google_compute_global_address" "paramify_gke_ip" {
  name          = "${var.google_prefix}-ip"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  ip_version    = "IPV4"
  prefix_length = 24
  network       = google_compute_network.paramify_gke_net.self_link
}

resource "google_service_networking_connection" "paramify_gke_connection" {
  network                 = google_compute_network.paramify_gke_net.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.paramify_gke_ip.name]
  deletion_policy         = "ABANDON"
}


###########################################################################
## DB & Bucket
###########################################################################

resource "google_sql_database_instance" "paramify_gke_db" {
  name             = "${var.google_prefix}-db"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project

  settings {
    tier      = "db-f1-micro"
    disk_size = 20
    insights_config {
      query_insights_enabled = false
    }
    ip_configuration {
      ipv4_enabled    = false  # no public IPv4 address (private network instead)
      private_network = google_compute_network.paramify_gke_net.self_link
      ssl_mode        = "ENCRYPTED_ONLY"
    }
  }

  deletion_protection = false
  depends_on = [
    google_service_account.paramify_gke_sa,
    google_service_networking_connection.paramify_gke_connection
  ]
}

resource "google_sql_user" "paramify_gke_db_user" {
  instance        = google_sql_database_instance.paramify_gke_db.name
  name            = "paramify"
  password_wo     = var.db_password
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "paramify_gke_db_db" {
  name     = "paramify"
  instance = google_sql_database_instance.paramify_gke_db.name
}

resource "google_storage_bucket" "paramify_gke_bucket" {
  name          = "${var.google_prefix}-bucket"
  location      = var.region
  project       = var.project
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "paramify_gke_bucket_iam" {
  bucket  = google_storage_bucket.paramify_gke_bucket.name
  role    = "roles/storage.objectUser"
  members = ["serviceAccount:${google_service_account.paramify_gke_sa.email}"]

  depends_on = [
    google_service_account.paramify_gke_sa,
  ]
}


###########################################################################
## GKE and Service Account (for Bucket)
###########################################################################

resource "google_container_cluster" "paramify_gke_cluster" {
  name     = "${var.google_prefix}-gke"
  location = var.zone
  project  = var.project

  initial_node_count       = 1
  remove_default_node_pool = true
  deletion_protection      = false

  network    = google_compute_network.paramify_gke_net.name
  subnetwork = google_compute_subnetwork.paramify_gke_subnet.name

  maintenance_policy {
    daily_maintenance_window {
      start_time = "04:00"
    }
  }

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = google_compute_subnetwork.paramify_gke_subnet.secondary_ip_range[0].range_name
    cluster_secondary_range_name  = google_compute_subnetwork.paramify_gke_subnet.secondary_ip_range[1].range_name
  }

  depends_on = [
    google_service_account.paramify_gke_sa,
  ]
}

resource "google_container_node_pool" "paramify_gke_nodepool" {
  name       = "${var.google_prefix}-nodepool"
  project    = var.project
  cluster    = google_container_cluster.paramify_gke_cluster.id
  node_count = 2

  management {
    auto_upgrade = true
  }

  node_config {
    machine_type = "e2-standard-2"
    disk_size_gb = 50
    oauth_scopes = [
      # "https://www.googleapis.com/auth/logging.write",
      # "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    tags         = ["gke-node", var.google_prefix]
    metadata     = {
      disable-legacy-endpoints = "true"
    }
    # enable workload identity on node pool
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  depends_on = [
    google_service_account.paramify_gke_sa,
  ]
}

resource "google_service_account" "paramify_gke_sa" {
  project      = var.project
  account_id   = "${var.google_prefix}-sa"
  display_name = "${var.google_prefix}-sa"
}

resource "google_service_account_iam_binding" "sa_user" {
  service_account_id = google_service_account.paramify_gke_sa.id
  role               = "roles/iam.serviceAccountUser"
  members            = ["serviceAccount:${google_service_account.paramify_gke_sa.email}"]
}

resource "google_service_account_iam_binding" "sa_token" {
  service_account_id = google_service_account.paramify_gke_sa.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.paramify_gke_sa.email}"]
}

resource "google_service_account_iam_binding" "sa_workload_binding" {
  service_account_id = google_service_account.paramify_gke_sa.id
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project}.svc.id.goog[${var.namespace}/paramify]"]

  depends_on = [
    google_service_account.paramify_gke_sa,
  ]
}


###########################################################################
## Paramify K8s Namespace
###########################################################################

resource "kubernetes_namespace" "paramify_gke_ns" {
  metadata {
    name = var.namespace
  }
}
