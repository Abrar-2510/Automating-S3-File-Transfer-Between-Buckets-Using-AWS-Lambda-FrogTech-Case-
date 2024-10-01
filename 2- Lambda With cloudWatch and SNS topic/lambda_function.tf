# Create the Lambda function for S3 transfer and Slack notifications
resource "aws_lambda_function" "s3_transfer_and_notify" {
  function_name = "S3TransferAndNotifyFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  # Path to the deployment package zip file
  s3_bucket = aws_s3_bucket.external.bucket
  s3_key    = "lambda_function.zip" 

  environment {
    variables = {
      DESTINATION_BUCKET = aws_s3_bucket.internal.bucket
      SLACK_WEBHOOK_URL  = var.slack_webhook_url  # Slack Webhook URL
    }
  }

  role = aws_iam_role.lambda_role.arn

  tags = {
    Environment = var.Environment
    Owner       = var.Owner
  }
}

# Allow S3 to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_transfer_and_notify.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.external.arn
}

# Set up S3 bucket notification to trigger the Lambda function
resource "aws_s3_bucket_notification" "external_bucket_notification" {
  bucket = aws_s3_bucket.external.bucket

  lambda_function {
    events = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.s3_transfer_and_notify.arn
  }
  depends_on = [aws_lambda_permission.allow_s3]
}

# Allow SNS to trigger the Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_transfer_and_notify.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_alarm_topic.arn
}

# Set Up SNS Subscription for Lambda
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alarm_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.s3_transfer_and_notify.arn
}
