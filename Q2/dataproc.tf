
resource "google_service_account" "default" {
    account_id = "dataproc-sa-account"
    display_name = "SA"
    project = var.project_id
}

# resource "google_project_iam_member" "binding" {
#   project = var.project_id
#   role    = "roles/dataproc.worker"
#   member  = "serviceAccount:${google_service_account.sa-name.email}"
# }

# resource "google_storage_bucket_iam_member" "dataproc-member" {
#     bucket = google_storage_bucket.dataproc-bucket.name
#     role   = "roles/storage.admin"
#     member = "serviceAccount:${google_service_account.sa-name.email}"
# }

resource "google_storage_bucket" "dataproc-bucket" {
    project                     = var.project_id
    name                        = var.bucket_name
    uniform_bucket_level_access = true
    location                    = var.region
}


resource "google_dataproc_cluster" "dp_cluster" {
    project = var.project_id
    name   = var.cluster_name
    region = var.region
    labels = var.labels
    graceful_decommission_timeout = "120s"

cluster_config {
    software_config {
        image_version = var.cluster_version
        override_properties = {
            "dataproc:dataproc.allow.zero.workers" = "true"
        }
        optional_components = ["DOCKER", "ANACONDA", "JUPYTER"]
    }



    gce_cluster_config {
      service_account = google_service_account.default.email
      service_account_scopes = [
        "cloud-platform"
      ]
      tags = [var.cluster_name]
      zone = var.zone
    #   metadata = {
    #     CONDA_PACKAGES = var.conda_packages
    #     PIP_PACKAGES = var.pip_packages
    #   }
    }
    master_config {
      num_instances = 1
      machine_type = var.master_instance_type
      disk_config {
        boot_disk_type    = "pd-ssd"
        boot_disk_size_gb = 30
      }
    }

    worker_config {
      num_instances = 2
      machine_type = var.worker_instance_type
      disk_config {
        boot_disk_size_gb = 30
        num_local_ssds    = 1
      }
      dynamic "accelerators" {
        for_each = var.worker_accelerator
        content {
          accelerator_count = accelerators.value.worker_accelerator.count
          accelerator_type = accelerators.value.worker_accelerator.type
        }
      }
    }
    preemptible_worker_config {
      num_instances = var.preemptible_worker_min_instances
    }
  }
}

data "google_compute_instance" "master" {
  name = "jupyter-docker-terraform-qiuyangz-m"
  zone = "us-central1-a"
  project = var.project_id
}

