# Create SNS Topic
resource "aws_sns_topic" "cloudwatch_alarm_topic" {
  name = "cloudwatch_alarm_topic"
}
