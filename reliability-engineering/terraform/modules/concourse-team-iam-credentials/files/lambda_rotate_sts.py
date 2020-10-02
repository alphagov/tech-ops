import boto3
import json
import os

print('Loading function')

ssm = boto3.client('ssm')
sts = boto3.client('sts')


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    deployment = os.environ.get('DEPLOYMENT')
    key_id = os.environ.get('KEY_ID')
    role_arn = event['role_arn']
    team_name = event['team_name']
    parameter_prefix = "/{}/concourse/pipelines/{}".format(deployment,team_name)
    try:
        sts_response = sts.assume_role(
            RoleArn=role_arn,
            RoleSessionName='ConcourseTeam-' + team_name,
        )
        ssm.put_parameter(
            Name=parameter_prefix + '/readonly_access_key_id',
            Value=sts_response['Credentials']['AccessKeyId'],
            Type='SecureString',
            KeyId=key_id,
            Overwrite=True,
        )
        ssm.put_parameter(
            Name=parameter_prefix + '/readonly_secret_access_key',
            Value=sts_response['Credentials']['SecretAccessKey'],
            Type='SecureString',
            KeyId=key_id,
            Overwrite=True,
        )
        ssm.put_parameter(
            Name=parameter_prefix + '/readonly_session_token',
            Value=sts_response['Credentials']['SessionToken'],
            Type='SecureString',
            KeyId=key_id,
            Overwrite=True,
        )
    except Exception as e:
        print(e)
        raise e

