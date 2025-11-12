output "kms_key_id" {
  description = "KMS Key ID for AMI encryption"
  value       = aws_kms_key.ami_encryption.key_id
}

output "kms_key_arn" {
  description = "KMS Key ARN for AMI encryption"
  value       = aws_kms_key.ami_encryption.arn
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for notifications"
  value       = aws_sns_topic.ami_pipeline.arn
}

output "image_pipeline_arn" {
  description = "Image Builder Pipeline ARN"
  value       = aws_imagebuilder_image_pipeline.main.arn
}

output "step_functions_arn" {
  description = "Step Functions State Machine ARN"
  value       = aws_sfn_state_machine.ami_pipeline.arn
}

output "ssm_parameter_name" {
  description = "SSM Parameter name for latest AMI"
  value       = aws_ssm_parameter.latest_golden_ami.name
}
