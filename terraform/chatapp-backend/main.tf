data "google_project" "main" {}


resource "google_service_account" "cloudrun_vertex" {
  account_id   = "cloudrun-vertex"
  display_name = "Cloud Run Vertex AI SA"
}

resource "google_project_iam_member" "vertex_user" {
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloudrun_vertex.email}"
  project = data.google_project.main.id
}

resource "google_artifact_registry_repository" "chatapp_backend" {

  location = var.region
  repository_id = "chatapp-docker-repo"
  format = "DOCKER"
  description = "Docker repository for ChatApp backend"
}

resource "google_cloud_run_v2_service" "chatapp_backend" {

  name = "chatapp-backend"
  location = var.region
  client = "terraform"

  template {
    containers {
      image = "us-central1-docker.pkg.dev/gcp-home-dtian01/chatapp-docker-repo/chat-app:latest"

      resources {
        limits = {
          cpu = "1"
          memory = "1024Mi"
        }
      }

      env {
        name  = "GOOGLE_CLOUD_LOCATION"
        value = var.region
      }

      env {
        name  = "GOOGLE_GENAI_USE_VERTEXAI"
        value = "true"
      }
    }
  }

  build_config {
    service_account = google_service_account.cloudrun_vertex.id
  }
}
