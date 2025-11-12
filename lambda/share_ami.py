import json
import os
import logging
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
kms = boto3.client('kms')
ssm = boto3.client('ssm')

def handler(event, context):
    try:
        ami_id = event['imageStatus']['Image']['OutputResources']['Amis'][0]['Image']
        kms_key_id = os.environ['KMS_KEY_ID']
        
        consumer_accounts = os.environ.get('CONSUMER_ACCOUNT_IDS', '').split(',')
        consumer_accounts = [acc.strip() for acc in consumer_accounts if acc.strip()]
        
        if not consumer_accounts:
            logger.info("No consumer accounts configured, skipping AMI sharing")
            return {'ami_id': ami_id, 'shared': False}
    
        # Share AMI
        ec2.modify_image_attribute(
            ImageId=ami_id,
            LaunchPermission={
                'Add': [{'UserId': acc_id} for acc_id in consumer_accounts]
            }
        )
        logger.info(f"Shared AMI {ami_id} with accounts: {consumer_accounts}")
        
        # Update KMS key policy
        key_policy = kms.get_key_policy(KeyId=kms_key_id, PolicyName='default')
        policy = json.loads(key_policy['Policy'])
        
        grant_statement = {
            "Sid": "AllowConsumerAccounts",
            "Effect": "Allow",
            "Principal": {
                "AWS": [f"arn:aws:iam::{acc_id}:root" for acc_id in consumer_accounts]
            },
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:CreateGrant"
            ],
            "Resource": "*"
        }
        
        policy['Statement'] = [s for s in policy['Statement'] if s.get('Sid') != 'AllowConsumerAccounts']
        policy['Statement'].append(grant_statement)
        
        kms.put_key_policy(
            KeyId=kms_key_id,
            PolicyName='default',
            Policy=json.dumps(policy)
        )
        logger.info("Updated KMS key policy")
        
        # Store previous AMI for rollback
        ssm_param = '/amis/latest-golden-ami'
        try:
            previous_ami = ssm.get_parameter(Name=ssm_param)['Parameter']['Value']
            if previous_ami != 'ami-placeholder':
                ssm.put_parameter(
                    Name=f"{ssm_param}-previous",
                    Value=previous_ami,
                    Type='String',
                    Overwrite=True
                )
                logger.info(f"Stored previous AMI {previous_ami} for rollback")
        except ssm.exceptions.ParameterNotFound:
            logger.info("No previous AMI to store")
        
        # Update SSM Parameter
        ssm.put_parameter(
            Name=ssm_param,
            Value=ami_id,
            Type='String',
            Overwrite=True
        )
        logger.info(f"Updated SSM parameter with AMI {ami_id}")
        
        return {
            'ami_id': ami_id,
            'shared': True,
            'consumer_accounts': consumer_accounts
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
