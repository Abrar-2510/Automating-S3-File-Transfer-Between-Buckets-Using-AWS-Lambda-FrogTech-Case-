import os
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Log the entire event to understand its structure
    print("Received event:", event)

    # Get the destination bucket name from the environment variable
    destination_bucket = os.environ['DESTINATION_BUCKET']

    # Get the source bucket name and object key from the event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']

    # Initialize the S3 client
    s3 = boto3.client('s3')

    # Check if the object exists before copying
    try:
        s3.head_object(Bucket=source_bucket, Key=source_key)
    except ClientError as e:
        if e.response['Error']['Code'] == '404':
            print(f"Object {source_key} does not exist in bucket {source_bucket}.")
            return {
                'statusCode': 404,
                'body': f'Object {source_key} not found in bucket {source_bucket}.'
            }
        else:
            raise e

    # Copy the object from the source bucket to the destination bucket
    try:
        copy_source = {'Bucket': source_bucket, 'Key': source_key}
        s3.copy_object(CopySource=copy_source, Bucket=destination_bucket, Key=source_key)
        print(f"Successfully copied {source_key} from {source_bucket} to {destination_bucket}.")
        return {
            'statusCode': 200,
            'body': f'Successfully copied {source_key} to {destination_bucket}.'
        }
    except Exception as e:
        print(f"Error copying object: {e}")
        raise e
