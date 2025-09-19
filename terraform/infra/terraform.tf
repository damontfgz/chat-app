terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.34.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26.0"
    }

    athenz = {
      source  = "Athenz/athenz"
      version = ">= 1.0.21"
    }

    calypso = {
      source  = "terraform-providers/yahoo/calypso"
      version = ">= 1.0.16"
    }
  }

  required_version = "~> 1.9.8"
}

provider "google" {}

locals {
  athenz_cert = fileexists("/sd/tokens/cert") ? "/tokens/cert" : pathexpand("~/.athenz/cert")
  athenz_key  = fileexists("/sd/tokens/key") ? "/tokens/key" : pathexpand("~/.athenz/key")
}

provider "athenz" {
  zms_url = "https://zms.athenz.ouroath.com:4443/zms/v1"
  cert    = local.athenz_cert
  key     = local.athenz_key
}

provider "calypso" {
  ums_url = "https://ums.athens.yahoo.com:4443/ums/v1"
  cert    = local.athenz_cert
  key     = local.athenz_key
}