"""
Cloud Function: Message Processor
Triggered by: Cloud Pub/Sub messages
Action: Saves message content to Cloud Storage
"""

import base64
import json
import os
from datetime import datetime
from google.cloud import storage
import functions_framework

# Initialize storage client
storage_client = storage.Client()


@functions_framework.cloud_event
def process_message(cloud_event):
    """
    Processes Pub/Sub message and saves to Cloud Storage.
    
    Args:
        cloud_event: CloudEvent containing Pub/Sub message data
    """
    bucket_name = os.environ.get('BUCKET_NAME')
    
    if not bucket_name:
        raise ValueError("BUCKET_NAME environment variable not set")
    
    try:
        # Extract message data
        pubsub_message = cloud_event.data.get('message', {})
        message_data = base64.b64decode(
            pubsub_message.get('data', '')
        ).decode('utf-8')
        
        # Generate unique filename
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S_%f')
        message_id = pubsub_message.get('messageId', 'unknown')
        filename = f"message_{timestamp}_{message_id}.json"
        
        # Prepare file content with metadata
        content = {
            "timestamp": datetime.utcnow().isoformat(),
            "message_id": message_id,
            "message": message_data,
            "attributes": pubsub_message.get('attributes', {}),
            "publish_time": pubsub_message.get('publishTime', '')
        }
        
        # Upload to Cloud Storage
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(filename)
        blob.upload_from_string(
            json.dumps(content, indent=2),
            content_type='application/json'
        )
        
        print(f"Message saved: gs://{bucket_name}/{filename}")
        
    except Exception as e:
        print(f"Error processing message: {e}")
        raise