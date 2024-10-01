# Create the Lambda function
resource "aws_lambda_function" "s3_transfer" {
  function_name = "S3TransferFunction"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  # Path to the deployment package zip file
  s3_bucket = aws_s3_bucket.external.bucket
  s3_key    = "lambda_function.zip" 

environment {
    variables = {
      DESTINATION_BUCKET = aws_s3_bucket.internal.bucket
    }
  }


  role = aws_iam_role.lambda_role.arn

  tags = {
    Environment = var.Environment
    Owner       = var.Owner
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_transfer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.external.arn
}


# Set up S3 bucket notification to trigger the Lambda function
resource "aws_s3_bucket_notification" "external_bucket_notification" {
  bucket = aws_s3_bucket.external.bucket

  lambda_function {
    events = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.s3_transfer.arn
  }
  depends_on = [aws_lambda_permission.allow_s3]
}
