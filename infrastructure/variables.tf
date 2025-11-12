variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "name_prefix" {
  description = "Optional prefix added to resource names"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to Terraform-managed resources"
  type        = map(string)
  default     = {}
}

variable "source_ami_id" {
  description = "Source AMI ID to patch"
  type        = string
  validation {
    condition     = can(regex("^ami-[a-z0-9]{8,17}$", var.source_ami_id))
    error_message = "Source AMI ID must be a valid AMI identifier."
  }
}

variable "notification_email" {
  description = "Email for pipeline notifications"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address."
  }
}

variable "schedule_expression" {
  description = "EventBridge schedule expression"
  type        = string
  default     = "cron(0 2 ? * SUN *)"
}

variable "consumer_account_ids" {
  description = "AWS account IDs to share AMI with"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for id in var.consumer_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "All consumer account IDs must be 12-digit AWS account numbers."
  }
}

variable "launch_template_ids" {
  description = "Launch Template IDs to update"
  type        = list(string)
  default     = []
}

variable "auto_scaling_group_names" {
  description = "Auto Scaling Group names for instance refresh"
  type        = list(string)
  default     = []
}

variable "imagebuilder_instance_types" {
  description = "Instance types used during Image Builder executions"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "share_ami_package_path" {
  description = "Override path to the Share AMI Lambda package"
  type        = string
  default     = null
}

variable "update_launch_template_package_path" {
  description = "Override path to the Update Launch Template Lambda package"
  type        = string
  default     = null
}

variable "trigger_instance_refresh_package_path" {
  description = "Override path to the Trigger Instance Refresh Lambda package"
  type        = string
  default     = null
}

variable "check_refresh_status_package_path" {
  description = "Override path to the Check Refresh Status Lambda package"
  type        = string
  default     = null
}

variable "rollback_ami_package_path" {
  description = "Override path to the Rollback AMI Lambda package"
  type        = string
  default     = null
}

variable "ssm_parameter_name" {
  description = "Override name for the SSM parameter that stores the latest AMI"
  type        = string
  default     = null
}

variable "ssm_parameter_initial_value" {
  description = "Initial placeholder value written to the SSM parameter"
  type        = string
  default     = "ami-placeholder"
}

variable "kms_deletion_window_in_days" {
  description = "Number of days before the custom KMS key is deleted after scheduling"
  type        = number
  default     = 10
}
