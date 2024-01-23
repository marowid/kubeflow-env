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

resource "google_compute_instance" "bpk-llm" {
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
    ssh-keys = "ubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDrfL0VNEve9Ve/pH1JQcC1Nj2WshN1UJ86r+b0SPjoq1u20eDy8K0ESBfzTXibs3FavKYUI9cKUsGwvsECd+xwFZPW4vG/AN2wU5e9Dq+789pMxJeQIbe1AocWUuMhXU8RB0no97Xp2/w0dYuXXu5aLNDuGa0HlpRhINCmWRInIgjjG6xuatcEaI6GufjnwzxUMYVbptvtFwK0RpPKGKOQFXksso2jL+Pv4ozFUm+2dpeYIjxzN0785lM5loKHJsU+/FCj6cDoqINWnotK3oBQ5E20kgcBVgOu5MY/wx8P2Yv2Afln6rjRZaj/o9Xt3qMKmbMP0ExQaHLcEMfJlqzOyxwzKPTgEj3peWwLJPO2K6RS+htEMwjvbUvROTyWYTjwXy44eqdfYmYJDI3HP2czhz53XotxS5Zw2+PZlmNiwSttdl0EE0Eu4qpeOz5W+I6vQUFocnGhhZ8vSdbvMg3IgMbmGfpnfFnlwwDQHK295Qnwyuq1gd9XqrIha9BvgdU1lmVS1hHt5PUtAXQe45FOwhL8YqZG+Q2zIyMhycKxmDzUkST7/+loppTO0ZwjRz1gzKVbPVFOvs4fssa51oWVaeGqk8P07MPlkDXOlcQ8egOUie9p70g4FUmRXzCWX5SML+cQn3A9lDvChy/auRUhU2INgZKzKXGSnqT+qxZWQ== ubuntu\nubuntu:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDvq4/W+nNh98rZsm5yQtDxyHFdcfEITg1Go1xMtma51dF4Q0bwVXmWr9XXujU+qWIdI6kGIeEDVQuScn0TA6fB4M21BfP/91vmapYnpuGipkjHcbfHwvj1u5FRGOv3o3suzzqYDmvxw3subIRFYycXEfGnsRSU/+8dDv0C2BHaEEdrw+qbJqQZJHBdM1o6Pxk+g6UiH9EC2rJjfyXm+8XTse794moSe7uXTI6PW8SQIbMR4r7EPeznxfj8rqzXQxT34igI4KIoBLfoZY+uQOQmhzB7QVksyfbJ5av3DJjWPhf1uFoTu7iGj1xeXiEauxnrG4wsuopqMUGpT6G1FqbHJr2oVHMsRbSZFtdpso25UUwqXBraxUUTo4JjNpoxG3+M3d4M7feQgAd0hX7m8+yRZrwebEAaxqCTdTE8yi8Nu6fFEQP/NAevE7NtaDbvjagJFn//R28ICy9VZgF2O+VxezZ3jdiyRhty9QW6rA29FX/sYD1NVZ8gPoNNYrKALI0= ubuntu"
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