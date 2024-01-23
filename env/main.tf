terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.25.0, < 5.0"
    }
  }
  backend "gcs" {
    bucket = "info-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "field-ai-ml-projects"
  region  = "europe-west1"
}

variable "project_id" {
  default = "field-ai-ml-projects"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "prefix" {
  default = "info-"
}

resource "google_compute_instance" "llm" {
  boot_disk {
    auto_delete = true
    device_name = "${var.prefix}llm"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230919"
      size  = 1000
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  machine_type = "e2-standard-32"

  metadata = {
    ssh-keys = "key"
  }

  name = "${var.prefix}llm"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone = var.zone
}

output "public_ip" {
  value = google_compute_instance.bpk-llm.network_interface.0.access_config.0.nat_ip
}