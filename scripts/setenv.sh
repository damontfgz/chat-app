#!/usr/bin/env bash

export GOOGLE_APPLICATION_CREDENTIALS=~/.athenz/gcp/config.json
export GOOGLE_PROJECT=$(gcloud config get project)
export GOOGLE_GENAI_USE_VERTEXAI=True
export GOOGLE_CLOUD_LOCATION=us-central1
export GOOGLE_CLOUD_PROJECT=$(gcloud config get project)