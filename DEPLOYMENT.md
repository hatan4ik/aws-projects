# Deployment Guide

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Bash shell
- zip utility

## Setup

1. Copy the example variables file:
```bash
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
```

2. Edit `infrastructure/terraform.tfvars` with your values:
   - `source_ami_id`: Base AMI to patch
   - `notification_email`: Email for pipeline notifications
   - `consumer_account_ids`: AWS accounts to share AMI with (optional)
   - `launch_template_ids`: Launch Templates to update (optional)
   - `auto_scaling_group_names`: ASGs for instance refresh (optional)

## Deploy

Run the deployment script:
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

Or manually:
```bash
# Build Lambda packages
./scripts/build_lambdas.sh

# Deploy infrastructure
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Manual Trigger

Trigger the pipeline manually:
```bash
aws stepfunctions start-execution \
  --state-machine-arn $(terraform output -raw step_functions_arn)
```

## Monitoring

- Check Step Functions console for execution status
- View CloudWatch Logs for Lambda function logs
- Monitor SNS notifications via email

## Cleanup

```bash
cd infrastructure
terraform destroy
```
