variable "project_id" {
  type = string
}

variable "api_image_name" {
  type = string
}

variable "ui_image_name" {
  type = string
}

locals {
  service_name       = "node-api"
  ui_service_name    = "nginx-ui"
  load_balancer_name = "my-lb"
  ssl_domain         = "test.com"
  region             = "us-central1"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = local.region
  zone    = "${local.region}-a"
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "cloud_run_api" {
  project = var.project_id
  service = "run.googleapis.com"
}

# cloud run service for the api
resource "google_cloud_run_service" "api" {
  name     = local.service_name
  location = local.region

  template {
    spec {
      containers {
        image = var.api_image_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress"            = "internal-and-cloud-load-balancing"
      "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
    }
  }
}

# do not require authentication for the api cloud run service (protected behind lb)
resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloud_run_service.api.location
  project  = var.project_id
  service  = google_cloud_run_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# cloud run service for the ui
resource "google_cloud_run_service" "ui" {
  name     = local.ui_service_name
  location = local.region

  template {
    spec {
      containers {
        image = var.ui_image_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }
}

# do not require authentication for the ui cloud run service (protected behind lb)
resource "google_cloud_run_service_iam_member" "ui" {
  location = google_cloud_run_service.ui.location
  project  = var.project_id
  service  = google_cloud_run_service.ui.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# reserved ip address
resource "google_compute_global_address" "default" {
  name = "${local.service_name}-address"
}

# node api network endpoint group
resource "google_compute_region_network_endpoint_group" "api" {
  provider              = google
  name                  = "${local.load_balancer_name}-api-neg"
  network_endpoint_type = "SERVERLESS"
  region                = local.region
  cloud_run {
    service = google_cloud_run_service.api.name
  }
}

# node api backend service
resource "google_compute_backend_service" "api" {
  name = "${local.load_balancer_name}-api-backend"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.api.id
  }
}

# ui network endpoint group
resource "google_compute_region_network_endpoint_group" "ui" {
  provider              = google
  name                  = "${local.load_balancer_name}-ui-neg"
  network_endpoint_type = "SERVERLESS"
  region                = local.region
  cloud_run {
    service = google_cloud_run_service.ui.name
  }
}

# ui backend service
resource "google_compute_backend_service" "ui" {
  name = "${local.load_balancer_name}-ui-backend"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.ui.id
  }
}

resource "google_compute_url_map" "default" {
  name = "${local.load_balancer_name}-urlmap"

  default_service = google_compute_backend_service.ui.id

  path_matcher {
    name = "mysite"

    path_rule {
      paths   = ["/api", "/api/*"]
      service = google_compute_backend_service.api.id
    }

    # serve the ui by default
    default_service = google_compute_backend_service.ui.id
  }

  host_rule {
    hosts        = ["*"]
    path_matcher = "mysite"
  }
}

# http proxy
resource "google_compute_target_http_proxy" "default" {
  name     = "${local.load_balancer_name}-http-proxy"
  provider = google
  url_map  = google_compute_url_map.default.id
}

# forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "${local.load_balancer_name}-forwarding-rule"
  provider              = google
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "default"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google

  network                 = "default"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  provider = google

  name                = "private-instance-${random_id.db_name_suffix.hex}"
  region              = "us-central1"
  database_version    = "POSTGRES_13"
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = true
      private_network                               = "projects/${var.project_id}/global/networks/default"
      enable_private_path_for_google_cloud_services = true
    }
  }
}

# SSL (requires proof of domain ownership)

# resource "google_compute_managed_ssl_certificate" "default" {
#   provider = google

#   name = "${local.load_balancer_name}-cert"
#   managed {
#     domains = ["${local.ssl_domain}"]
#   }
# }

# resource "google_compute_target_https_proxy" "default" {
#   name = "${local.load_balancer_name}-https-proxy"

#   url_map = google_compute_url_map.default.id
#   ssl_certificates = [
#     google_compute_managed_ssl_certificate.default.id
#   ]
# }

# resource "google_compute_global_forwarding_rule" "default" {
#   name = "${local.load_balancer_name}-lb"

#   target     = google_compute_target_https_proxy.default.id
#   port_range = "443"
#   ip_address = google_compute_global_address.default.address
# }
