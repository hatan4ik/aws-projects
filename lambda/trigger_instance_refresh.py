import os
import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

autoscaling = boto3.client('autoscaling')

def handler(event, context):
    try:
        asg_names = os.environ.get('AUTO_SCALING_GROUP_NAMES', '').split(',')
        asg_names = [asg.strip() for asg in asg_names if asg.strip()]
        
        if not asg_names:
            logger.info("No Auto Scaling Groups configured")
            return {'all_asgs': [], 'current_index': -1, 'complete': True}
        
        current_index = event.get('current_index', -1)
        next_index = current_index + 1
        
        if next_index >= len(asg_names):
            logger.info("All ASGs processed")
            return {'all_asgs': asg_names, 'current_index': next_index, 'complete': True}
        
        asg_name = asg_names[next_index]
        response = autoscaling.start_instance_refresh(
            AutoScalingGroupName=asg_name,
            Strategy='Rolling',
            Preferences={
                'MinHealthyPercentage': 90,
                'InstanceWarmup': 300
            }
        )
        
        logger.info(f"Started instance refresh for {asg_name}: {response['InstanceRefreshId']}")
        
        return {
            'all_asgs': asg_names,
            'current_index': next_index,
            'asg_name': asg_name,
            'refresh_id': response['InstanceRefreshId'],
            'complete': False
        }
    except ClientError as e:
        logger.error(f"AWS API error: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise
