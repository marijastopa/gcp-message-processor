#!/bin/bash

# Test script for message processing pipeline

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

echo "Testing Message Processing Pipeline"
echo ""
echo ""

echo "1. Verifying infrastructure..."

echo -n "   Checking Pub/Sub topic... "
if gcloud pubsub topics describe $TOPIC_NAME &>/dev/null; then
    echo "ok"
else
    echo "   Error: Topic not found. Run ./setup-infrastructure.sh first"
    exit 1
fi

echo -n "   Checking Storage bucket... "
if gsutil ls -b gs://$BUCKET_NAME &>/dev/null; then
    echo "ok"
else
    echo "   Error: Bucket not found. Run ./setup-infrastructure.sh first"
    exit 1
fi

echo -n "   Checking Cloud Function... "
if gcloud functions describe $FUNCTION_NAME --region=$REGION --gen2 &>/dev/null; then
    echo "ok"
else
    echo "   Error: Function not deployed. Run ./deploy-function.sh first"
    exit 1
fi

echo ""

echo "2. Publishing test messages..."

echo "   Message 1: Simple text"
gcloud pubsub topics publish $TOPIC_NAME \
    --message="Test message from pipeline verification" \
    --quiet

sleep 2

echo "   Message 2: JSON data"
gcloud pubsub topics publish $TOPIC_NAME \
    --message='{"event":"test","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' \
    --attribute=type=json,source=test-script \
    --quiet

sleep 2

echo "   Message 3: Alert"
gcloud pubsub topics publish $TOPIC_NAME \
    --message="ALERT: Test alert message" \
    --attribute=severity=info,type=alert \
    --quiet

echo "    Published 3 test messages"
echo ""

echo "3. Waiting for processing (10 seconds)..."
sleep 10
echo ""

echo "4. Verifying results..."
echo ""

# Count files
echo "   Files in storage:"
FILE_COUNT=$(gsutil ls gs://$BUCKET_NAME/ 2>/dev/null | wc -l)
if [ $FILE_COUNT -gt 0 ]; then
    gsutil ls -l gs://$BUCKET_NAME/ | tail -5
    echo ""
    echo "    Found $FILE_COUNT file(s)"
else
    echo "    No files found"
fi

echo ""

# Show latest file content
if [ $FILE_COUNT -gt 0 ]; then
    echo "   Latest file content:"
    echo "   ---"
    LATEST_FILE=$(gsutil ls gs://$BUCKET_NAME/ | tail -1)
    gsutil cat $LATEST_FILE | head -15
    echo "   ---"
fi

echo ""

echo "5. Recent function logs:"
gcloud functions logs read $FUNCTION_NAME \
    --region=$REGION \
    --gen2 \
    --limit=10 \
    --format="table(time_utc,log)"

echo ""
echo "  Test Summary"
echo "Infrastructure: "
echo "Messages published: "
echo "Files in storage: $FILE_COUNT"
echo ""

if [ $FILE_COUNT -ge 3 ]; then
    echo "All tests passed!"
else
    echo "  Warning: Expected at least 3 files, found $FILE_COUNT"
    echo "  Check function logs for errors"
fi
