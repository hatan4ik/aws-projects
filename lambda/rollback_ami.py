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
        previous_ami_param = f"{ssm_param}-previous"
        
        previous_ami = ssm.get_parameter(Name=previous_ami_param)['Parameter']['Value']
        logger.info(f"Rolling back to previous AMI: {previous_ami}")
        
        launch_template_ids = os.environ.get('LAUNCH_TEMPLATE_IDS', '').split(',')
        launch_template_ids = [lt.strip() for lt in launch_template_ids if lt.strip()]
        
        if not launch_template_ids:
            logger.warning("No launch templates to rollback")
            return {'rolled_back': False, 'previous_ami': previous_ami}
        
        rolled_back = []
        for lt_id in launch_template_ids:
            response = ec2.create_launch_template_version(
                LaunchTemplateId=lt_id,
                SourceVersion='$Latest',
                LaunchTemplateData={
                    'ImageId': previous_ami
                }
            )
            
            ec2.modify_launch_template(
                LaunchTemplateId=lt_id,
                DefaultVersion=str(response['LaunchTemplateVersion']['VersionNumber'])
            )
            
            rolled_back.append({
                'template_id': lt_id,
                'version': response['LaunchTemplateVersion']['VersionNumber']
            })
            logger.info(f"Rolled back launch template {lt_id} to AMI {previous_ami}")
        
        ssm.put_parameter(
            Name=ssm_param,
            Value=previous_ami,
            Type='String',
            Overwrite=True
        )
        
        return {
            'rolled_back': True,
            'previous_ami': previous_ami,
            'updated_templates': rolled_back
        }
    except ClientError as e:
        logger.error(f"AWS API error: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise
