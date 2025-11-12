import os
import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

autoscaling = boto3.client('autoscaling')

def handler(event, context):
    try:
        refresh_id = event['refresh_id']
        asg_name = event['asg_name']
        
        response = autoscaling.describe_instance_refreshes(
            AutoScalingGroupName=asg_name,
            InstanceRefreshIds=[refresh_id]
        )
        
        if not response['InstanceRefreshes']:
            raise ValueError(f"Instance refresh {refresh_id} not found")
        
        refresh = response['InstanceRefreshes'][0]
        status = refresh['Status']
        
        logger.info(f"ASG {asg_name} refresh {refresh_id} status: {status}")
        
        return {
            'asg_name': asg_name,
            'refresh_id': refresh_id,
            'status': status,
            'percentage_complete': refresh.get('PercentageComplete', 0),
            'is_complete': status in ['Successful', 'Failed', 'Cancelled'],
            'is_successful': status == 'Successful'
        }
    except ClientError as e:
        logger.error(f"AWS API error: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise
