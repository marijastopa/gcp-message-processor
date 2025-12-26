#!/bin/bash

# Cleanup script - removes all GCP resources

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

echo "  CLEANUP WARNING"
echo "This will DELETE:"
echo "  - Cloud Function: $FUNCTION_NAME"
echo "  - Pub/Sub Topic: $TOPIC_NAME"
echo "  - Storage Bucket: $BUCKET_NAME (and all files)"
echo ""
read -p "Continue? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

echo "1. Deleting Cloud Function..."
if gcloud functions describe $FUNCTION_NAME --region=$REGION --gen2 &>/dev/null; then
    gcloud functions delete $FUNCTION_NAME \
        --region=$REGION \
        --gen2 \
        --quiet
    echo "    Function deleted"
else
    echo "    Function not found"
fi

echo ""
echo "2. Deleting Pub/Sub topic..."
if gcloud pubsub topics describe $TOPIC_NAME &>/dev/null; then
    # Delete subscriptions first
    SUBSCRIPTIONS=$(gcloud pubsub topics list-subscriptions $TOPIC_NAME \
        --format="value(name)" 2>/dev/null || echo "")
    
    if [ ! -z "$SUBSCRIPTIONS" ]; then
        echo "   Deleting subscriptions..."
        for sub in $SUBSCRIPTIONS; do
            gcloud pubsub subscriptions delete $sub --quiet
            echo "      Deleted: $sub"
        done
    fi
    
    # Delete topic
    gcloud pubsub topics delete $TOPIC_NAME --quiet
    echo "    Topic deleted"
else
    echo "    Topic not found"
fi

echo ""
echo "3. Deleting Storage bucket..."
if gsutil ls -b gs://$BUCKET_NAME &>/dev/null; then
    # Delete all files
    gsutil -m rm -r gs://$BUCKET_NAME/** 2>/dev/null || true
    
    # Delete bucket
    gsutil rb gs://$BUCKET_NAME
    echo "    Bucket deleted"
else
    echo "    Bucket not found"
fi

echo ""
echo " Cleanup Complete"
echo "All resources removed."
echo ""