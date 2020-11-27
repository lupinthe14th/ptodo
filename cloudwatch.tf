resource "aws_cloudwatch_log_group" "ptodo" {
  name              = "/ecs/ptodo"
  retention_in_days = 180
}
