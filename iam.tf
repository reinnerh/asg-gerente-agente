# ========== POLICY: Gerente ==========
resource "aws_iam_policy" "asg_gerente_policy" {
  name        = "ASGGerentePolicy"
  description = "Permite que EC2 gerente leia do SQS e escale ASG"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ],
        Resource = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cpu-monitor-queue"
      }
    ]
  })
}

# ========== POLICY: Agente ==========
resource "aws_iam_policy" "asg_agente_policy" {
  name        = "ASGAgentePolicy"
  description = "Permite que EC2 agente envie mensagens para o SQS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cpu-monitor-queue"
      }
    ]
  })
}

# ========== ROLE: Gerente ==========
resource "aws_iam_role" "asg_gerente_role" {
  name = "ASGGerenteRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# ========== ROLE: Agente ==========
resource "aws_iam_role" "asg_agente_role" {
  name = "ASGAgenteRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# ========== ATTACH: Gerente ==========
resource "aws_iam_role_policy_attachment" "asg_gerente_attach" {
  role       = aws_iam_role.asg_gerente_role.name
  policy_arn = aws_iam_policy.asg_gerente_policy.arn
}

# ========== ATTACH: Agente ==========
resource "aws_iam_role_policy_attachment" "asg_agente_attach" {
  role       = aws_iam_role.asg_agente_role.name
  policy_arn = aws_iam_policy.asg_agente_policy.arn
}