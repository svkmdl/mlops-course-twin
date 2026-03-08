variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name must contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
    description = "Environment name (dev, test, prod)"
    type        = string
    validation {
        condition     = contains(["dev", "test", "prod"], var.environment)
        error_message = "Environment must be one of: dev, test, prod."
    }
}

variable "bedrock_model_id" {
  description = "ID of the Bedrock model to use"
  type        = string
  default     = "eu.amazon.nova-micro-v1:0"
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 60
}

variable "api_throttle_burst_limit" {
  description = "Burst limit for API Gateway throttling"
  type        = number
  default     = 10
}

variable "api_throttle_rate_limit" {
  description = "Rate limit for API Gateway throttling (requests per second)"
  type        = number
  default     = 5
}

variable "use_custom_domain" {
  description = "Attach a custom domain to CloudFront distribution"
  type        = bool
  default     =  false
}

variable "root_domain" {
  description = "Apex domain for the custom domain (e.g., example.com)"
  type        = string
  default     = ""
}