terraform {
  backend "remote" {
    organization = "personal-mobile"
    workspaces {
      name = "iac-gke"
    }
  }
}

provider "google" {
  credentials = var.gcpcredentials
  project     = var.gcp_project_id
  region      = "us-central1"
}

resource "azurerm_resource_group" "arcdemo" {
  name     = var.resource_group_name
  location = var.location
}

resource "google_container_cluster" "arcdemo" {
  name     = var.gke_cluster_name
  location = var.gcp_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [azurerm_resource_group.arcdemo]
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "arcdemo-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.arcdemo.name
  node_count = var.gke_cluster_node_count

  node_config {
    preemptible  = true
    machine_type = var.gke_cluster_node_machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}