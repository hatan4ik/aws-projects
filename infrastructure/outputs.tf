output "kms_key_id" {
  description = "KMS Key ID for AMI encryption"
  value       = module.ami_pipeline.kms_key_id
}

output "kms_key_arn" {
  description = "KMS Key ARN for AMI encryption"
  value       = module.ami_pipeline.kms_key_arn
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for notifications"
  value       = module.ami_pipeline.sns_topic_arn
}

output "image_pipeline_arn" {
  description = "Image Builder Pipeline ARN"
  value       = module.ami_pipeline.image_pipeline_arn
}

output "step_functions_arn" {
  description = "Step Functions State Machine ARN"
  value       = module.ami_pipeline.step_functions_arn
}

output "ssm_parameter_name" {
  description = "SSM Parameter name for latest AMI"
  value       = module.ami_pipeline.ssm_parameter_name
}
