provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_manifest" "llm_operator_crd_and_deploy" {
  manifest = yamldecode(file("${path.module}/k8s_resources.yaml"))
}