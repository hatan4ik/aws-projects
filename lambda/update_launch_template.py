import os
import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')

def handler(event, context):
    try:
        ssm_param = os.environ['SSM_PARAMETER_NAME']
        
        ami_id = ssm.get_parameter(Name=ssm_param)['Parameter']['Value']
        logger.info(f"Retrieved AMI ID: {ami_id}")
        
        launch_template_ids = os.environ.get('LAUNCH_TEMPLATE_IDS', '').split(',')
        launch_template_ids = [lt.strip() for lt in launch_template_ids if lt.strip()]
        
        if not launch_template_ids:
            logger.info("No launch templates configured")
            return {'ami_id': ami_id, 'updated_templates': []}
    
        updated = []
        for lt_id in launch_template_ids:
            response = ec2.create_launch_template_version(
                LaunchTemplateId=lt_id,
                SourceVersion='$Latest',
                LaunchTemplateData={
                    'ImageId': ami_id
                }
            )
            
            ec2.modify_launch_template(
                LaunchTemplateId=lt_id,
                DefaultVersion=str(response['LaunchTemplateVersion']['VersionNumber'])
            )
            
            updated.append({
                'template_id': lt_id,
                'version': response['LaunchTemplateVersion']['VersionNumber']
            })
            logger.info(f"Updated launch template {lt_id} to version {response['LaunchTemplateVersion']['VersionNumber']}")
        
        return {
            'ami_id': ami_id,
            'updated_templates': updated
        }
    except ClientError as e:
        logger.error(f"AWS API error: {e}")
        raise
    except KeyError as e:
        logger.error(f"Missing required data: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise
