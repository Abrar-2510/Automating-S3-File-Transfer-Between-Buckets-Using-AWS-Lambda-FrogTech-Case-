import os
import boto3
from botocore.exceptions import ClientError
import json
import urllib3

# Function to send messages to Slack
def send_to_slack(slack_webhook_url, message):
    http = urllib3.PoolManager()
    slack_message = {
        'text': message
    }
    response = http.request(
        'POST',
        slack_webhook_url,
        body=json.dumps(slack_message),
        headers={'Content-Type': 'application/json'},
    )
    return response.status, response.data

def lambda_handler(event, context):
    print("Received event:", event)

    # Get Slack webhook URL from environment variable
    slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']

    # Check if the event is from S3
    if 'Records' in event and 's3' in event['Records'][0]:
        # Process S3 event
        destination_bucket = os.environ['DESTINATION_BUCKET']
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        source_key = event['Records'][0]['s3']['object']['key']

        # Initialize the S3 and CloudWatch clients
        s3 = boto3.client('s3')
        cloudwatch = boto3.client('cloudwatch')

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
            success_message = f"Successfully copied {source_key} from {source_bucket} to {destination_bucket}."
            print(success_message)

            # Publish a custom metric to CloudWatch
            cloudwatch.put_metric_data(
                Namespace='FileTransfer',
                MetricData=[
                    {
                        'MetricName': 'FilesTransferred',
                        'Value': 1,
                        'Unit': 'Count'
                    },
                ]
            )

            # Send success message to Slack
            send_to_slack(slack_webhook_url, success_message)

            return {
                'statusCode': 200,
                'body': success_message
            }
        except Exception as e:
            error_message = f"Error copying object: {e}"
            print(error_message)

            # Send error message to Slack
            send_to_slack(slack_webhook_url, error_message)

            return {
                'statusCode': 500,
                'body': error_message
            }

    elif 'Records' in event and 'Sns' in event['Records'][0]:
        # Process SNS event
        message = event['Records'][0]['Sns']['Message']
        send_to_slack(slack_webhook_url, f"CloudWatch Alarm: {message}")
        return {
            'statusCode': 200,
            'body': "SNS message sent to Slack."
        }

    return {
        'statusCode': 400,
        'body': "Unsupported event type."
    }

# json file test
# {
#   "Records": [
#     {
#       "Sns": {
#         "Message": "CloudWatch Alarm: Your alarm has been triggered!"
#       }
#     }
#   ]
# }
