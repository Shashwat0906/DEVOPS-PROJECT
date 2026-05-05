# =====================================================================
# IAM Role Management - Supports Restricted AWS Environments
# =====================================================================
# This file uses existing IAM role ARNs when provided (e.g., AWS Academy LabRole).
# For unrestricted environments, leave the role_arn variables empty in terraform.tfvars
# to automatically create new roles.
#
# NOTE: In AWS Academy or restricted IAM environments:
#   1. Use the LabRole ARN provided by your institution
#   2. Set ecs_task_execution_role_arn, ecs_task_role_arn, and autoscaling_role_arn
#   3. The aws_iam_role resources below will be conditionally skipped
# =====================================================================

# =====================================================================
# Local Variables - Use existing roles if provided
# =====================================================================

locals {
  use_existing_execution_role   = var.ecs_task_execution_role_arn != ""
  use_existing_task_role        = var.ecs_task_role_arn != ""
  use_existing_autoscaling_role = var.autoscaling_role_arn != ""

  # Default to created roles or use provided ARNs
  ecs_task_execution_role_arn = local.use_existing_execution_role ? var.ecs_task_execution_role_arn : try(aws_iam_role.ecs_task_execution_role[0].arn, "")
  ecs_task_role_arn           = local.use_existing_task_role ? var.ecs_task_role_arn : try(aws_iam_role.ecs_task_role[0].arn, "")
  autoscaling_role_arn        = local.use_existing_autoscaling_role ? var.autoscaling_role_arn : try(aws_iam_role.autoscaling_role[0].arn, "")
}

# =====================================================================
# ECS Task Execution Role (ONLY created if not using existing role)
# =====================================================================

resource "aws_iam_role" "ecs_task_execution_role" {
  count = local.use_existing_execution_role ? 0 : 1

  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

# =====================================================================
# Attach AWS managed policy for ECS task execution
# =====================================================================

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  count      = local.use_existing_execution_role ? 0 : 1
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# =====================================================================
# Custom inline policy for ECS task execution (ECR + CloudWatch)
# =====================================================================

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  count = local.use_existing_execution_role ? 0 : 1

  name = "${var.project_name}-ecs-task-execution-policy"
  role = aws_iam_role.ecs_task_execution_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:*:repository/${var.ecr_repository_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_logs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/*"
      }
    ]
  })
}

# =====================================================================
# ECS Task Role (ONLY created if not using existing role)
# =====================================================================

resource "aws_iam_role" "ecs_task_role" {
  count = local.use_existing_task_role ? 0 : 1

  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# =====================================================================
# Custom policy for ECS task role (S3, DynamoDB, RDS, etc.)
# =====================================================================

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  count = local.use_existing_task_role ? 0 : 1

  name = "${var.project_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.project_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# =====================================================================
# Auto Scaling Role (ONLY created if not using existing role)
# =====================================================================

resource "aws_iam_role" "autoscaling_role" {
  count = local.use_existing_autoscaling_role ? 0 : 1

  name = "${var.project_name}-autoscaling-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-autoscaling-role"
  }
}

# =====================================================================
# Attach managed policy for Auto Scaling
# =====================================================================

resource "aws_iam_role_policy_attachment" "autoscaling_policy" {
  count      = local.use_existing_autoscaling_role ? 0 : 1
  role       = aws_iam_role.autoscaling_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

# =====================================================================
# Custom policy for Auto Scaling
# =====================================================================

resource "aws_iam_role_policy" "autoscaling_policy" {
  count = local.use_existing_autoscaling_role ? 0 : 1

  name = "${var.project_name}-autoscaling-policy"
  role = aws_iam_role.autoscaling_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}
