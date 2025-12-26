# GCP Message Processing Pipeline

Event-driven serverless architecture for message processing using Google Cloud Platform.

## Architecture

```
Pub/Sub Topic → Cloud Function → Cloud Storage
```

**Flow:**
1. Messages published to Cloud Pub/Sub topic
2. Cloud Function automatically triggered by Pub/Sub events
3. Function processes message and saves to Cloud Storage as JSON

## Components

- **Cloud Pub/Sub** - Message broker for asynchronous messaging
- **Cloud Functions (Gen2)** - Serverless compute for event processing
- **Cloud Storage** - Object storage for persisting processed messages

## Prerequisites

- Google Cloud Platform account
- Active GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- Project roles: Owner or Editor

## Quick Start

### 1. Initial Setup

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/gcp-message-processor.git
cd gcp-message-processor

# Edit .env and set your PROJECT_ID
nano .env
```
### 2. Deploy Infrastructure

```bash
# Make scripts executable
chmod +x *.sh

# Create GCP resources (Pub/Sub topic, Storage bucket, enable APIs)
./setup-infrastructure.sh
```

**What this creates:**
- Pub/Sub topic: `message-topic`
- Storage bucket: `{PROJECT_ID}-message-storage`
- Enables required GCP APIs

### 3. Deploy Cloud Function

```bash
./deploy-function.sh
```
### 4. Test the Pipeline

```bash
./test-pipeline.sh
```

This automated test:
- Verifies all components are deployed
- Publishes 3 test messages
- Waits for processing
- Displays results and logs

## Essential Commands

### Publishing Messages

```bash
# Simple text message
gcloud pubsub topics publish message-topic --message="Your message here"

# Message with attributes
gcloud pubsub topics publish message-topic \
  --message='{"event":"user_login","user_id":123}' \
  --attribute=type=json,priority=high
```

### Checking Results

```bash
# List files in storage
gsutil ls gs://PROJECT_ID-message-storage/

# View latest file
gsutil cat $(gsutil ls gs://PROJECT_ID-message-storage/ | tail -1)

# View specific file
gsutil cat gs://PROJECT_ID-message-storage/message_20251226_180648_396197_16968718751361250.json
```

### Viewing Logs

```bash
# Recent function logs
gcloud functions logs read message-processor \
  --region=europe-west1 \
  --gen2 \
  --limit=20

# Follow logs (real-time)
gcloud functions logs read message-processor \
  --region=europe-west1 \
  --gen2 \
  --limit=50 \
  --follow

# Filter errors only
gcloud functions logs read message-processor \
  --region=europe-west1 \
  --gen2 \
  --filter="severity>=ERROR"
```

### Infrastructure Status

```bash
# Check function status
gcloud functions describe message-processor \
  --region=europe-west1 \
  --gen2

# Check Pub/Sub topic
gcloud pubsub topics describe message-topic

# Check storage bucket
gsutil ls -L -b gs://PROJECT_ID-message-storage
```

## Message Format

Messages are saved as JSON files with the following structure:

```json
{
  "timestamp": "2025-12-26T18:06:48.396232",
  "message_id": "16968718751361250",
  "message": "Your message content",
  "attributes": {
    "custom_key": "custom_value"
  },
  "publish_time": "2025-12-26T18:06:46.506Z"
}
```

**Filename format:** `message_{timestamp}_{microseconds}_{message_id}.json`

## Project Structure

```
.
├── .gitignore               # Git ignore rules
├── README.md                # This file
├── main.py                  # Cloud Function source code
├── requirements.txt         # Python dependencies
├── setup-infrastructure.sh  # Infrastructure setup script
├── deploy-function.sh       # Function deployment script
├── test-pipeline.sh         # Automated testing script
└── cleanup.sh               # Resource cleanup script
```

## Troubleshooting

### APIs Not Enabled

**Error:** `API has not been used in project...`

**Solution:**
```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com
```

### Permission Denied

**Error:** `PERMISSION_DENIED`

**Solution:** Ensure your account has Owner or Editor role:
```bash
gcloud projects get-iam-policy PROJECT_ID
```

### Function Not Triggering

**Check deployment:**
```bash
gcloud functions describe message-processor --region=europe-west1 --gen2
```

**Check Pub/Sub subscription:**
```bash
gcloud pubsub topics list-subscriptions message-topic
```

**Check logs for errors:**
```bash
gcloud functions logs read message-processor \
  --region=europe-west1 \
  --gen2 \
  --filter="severity>=ERROR"
```

### No Files in Storage

**Verify bucket access:**
```bash
gsutil ls -L -b gs://PROJECT_ID-message-storage
```

**Check function logs:**
```bash
gcloud functions logs read message-processor \
  --region=europe-west1 \
  --gen2 \
  --limit=50
```

## Cleanup

Remove all resources to avoid charges:

```bash
./cleanup.sh
```

This deletes:
- Cloud Function
- Pub/Sub topic and subscriptions
- Storage bucket and all files

**Warning:** This action cannot be undone. 

## Development Workflow

### Redeploying After Changes

```bash
# Redeploy function after code changes
./deploy-function.sh

# Test changes
./test-pipeline.sh
```

## Key Features

- **Event-driven architecture** - Automatic triggering via Pub/Sub
- **Serverless** - No infrastructure management required
- **Scalable** - Auto-scaling from 0 to max instances
- **Reliable** - Built-in retry mechanism for failed messages
- **Secure** - Environment-based configuration, no hardcoded secrets
- **Cost-effective** - Pay only for execution time
- **Metadata preservation** - All message attributes saved
- **Unique filenames** - Timestamp-based naming prevents overwrites

## Best Practices Implemented

1. **Infrastructure as Code** - All resources created via scripts
2. **Environment Variables** - Configuration separated from code
3. **Error Handling** - Proper exception handling with logging
4. **Resource Limits** - Memory and timeout constraints defined
5. **Git Workflow** - Feature branches and pull requests
6. **Security** - Sensitive data excluded from version control
7. **Automated Testing** - End-to-end pipeline verification
8. **Documentation** - Comprehensive README and code comments

## Support & Documentation

- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Cloud Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [GCP Best Practices](https://cloud.google.com/architecture/framework)
