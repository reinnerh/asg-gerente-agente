provider "aws" {
  region = "sa-east-1"
}

resource "aws_sqs_queue" "cpu_monitor_queue" {
  name = "cpu-monitor-queue"
}
