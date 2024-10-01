resource "aws_cloudwatch_event_rule" "s3_event" {
  name                 = "s3_event_rule"
  description          = "Trigger Lambda every hour"
  schedule_expression  = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_event.name
  arn       = aws_lambda_function.s3_transfer_and_notify.arn

  # Lambda function permission to be triggered by CloudWatch Events
  depends_on = [
    aws_lambda_permission.cloudwatch_permission
  ]
}

resource "aws_lambda_permission" "cloudwatch_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_transfer_and_notify.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_event.arn
}
# CloudWatch Alarm for CPU utilization (example)
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high_cpu_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  # Replace with the EC2 instance ID
  dimensions = {
    InstanceId = "i-0123456789abcdef0"
  }

  # When alarm triggers, send notification to SNS
  alarm_actions = [
    aws_sns_topic.cloudwatch_alarm_topic.arn
  ]
}
