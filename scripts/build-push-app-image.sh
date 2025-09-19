
# Build image
#docker build -t gcr.io/$GOOGLE_PROJECT/chat-app .
#
#gcloud builds submit --region=us-central1 --tag us-central1-docker.pkg.dev/$GOOGLE_PROJECT/chatapp-docker-repo/chatapp:latest


docker build --no-cache --platform linux/amd64 -t us-central1-docker.pkg.dev/$GOOGLE_PROJECT/chatapp-docker-repo/chat-app .
docker push us-central1-docker.pkg.dev/$GOOGLE_PROJECT/chatapp-docker-repo/chat-app


#docker run -d -p 7860:7860 -e VLLM_CNAME=host.docker.internal us-central1-docker.pkg.dev/$GOOGLE_PROJECT/chatapp-docker-repo/chat-app:latest
