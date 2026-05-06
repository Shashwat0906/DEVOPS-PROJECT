variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devops-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB (512, 1024, 2048, 4096, 8192)"
  type        = number
  default     = 1024
}

variable "ecs_task_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2

  validation {
    condition     = var.ecs_task_count > 0 && var.ecs_task_count <= 10
    error_message = "Task count must be between 1 and 10."
  }
}

variable "container_port" {
  description = "Port exposed by container"
  type        = number
  default     = 5001
}

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes to mark healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures to mark unhealthy"
  type        = number
  default     = 3
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "devops-app"
}

variable "ecr_image_tag_mutability" {
  description = "Whether ECR image tags are immutable"
  type        = bool
  default     = false
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push to ECR"
  type        = bool
  default     = true
}

variable "ecs_task_definition_family" {
  description = "ECS task definition family"
  type        = string
  default     = "devops-task"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "auto_scaling_min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "auto_scaling_max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 4
}

variable "cpu_target_tracking_value" {
  description = "CPU utilization target for auto-scaling (%)"
  type        = number
  default     = 70
}

variable "memory_target_tracking_value" {
  description = "Memory utilization target for auto-scaling (%)"
  type        = number
  default     = 80
}

variable "ecs_task_execution_role_arn" {

  description = "ARN of existing IAM role for ECS task execution (e.g., AWS Academy LabRole). Leave empty to create a new role."
  type        = string
  default     = ""
}

variable "ecs_task_role_arn" {
  description = "ARN of existing IAM role for ECS task application permissions (e.g., AWS Academy LabRole). Leave empty to create a new role."
  type        = string
  default     = ""
}

variable "autoscaling_role_arn" {
  description = "ARN of existing IAM role for ECS auto-scaling (e.g., AWS Academy LabRole). Leave empty to create a new role."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
