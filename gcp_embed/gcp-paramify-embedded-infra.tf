##########################################################################
## VARIABLES
###########################################################################

variable "project" {
  description = "The Google project to create resources in."
  default     = "mycompany-paramify-project-id"
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

variable "image_id" {
  description = "The OS image to use for the VM."
  default     = "family/debian-12"
}

variable "allowed_ips" {
  description = "Company egress IPs that should be allowed to access app and installer."
  default     = ["192.168.0.1/32","192.168.0.2/32"]
}

variable "db_password" {
  description = "Database password used by Paramify."
  default     = "super_secret"
}

variable "google_prefix" {
  description = "Prefix for naming the created Google resources."
  default     = "paramify-mycompany"
}

variable "paramify_license_id" {
  description = "Paramify license ID."
  default     = "<paramify_licese_id>"
}

###########################################################################
## CORE
###########################################################################

provider "google" {
  region  = var.region
  project = var.project
}

# # Better to enable APIs manually in the project prior to provisioning with:
# # gcloud services enable compute.googleapis.com \
# #   iamcredentials.googleapis.com \
# #   networkservices.googleapis.com \
# #   servicenetworking.googleapis.com

# variable "gcp_services" {
#   description = "Google service APIs to enable."
#   type = list(string)
#   default = [
#     "compute.googleapis.com",
#     "iamcredentials.googleapis.com",
#     "networkservices.googleapis.com",
#     "servicenetworking.googleapis.com",
#   ]
# }

# resource "google_project_service" "paramify_gsolo_services" {
#   for_each = toset(var.gcp_services)
#   project = var.project
#   service = each.key
# }


###########################################################################
## OUTPUT
###########################################################################

output "vm_id" {
  description = "VM ID to use to SSH via IAP"
  value       = google_compute_instance.paramify_gsolo_app.name
}

output "db_ip" {
  description = "DB endpoint to configure for application"
  value       = google_sql_database_instance.paramify_gsolo_db.private_ip_address
}

output "google_bucket" {
  description = "Google Storage bucket created to store documents"
  value       = google_storage_bucket.paramify_gsolo_bucket.name
}

output "iam_sa" {
  description = "IAM service account email address"
  value       = google_service_account.paramify_gsolo_sa.email
}

output "lb_ip" {
  description = "Load balancer IP address"
  value       = google_compute_global_address.paramify_gsolo_lb_ip.address
}


###########################################################################
## NETWORK
###########################################################################

resource "google_compute_network" "paramify_gsolo_net" {
  name                    = "${var.google_prefix}-net"
  project                 = var.project
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "paramify_gsolo_subnet" {
  name          = "${var.google_prefix}-subnet"
  project       = var.project
  region        = var.region
  network       = google_compute_network.paramify_gsolo_net.self_link
  ip_cidr_range = "10.0.0.0/24"

  private_ip_google_access = true
}

resource "google_compute_global_address" "paramify_gsolo_ip" {
  name          = "${var.google_prefix}-ip"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  ip_version    = "IPV4"
  prefix_length = 24
  network       = google_compute_network.paramify_gsolo_net.self_link
}

resource "google_service_networking_connection" "paramify_gsolo_connection" {
  network                 = google_compute_network.paramify_gsolo_net.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.paramify_gsolo_ip.name]
  deletion_policy         = "ABANDON"
}


###########################################################################
## SECURITY GROUPS
###########################################################################

# Allow SSH from IAP and web traffic (from LB/health) to private subnet
resource "google_compute_firewall" "paramify_gsolo_allow_in" {
  name        = "${var.google_prefix}-allow-in"
  description = "Allow SSH from IAP and web traffic to private subnet"
  network     = google_compute_network.paramify_gsolo_net.self_link
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "8443", "30000", "30001"]
  }

  # Allow "35.235.240.0/20" for SSH access via IAP
  # Allow "35.191.0.0/16","209.85.152.0/22","209.85.204.0/22" for Google LB Health Checks
  source_ranges = ["35.235.240.0/20", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
}

# Restrict access to SSL proxy to only allowed IPs
resource "google_compute_security_policy" "paramify_gsolo_secpol" {
  name = "${var.google_prefix}-secpol"

  rule {
    description = "Default rule"
    action      = "deny"
    priority    = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  rule {
    description = "Allow only trusted IPs"
    action      = "allow"
    priority    = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_ips
      }
    }
  }
}


###########################################################################
## LB (App 443->30001 and KOTS installer 8443->30000)
###########################################################################

resource "google_compute_global_address" "paramify_gsolo_lb_ip" {
  name = "${var.google_prefix}-lb-ip"
}

# Self-signed regional SSL certificate for testing
resource "tls_private_key" "paramify_gsolo_tls_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "paramify_gsolo_tls_cert" {
  private_key_pem = tls_private_key.paramify_gsolo_tls_key.private_key_pem

  # Certificate expires after 24 months
  validity_period_hours = 24 * 30 * 24
  early_renewal_hours   = 24 * 30

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [var.dns_name]

  subject {
    common_name  = var.dns_name
    organization = "Paramify, Inc"
  }
}

resource "google_compute_ssl_certificate" "paramify_gsolo_tls_cert" {
  name_prefix = "${var.google_prefix}-tls-cert"
  private_key = tls_private_key.paramify_gsolo_tls_key.private_key_pem
  certificate = tls_self_signed_cert.paramify_gsolo_tls_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_ssl_proxy" "paramify_gsolo_app_proxy" {
  name             = "${var.google_prefix}-app-proxy"
  ssl_certificates = [google_compute_ssl_certificate.paramify_gsolo_tls_cert.id]
  backend_service  = google_compute_backend_service.paramify_gsolo_app_service.id
}

resource "google_compute_target_ssl_proxy" "paramify_gsolo_admin_proxy" {
  name             = "${var.google_prefix}-admin-proxy"
  ssl_certificates = [google_compute_ssl_certificate.paramify_gsolo_tls_cert.id]
  backend_service  = google_compute_backend_service.paramify_gsolo_admin_service.id
}

resource "google_compute_global_forwarding_rule" "paramify_gsolo_app_lb" {
  name                  = "${var.google_prefix}-app-lb"
  target                = google_compute_target_ssl_proxy.paramify_gsolo_app_proxy.id
  port_range            = "443"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.paramify_gsolo_lb_ip.address
}

resource "google_compute_global_forwarding_rule" "paramify_gsolo_admin_lb" {
  name                  = "${var.google_prefix}-admin-lb"
  target                = google_compute_target_ssl_proxy.paramify_gsolo_admin_proxy.id
  port_range            = "8443"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.paramify_gsolo_lb_ip.address
}

resource "google_compute_health_check" "paramify_gsolo_app_check" {
  name                = "${var.google_prefix}-app-check"
  check_interval_sec  = 10
  timeout_sec         = 10
  healthy_threshold   = 1
  unhealthy_threshold = 2

  https_health_check {
    port         = 30001
    request_path = "/health-check"
  }
}

resource "google_compute_health_check" "paramify_gsolo_admin_check" {
  name                = "${var.google_prefix}-admin-check"
  check_interval_sec  = 10
  timeout_sec         = 10
  healthy_threshold   = 1
  unhealthy_threshold = 2

  https_health_check {
    port         = 30000
    request_path = "/healthz"
  }
}

resource "google_compute_backend_service" "paramify_gsolo_app_service" {
  name                  = "${var.google_prefix}-app-service"
  protocol              = "SSL"
  timeout_sec           = 10
  port_name             = "app"
  enable_cdn            = false
  session_affinity      = "NONE"
  health_checks         = [google_compute_health_check.paramify_gsolo_app_check.id]
  load_balancing_scheme = "EXTERNAL"
  security_policy       = google_compute_security_policy.paramify_gsolo_secpol.id

  backend {
    group = google_compute_instance_group.paramify_gsolo_ig.self_link
  }
}

resource "google_compute_backend_service" "paramify_gsolo_admin_service" {
  name                  = "${var.google_prefix}-admin-service"
  protocol              = "SSL"
  timeout_sec           = 10
  port_name             = "admin"
  enable_cdn            = false
  session_affinity      = "NONE"
  health_checks         = [google_compute_health_check.paramify_gsolo_admin_check.id]
  load_balancing_scheme = "EXTERNAL"
  security_policy       = google_compute_security_policy.paramify_gsolo_secpol.id

  backend {
    group = google_compute_instance_group.paramify_gsolo_ig.self_link
  }
}

resource "google_compute_instance_group" "paramify_gsolo_ig" {
  name      = "${var.google_prefix}-ig"
  zone      = var.zone
  instances = [google_compute_instance.paramify_gsolo_app.self_link]

  named_port {
    name = "app"
    port = 30001
  }
  named_port {
    name = "admin"
    port = 30000
  }
}


###########################################################################
## DB & Bucket
###########################################################################

resource "google_sql_database_instance" "paramify_gsolo_db" {
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
      ipv4_enabled    = false
      private_network = google_compute_network.paramify_gsolo_net.self_link
      ssl_mode        = "ENCRYPTED_ONLY"
    }
  }

  deletion_protection = false
  depends_on = [
    google_service_account.paramify_gsolo_sa,
    google_service_networking_connection.paramify_gsolo_connection
  ]
}

resource "google_sql_user" "paramify_gsolo_db_user" {
  instance        = google_sql_database_instance.paramify_gsolo_db.name
  name            = "paramify"
  password        = var.db_password
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "paramify_gsolo_db_db" {
  name     = "paramify"
  instance = google_sql_database_instance.paramify_gsolo_db.name
}

resource "google_storage_bucket" "paramify_gsolo_bucket" {
  name          = "${var.google_prefix}-bucket"
  location      = var.region
  project       = var.project
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "paramify_gsolo_bucket_iam" {
  bucket = google_storage_bucket.paramify_gsolo_bucket.name
  role   = "roles/storage.objectUser"
  members = [
    "serviceAccount:${google_service_account.paramify_gsolo_sa.email}",
  ]
}


###########################################################################
## VM (App) and Service Account (for Bucket)
###########################################################################

resource "google_compute_instance" "paramify_gsolo_app" {
  name           = "${var.google_prefix}-app"
  machine_type   = "e2-standard-2"
  zone           = var.zone
  can_ip_forward = true

  boot_disk {
    auto_delete = true
    device_name = "${var.google_prefix}-app"
    initialize_params {
      image = var.image_id
      size  = 42
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.paramify_gsolo_net.self_link
    subnetwork = google_compute_subnetwork.paramify_gsolo_subnet.self_link

    // configures external IP, alternatively setup a cloud nat
    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = google_service_account.paramify_gsolo_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = templatefile("startup.sh", { license_id = var.paramify_license_id })
  }
}

resource "google_service_account" "paramify_gsolo_sa" {
  account_id   = "${var.google_prefix}-sa"
  display_name = "${var.google_prefix}-sa"
  project      = var.project
}

resource "google_service_account_iam_binding" "sa_user" {
  service_account_id = google_service_account.paramify_gsolo_sa.id
  role               = "roles/iam.serviceAccountUser"
  members            = ["serviceAccount:${google_service_account.paramify_gsolo_sa.email}"]
}

resource "google_service_account_iam_binding" "sa_token" {
  service_account_id = google_service_account.paramify_gsolo_sa.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.paramify_gsolo_sa.email}"]
}

resource "google_project_iam_member" "sa_oslogin" {
  project = var.project
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.paramify_gsolo_sa.email}"
}

# # If using Workload Identity on a GKE cluster
# resource "google_project_iam_member" "sa_workload" {
#   project  = var.project
#   role     = "roles/iam.workloadIdentityUser"
#   member   = "serviceAccount:${var.project}.svc.id.goog[${var.namespace}/paramify]"
# }
