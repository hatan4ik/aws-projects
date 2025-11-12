locals {
  raw_prefix        = trimspace(coalesce(var.name_prefix, ""))
  normalized_prefix = length(local.raw_prefix) > 0 ? local.raw_prefix : "ami-pipeline"
  resource_prefix   = "${local.normalized_prefix}-${var.environment}"
  sanitized_prefix  = replace(replace(lower(local.resource_prefix), "_", "-"), " ", "-")
  log_bucket_name   = "${local.sanitized_prefix}-logs-${data.aws_caller_identity.current.account_id}"
  tags = merge({
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = local.normalized_prefix
  }, var.tags)
}

# KMS Key for AMI Encryption
resource "aws_kms_key" "ami_encryption" {
  description             = "${local.normalized_prefix} KMS key for AMI encryption"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Image Builder"
        Effect = "Allow"
        Principal = {
          Service = "imagebuilder.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "ami_encryption" {
  name          = "alias/${local.sanitized_prefix}-ami-encryption"
  target_key_id = aws_kms_key.ami_encryption.key_id
}

# SNS Topic for Notifications
resource "aws_sns_topic" "ami_pipeline" {
  name              = "${local.sanitized_prefix}-notifications"
  kms_master_key_id = aws_kms_key.ami_encryption.id
  tags              = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.ami_pipeline.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# SSM Parameter for Latest AMI
resource "aws_ssm_parameter" "latest_golden_ami" {
  name  = var.ssm_parameter_name
  type  = "String"
  value = var.ssm_parameter_initial_value

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.tags
}

# IAM Role for Image Builder
resource "aws_iam_role" "image_builder" {
  name = "${local.resource_prefix}-image-builder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "image_builder_managed" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "image_builder_ssm" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "image_builder" {
  name = "${local.resource_prefix}-image-builder-profile"
  role = aws_iam_role.image_builder.name
}

# Image Builder Component
resource "aws_imagebuilder_component" "patch_linux" {
  name     = "${local.resource_prefix}-patch-linux"
  platform = "Linux"
  version  = "1.0.0"

  data = yamlencode({
    name          = "PatchLinuxAMI"
    description   = "Patch Linux AMI with latest updates"
    schemaVersion = 1.0
    phases = [{
      name = "build"
      steps = [{
        name   = "UpdateOS"
        action = "UpdateOS"
      }]
    }]
  })

  tags = local.tags
}

# Image Builder Recipe
resource "aws_imagebuilder_image_recipe" "golden_ami" {
  name         = "${local.resource_prefix}-recipe"
  parent_image = var.source_ami_id
  version      = "1.0.0"

  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.ami_encryption.arn
    }
  }

  component {
    component_arn = aws_imagebuilder_component.patch_linux.arn
  }

  component {
    component_arn = "arn:aws:imagebuilder:${var.aws_region}:aws:component/inspector-test-linux/1.0.0"
  }

  tags = local.tags
}

# Image Builder Infrastructure Configuration
resource "aws_imagebuilder_infrastructure_configuration" "main" {
  name                          = "${local.resource_prefix}-infra"
  instance_profile_name         = aws_iam_instance_profile.image_builder.name
  instance_types                = var.imagebuilder_instance_types
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = aws_s3_bucket.image_builder_logs.id
    }
  }

  tags = local.tags
}

# S3 Bucket for Logs
resource "aws_s3_bucket" "image_builder_logs" {
  bucket = local.log_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "image_builder_logs" {
  bucket = aws_s3_bucket.image_builder_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Image Builder Distribution Configuration
resource "aws_imagebuilder_distribution_configuration" "main" {
  name = "${local.resource_prefix}-distribution"

  distribution {
    region = var.aws_region

    ami_distribution_configuration {
      name = "${local.normalized_prefix}-ami-{{ imagebuilder:buildDate }}"

      ami_tags = {
        Name        = "${local.normalized_prefix}-golden-ami"
        BuildDate   = "{{ imagebuilder:buildDate }}"
        Environment = var.environment
      }

      kms_key_id = aws_kms_key.ami_encryption.arn
    }
  }

  tags = local.tags
}

# Image Builder Pipeline
resource "aws_imagebuilder_image_pipeline" "main" {
  name                             = "${local.resource_prefix}-pipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_ami.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.main.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.main.arn

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 60
  }

  status = "ENABLED"
  tags   = local.tags
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda" {
  name = "${local.resource_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "lambda" {
  name = "${local.resource_prefix}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeImages",
          "ec2:ModifyImageAttribute",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DescribeLaunchTemplates",
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/amis/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:PutKeyPolicy",
          "kms:GetKeyPolicy"
        ]
        Resource = aws_kms_key.ami_encryption.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.ami_pipeline.arn
      }
    ]
  })
}

# Lambda: Share AMI
resource "aws_lambda_function" "share_ami" {
  filename         = var.share_ami_package_path
  function_name    = "${local.resource_prefix}-share-ami"
  role             = aws_iam_role.lambda.arn
  handler          = "share_ami.handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256(var.share_ami_package_path)

  environment {
    variables = {
      KMS_KEY_ID           = aws_kms_key.ami_encryption.key_id
      CONSUMER_ACCOUNT_IDS = join(",", var.consumer_account_ids)
    }
  }

  tags = local.tags
}

# Lambda: Update Launch Template
resource "aws_lambda_function" "update_launch_template" {
  filename         = var.update_launch_template_package_path
  function_name    = "${local.resource_prefix}-update-lt"
  role             = aws_iam_role.lambda.arn
  handler          = "update_launch_template.handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256(var.update_launch_template_package_path)

  environment {
    variables = {
      SSM_PARAMETER_NAME  = aws_ssm_parameter.latest_golden_ami.name
      LAUNCH_TEMPLATE_IDS = join(",", var.launch_template_ids)
    }
  }

  tags = local.tags
}

# Lambda: Trigger Instance Refresh
resource "aws_lambda_function" "trigger_instance_refresh" {
  filename         = var.trigger_instance_refresh_package_path
  function_name    = "${local.resource_prefix}-instance-refresh"
  role             = aws_iam_role.lambda.arn
  handler          = "trigger_instance_refresh.handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256(var.trigger_instance_refresh_package_path)

  environment {
    variables = {
      AUTO_SCALING_GROUP_NAMES = join(",", var.auto_scaling_group_names)
    }
  }

  tags = local.tags
}

# Lambda: Check Refresh Status
resource "aws_lambda_function" "check_refresh_status" {
  filename         = var.check_refresh_status_package_path
  function_name    = "${local.resource_prefix}-check-refresh"
  role             = aws_iam_role.lambda.arn
  handler          = "check_refresh_status.handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256(var.check_refresh_status_package_path)

  tags = local.tags
}

# Lambda: Rollback AMI
resource "aws_lambda_function" "rollback_ami" {
  filename         = var.rollback_ami_package_path
  function_name    = "${local.resource_prefix}-rollback"
  role             = aws_iam_role.lambda.arn
  handler          = "rollback_ami.handler"
  runtime          = "python3.11"
  timeout          = 60
  source_code_hash = filebase64sha256(var.rollback_ami_package_path)

  environment {
    variables = {
      SSM_PARAMETER_NAME  = aws_ssm_parameter.latest_golden_ami.name
      LAUNCH_TEMPLATE_IDS = join(",", var.launch_template_ids)
    }
  }

  tags = local.tags
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions" {
  name = "${local.resource_prefix}-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "step_functions" {
  name = "${local.resource_prefix}-step-functions-policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "imagebuilder:StartImagePipelineExecution",
          "imagebuilder:GetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.share_ami.arn,
          aws_lambda_function.update_launch_template.arn,
          aws_lambda_function.trigger_instance_refresh.arn,
          aws_lambda_function.check_refresh_status.arn,
          aws_lambda_function.rollback_ami.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.ami_pipeline.arn
      }
    ]
  })
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "ami_pipeline" {
  name     = "${local.resource_prefix}-state-machine"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "AMI Update Pipeline Orchestration"
    StartAt = "StartImageBuilder"
    States = {
      StartImageBuilder = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:imagebuilder:startImagePipelineExecution"
        Parameters = {
          ImagePipelineArn = aws_imagebuilder_image_pipeline.main.arn
        }
        ResultPath = "$.imageBuilderResult"
        Next       = "WaitForImageBuilder"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
        }]
      }
      WaitForImageBuilder = {
        Type    = "Wait"
        Seconds = 300
        Next    = "CheckImageStatus"
      }
      CheckImageStatus = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:imagebuilder:getImage"
        Parameters = {
          ImageBuildVersionArn = ".$$.imageBuilderResult.ImageBuildVersionArn"
        }
        ResultPath = "$.imageStatus"
        Next       = "IsImageReady"
      }
      IsImageReady = {
        Type = "Choice"
        Choices = [{
          Variable     = "$.imageStatus.Image.State.Status"
          StringEquals = "AVAILABLE"
          Next         = "ShareAMI"
          }, {
          Variable     = "$.imageStatus.Image.State.Status"
          StringEquals = "FAILED"
          Next         = "NotifyFailure"
        }]
        Default = "WaitForImageBuilder"
      }
      ShareAMI = {
        Type       = "Task"
        Resource   = aws_lambda_function.share_ami.arn
        ResultPath = "$.shareResult"
        Next       = "UpdateLaunchTemplate"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
        }]
      }
      UpdateLaunchTemplate = {
        Type       = "Task"
        Resource   = aws_lambda_function.update_launch_template.arn
        ResultPath = "$.updateResult"
        Next       = "TriggerInstanceRefresh"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
        }]
      }
      TriggerInstanceRefresh = {
        Type       = "Task"
        Resource   = aws_lambda_function.trigger_instance_refresh.arn
        ResultPath = "$.refreshResult"
        Next       = "CheckIfMoreASGs"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "RollbackAMI"
        }]
      }
      CheckIfMoreASGs = {
        Type = "Choice"
        Choices = [{
          Variable     = "$.refreshResult.complete"
          BooleanEquals = true
          Next         = "NotifySuccess"
        }]
        Default = "WaitForRefresh"
      }
      WaitForRefresh = {
        Type    = "Wait"
        Seconds = 60
        Next    = "CheckRefreshStatus"
      }
      CheckRefreshStatus = {
        Type       = "Task"
        Resource   = aws_lambda_function.check_refresh_status.arn
        Parameters = {
          "refresh_id.$" = "$.refreshResult.refresh_id"
          "asg_name.$"   = "$.refreshResult.asg_name"
        }
        ResultPath = "$.statusResult"
        Next       = "EvaluateRefreshStatus"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "RollbackAMI"
        }]
      }
      EvaluateRefreshStatus = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.statusResult.is_successful"
            BooleanEquals = true
            Next         = "TriggerInstanceRefresh"
          },
          {
            Variable     = "$.statusResult.is_complete"
            BooleanEquals = true
            Next         = "RollbackAMI"
          }
        ]
        Default = "WaitForRefresh"
      }
      RollbackAMI = {
        Type       = "Task"
        Resource   = aws_lambda_function.rollback_ami.arn
        ResultPath = "$.rollbackResult"
        Next       = "NotifyRollback"
      }
      NotifyRollback = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.ami_pipeline.arn
          Subject  = "AMI Pipeline Rollback"
          Message  = "AMI update rolled back due to instance refresh failure"
        }
        Next = "NotifyFailure"
      }
      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.ami_pipeline.arn
          Subject  = "AMI Pipeline Success"
          Message  = "AMI update pipeline completed successfully"
        }
        End = true
      }
      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.ami_pipeline.arn
          Subject  = "AMI Pipeline Failure"
          Message  = "AMI update pipeline failed"
        }
        End = true
      }
    }
  })

  tags = local.tags
}

# EventBridge Rule for Scheduled Execution
resource "aws_cloudwatch_event_rule" "ami_pipeline_schedule" {
  name                = "${local.resource_prefix}-schedule"
  description         = "Trigger ${local.normalized_prefix} pipeline"
  schedule_expression = var.schedule_expression
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "ami_pipeline" {
  rule     = aws_cloudwatch_event_rule.ami_pipeline_schedule.name
  arn      = aws_sfn_state_machine.ami_pipeline.arn
  role_arn = aws_iam_role.eventbridge.arn
}

# IAM Role for EventBridge
resource "aws_iam_role" "eventbridge" {
  name = "${local.resource_prefix}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "eventbridge" {
  name = "${local.resource_prefix}-eventbridge-policy"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "states:StartExecution"
      ]
      Resource = aws_sfn_state_machine.ami_pipeline.arn
    }]
  })
}

data "aws_caller_identity" "current" {}
