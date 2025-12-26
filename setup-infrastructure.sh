#!/bin/bash

# GCP Infrastructure Setup
# Creates: Pub/Sub topic and Cloud Storage bucket

set -e

# ============================================
# CONFIGURATION
# ============================================

# Load configuration from .env if it exists
[ -f .env ] && source .env

# Validate required configuration
if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID not configured."
    exit 1
fi

# Set defaults
REGION=${REGION:-"europe-west1"}
BUCKET_NAME=${BUCKET_NAME:-"${PROJECT_ID}-message-storage"}
TOPIC_NAME=${TOPIC_NAME:-"message-topic"}

# Set project
echo "Setting default project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com

echo "Waiting for APIs to be enabled..."
sleep 10

# Create Cloud Storage bucket
echo ""
echo "Creating Cloud Storage bucket..."
if gsutil ls -b gs://$BUCKET_NAME 2>/dev/null; then
    echo " Bucket already exists"
else
    gsutil mb -l $REGION gs://$BUCKET_NAME
    echo " Bucket created: gs://$BUCKET_NAME"
fi

# Create Pub/Sub topic
echo ""
echo "Creating Pub/Sub topic..."
if gcloud pubsub topics describe $TOPIC_NAME 2>/dev/null; then
    echo " Topic already exists"
else
    gcloud pubsub topics create $TOPIC_NAME
    echo " Topic created: $TOPIC_NAME"
fi

# Summary
echo ""
echo " Infrastructure Setup Complete"
echo ""
echo "Created resources:"
echo "  Pub/Sub Topic: $TOPIC_NAME"
echo "  Storage Bucket: gs://$BUCKET_NAME"
echo ""
echo "Next step: Deploy Cloud Function"