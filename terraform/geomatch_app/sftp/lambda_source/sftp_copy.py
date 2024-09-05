import os
import sys
from typing import TYPE_CHECKING, Optional

from dataclasses import dataclass, asdict
import json
import boto3

if TYPE_CHECKING:
    from mypy_boto3_sagemaker import SageMakerClient

def handler(event, context = {}):
    """
    See https://docs.aws.amazon.com/transfer/latest/userguide/custom-step-details.html
    for event schema
    """
    env = os.environ

    s3_client = boto3.client('s3')
    transfer_client = boto3.client('transfer')
    
    bucket_name = event["fileLocation"]["bucket"]
    file_key = event["fileLocation"]["key"]
    user = event["serviceMetadata"]["userName"]

    if not user:
        raise ValueError("No user in event")
    mount_path = env.get("MOUNT_PATH", None)
    if not mount_path:
        raise ValueError("No MOUNT_PATH set")

    local_file_path = os.path.join(mount_path, user, file_key)
    
    # Create directories if they do not exist
    os.makedirs(os.path.dirname(local_file_path), exist_ok=True)
    
    s3_client.download_file(bucket_name, file_key, local_file_path)

    response = transfer_client.send_workflow_step_state(
        WorkflowId=event['serviceMetadata']['executionDetails']['workflowId'],
        ExecutionId=event['serviceMetadata']['executionDetails']['executionId'],
        Token=event['token'],
        Status='SUCCESS'
    )
    print(json.dumps(response))

    return {
        'statusCode': 200,
        'body': {}
    }

if __name__ == "__main__":
    res = json.dumps(handler({}, {}), indent=3)
    print(res)
