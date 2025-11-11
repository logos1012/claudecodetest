variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2" # Seoul region
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "daily-log-automation"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "DailyLogAutomation"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

# Secrets will be stored in AWS Secrets Manager
# You'll need to create a secret with the following keys:
# - airtable_api_key
# - airtable_base_id
# - airtable_table_name
# - openai_api_key

variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
  default     = "daily-log-automation-secrets"
}
