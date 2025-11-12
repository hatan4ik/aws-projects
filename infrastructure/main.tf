terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  share_ami_package_path                = coalesce(var.share_ami_package_path, "${path.module}/../lambda/packages/share_ami.zip")
  update_launch_template_package_path   = coalesce(var.update_launch_template_package_path, "${path.module}/../lambda/packages/update_launch_template.zip")
  trigger_instance_refresh_package_path = coalesce(var.trigger_instance_refresh_package_path, "${path.module}/../lambda/packages/trigger_instance_refresh.zip")
  check_refresh_status_package_path     = coalesce(var.check_refresh_status_package_path, "${path.module}/../lambda/packages/check_refresh_status.zip")
  rollback_ami_package_path             = coalesce(var.rollback_ami_package_path, "${path.module}/../lambda/packages/rollback_ami.zip")
  ssm_parameter_name                    = coalesce(var.ssm_parameter_name, "/amis/${var.environment}/latest-golden-ami")
}

module "ami_pipeline" {
  source = "./modules/ami-pipeline"

  aws_region  = var.aws_region
  environment = var.environment
  name_prefix = var.name_prefix
  tags        = var.tags

  source_ami_id       = var.source_ami_id
  notification_email  = var.notification_email
  schedule_expression = var.schedule_expression

  consumer_account_ids     = var.consumer_account_ids
  launch_template_ids      = var.launch_template_ids
  auto_scaling_group_names = var.auto_scaling_group_names

  imagebuilder_instance_types = var.imagebuilder_instance_types

  share_ami_package_path                = local.share_ami_package_path
  update_launch_template_package_path   = local.update_launch_template_package_path
  trigger_instance_refresh_package_path = local.trigger_instance_refresh_package_path
  check_refresh_status_package_path     = local.check_refresh_status_package_path
  rollback_ami_package_path             = local.rollback_ami_package_path

  ssm_parameter_name          = local.ssm_parameter_name
  ssm_parameter_initial_value = var.ssm_parameter_initial_value
  kms_deletion_window_in_days = var.kms_deletion_window_in_days
}
