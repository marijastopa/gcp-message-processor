#!/bin/bash

# Deploy Cloud Function with Pub/Sub trigger

set -e

# Load configuration
[ -f .env ] && source .env

# Validate
if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID not configured."
    exit 1
fi

# Set defaults
REGION=${REGION:-"europe-west1"}
BUCKET_NAME=${BUCKET_NAME:-"${PROJECT_ID}-message-storage"}
TOPIC_NAME=${TOPIC_NAME:-"message-topic"}
FUNCTION_NAME="message-processor"
RUNTIME="python311"

echo "Deploying Cloud Function"
echo "Function: $FUNCTION_NAME"
echo "Trigger: Pub/Sub topic '$TOPIC_NAME'"
echo "Region: $REGION"
echo ""

# Deploy function
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --region=$REGION \
  --runtime=$RUNTIME \
  --source=. \
  --entry-point=process_message \
  --trigger-topic=$TOPIC_NAME \
  --set-env-vars=BUCKET_NAME=$BUCKET_NAME \
  --memory=256MB \
  --timeout=60s \
  --max-instances=10 \
  --quiet

echo ""
echo "  Cloud Function Deployed"
echo ""
echo "Test with:"
echo "  gcloud pubsub topics publish $TOPIC_NAME --message='Hello GCP'"
echo ""
echo "View logs:"
echo "  gcloud functions logs read $FUNCTION_NAME --region=$REGION --gen2 --limit=20"
