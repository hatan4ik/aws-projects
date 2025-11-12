variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod) used for tagging and naming"
  type        = string
}

variable "name_prefix" {
  description = "Optional prefix added to resource names to support multi-environment reuse"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
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
  description = "Instance types used by Image Builder during AMI creation"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "share_ami_package_path" {
  description = "Absolute path to the packaged Share AMI Lambda artifact"
  type        = string
}

variable "update_launch_template_package_path" {
  description = "Absolute path to the packaged Update Launch Template Lambda artifact"
  type        = string
}

variable "trigger_instance_refresh_package_path" {
  description = "Absolute path to the packaged Trigger Instance Refresh Lambda artifact"
  type        = string
}

variable "check_refresh_status_package_path" {
  description = "Absolute path to the packaged Check Refresh Status Lambda artifact"
  type        = string
}

variable "rollback_ami_package_path" {
  description = "Absolute path to the packaged Rollback AMI Lambda artifact"
  type        = string
}

variable "ssm_parameter_name" {
  description = "SSM Parameter name that stores the latest golden AMI ID"
  type        = string
  validation {
    condition     = startswith(var.ssm_parameter_name, "/")
    error_message = "SSM parameter names must start with /"
  }
}

variable "ssm_parameter_initial_value" {
  description = "Initial placeholder value stored in the SSM parameter"
  type        = string
  default     = "ami-placeholder"
}

variable "kms_deletion_window_in_days" {
  description = "Number of days before the KMS key is deleted after scheduling"
  type        = number
  default     = 10
}
