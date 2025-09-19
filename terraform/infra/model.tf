locals {
  project_id = data.google_project.project.project_id
  gemma_namespace = "vllm-server"
  vllm_gemma_ksa_name    = "chat-api"
}

output "project_id" {
  value = local.project_id
}
output "id" {
  value = data.google_project.project.id
}

resource "kubernetes_namespace" "vllm_gemma" {
  metadata {
    name = local.gemma_namespace
  }
}

resource "google_service_account" "vllm_gemma" {
  account_id                   = "chat-api"
  create_ignore_already_exists = true
}

resource "kubernetes_service_account" "vllm_gemma" {
  metadata {
    name      = local.vllm_gemma_ksa_name
    namespace = local.gemma_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.vllm_gemma.email
    }
  }
}

resource "google_service_account_iam_binding" "vllm_gemma_gsa_user" {
  service_account_id = google_service_account.vllm_gemma.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${local.project_id}.svc.id.goog[${local.gemma_namespace}/${local.vllm_gemma_ksa_name}]"
  ]
}

resource "kubernetes_secret_v1" "huggingface_token" {
  metadata {
    name      = "huggingface-token"
    namespace = local.gemma_namespace
  }

  data = {
    hf_token = var.hf_token
  }
  type = "Opaque"
}


# resource "kubernetes_deployment" "vllm_gemma" {
#   metadata {
#     name      = "vllm-gemma"
#     namespace = local.gemma_namespace
#     labels = {
#       app = "gemma-server"
#     }
#   }
#
#   spec {
#     replicas = 1
#
#     selector {
#       match_labels = {
#         app = "gemma-server"
#       }
#     }
#
#     template {
#       metadata {
#         labels = {
#           app = "gemma-server"
#         }
#         annotations = {
#           "ai.gke.io/model" = "gemma-3-1b-it"
#           "ai.gke.io/inference-server" = "vllm"
#         }
#       }
#
#       spec {
#         service_account_name = local.vllm_gemma_ksa_name
#
#         container {
#           image             = "us-docker.pkg.dev/vertex-ai/vertex-vision-model-garden-dockers/pytorch-vllm-serve:20250312_0916_RC01"
#           name              = "inference-server"
#           image_pull_policy = "Always"
#
#           command = ["python3", "-m", "vllm.entrypoints.openai.api_server"]
#             args = [
#               "--model", "google/gemma-3-1b-it",
#               "--dtype", "half",
#               "--tensor-parallel-size", "1",
#               "--host", "0.0.0.0",
#               "--port", "8000",
#             ]
#
#           resources {
#             requests = {
#               cpu    = "1"
#               memory = "8Gi"
#               ephemeral-storage = "8Gi"
#               "nvidia.com/gpu" = "1"
#             }
#             limits = {
#               cpu    = "2"
#               memory = "12Gi"
#               ephemeral-storage = "20Gi"
#               "nvidia.com/gpu" = "1"
#             }
#           }
#
#           volume_mount {
#             name       = "dshm"
#             mount_path = "/dev/shm"
#           }
#
#           volume_mount {
#             name       = "tmp-vol"
#             mount_path = "/tmp"
#           }
#
#           volume_mount {
#             name = "vllm-config-volume"
#             mount_path = "/config/vllm"
#           }
#
#           volume_mount {
#             name       = "hf-cache-volume"
#             mount_path = "/cache" # Mount it at a clean path like /cache
#           }
#
#           env {
#             name = "HF_TOKEN"
#             value_from {
#               secret_key_ref {
#                 name = "huggingface-token"
#                 key  = "hf_token"
#               }
#             }
#           }
#
#           env {
#             name  = "HF_HOME"
#             value = "/cache"
#           }
#
#           env {
#             name  = "TRITON_CACHE_DIR"
#             value = "/cache/triton"
#           }
#
#           env {
#             name  = "XDG_CONFIG_HOME"
#             value = "/config/vllm"
#           }
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
#           name = "dshm"
#           empty_dir {
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
#
#         volume {
#           name = "vllm-config-volume"
#           empty_dir {} # This creates an ephemeral, writable directory
#         }
#
#         node_selector = {
#           "cloud.google.com/gke-accelerator" = "nvidia-tesla-t4"
#           # "cloud.google.com/gke-gpu-driver-version" = "latest"
#         }
#
#         toleration {
#           key = "nvidia.com/gpu"
#           operator = "Exists"
#           effect = "NoSchedule"
#         }
#
#       }
#     }
#   }
# }
#
# resource "kubernetes_service" "vllm_gemma" {
#   metadata {
#     name      = "vllm-gemma"
#     namespace = local.gemma_namespace
#     labels = {
#       app = "gemma-server"
#     }
#   }
#
#   spec {
#     selector = {
#       app = "gemma-server"
#     }
#
#     port {
#       protocol = "TCP"
#       port        = 8000
#       target_port = 8000
#     }
#
#     type = "ClusterIP"
#   }
# }