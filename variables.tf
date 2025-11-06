variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1"
}

variable "queue_name" {
  description = "SQS queue name"
  type        = string
  default     = "cpu-monitor-queue"
}

data "aws_caller_identity" "current" {}
