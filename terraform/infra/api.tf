# locals {
#   url = "${kubernetes_service.vllm_gemma.metadata.0.name}.${kubernetes_service.vllm_gemma.metadata.0.namespace}.svc.cluster.local"
# }

resource "google_project_iam_member" "vertex_user" {
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.vllm_gemma.email}"
  project = local.project_id
}

# resource "kubernetes_deployment" "chat_api" {
#   metadata {
#     name      = "chat-api"
#     namespace = local.gemma_namespace
#     labels = {
#       app = "chat-api"
#     }
#   }
#
#   spec {
#     replicas = 1
#
#     selector {
#       match_labels = {
#         app = "chat-api"
#       }
#     }
#
#     template {
#       metadata {
#         labels = {
#           app = "chat-api"
#         }
#       }
#
#       spec {
#         service_account_name = local.vllm_gemma_ksa_name
#
#         container {
#           image             = "us-central1-docker.pkg.dev/${local.project_id}/chatapp-docker-repo/chat-app:latest"
#           name              = "chat-api"
#           image_pull_policy = "Always"
#
#           # command = ["fastapi", "run", "vllm.entrypoints.openai.api_server"]
#           # args = ["--port", "8080"]
#
#           resources {
#             requests = {
#               cpu    = "1"
#               memory = "2Gi"
#             }
#             limits = {
#               cpu    = "1"
#               memory = "3Gi"
#             }
#           }
#
#           volume_mount {
#             name       = "tmp-vol"
#             mount_path = "/tmp"
#           }
#
#           volume_mount {
#             name       = "hf-cache-volume"
#             mount_path = "/cache" # Mount it at a clean path like /cache
#           }
#
#           env {
#             name  = "VLLM_CNAME"
#             value = local.url
#           }
#
#           env {
#             name  = "VLLM_PORT"
#             value = 8000
#           }
#
#           env {
#             name = "MEMORYSTORE_URL"
#             value = "redis://10.3.0.2:6379"
#           }
#
#           env {
#             name  = "HF_HOME"
#             value = "/cache"
#           }
#
#           # env {
#           #   name  = "GOOGLE_CLOUD_LOCATION"
#           #   value = var.region
#           # }
#           #
#           # env {
#           #   name  = "GOOGLE_GENAI_USE_VERTEXAI"
#           #   value = "true"
#           # }
#
#           security_context {
#             privileged                 = false
#             allow_privilege_escalation = false
#             read_only_root_filesystem  = true
#             capabilities {
#               drop = ["ALL"]
#             }
#           }
#         }
#
#         volume {
#           name = "tmp-vol"
#           empty_dir {
#           }
#         }
#
#         volume {
#           name = "hf-cache-volume"
#           empty_dir {} # This creates an ephemeral, writable directory
#         }
#       }
#
#
#
#     }
#   }
# }
#
# resource "kubernetes_service" "chat_api" {
#   metadata {
#     name      = "chat-api"
#     namespace = local.gemma_namespace
#     labels = {
#       app = "chat-api"
#     }
#   }
#
#   spec {
#     selector = {
#       app = "chat-api"
#     }
#
#     port {
#       protocol    = "TCP"
#       port        = 8000
#       target_port = 8000
#     }
#
#     type = "LoadBalancer"
#     # load_balancer_ip = google_compute_address.external.address
#   }
# }

# resource "google_compute_address" "external" {
#   name         = "cad-external"
#   region       = var.region
#   network_tier = "STANDARD"
# }