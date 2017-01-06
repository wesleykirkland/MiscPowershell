# This script is designed to label all volumes when ever it is ran, it will label the volume as the instance name and current mount point on the instance
# It will rename existing tagged vol

import boto3


# Function that will convert a EC2 object list to a dict format
def make_tag_dict(ec2_object):
    # Given an tagable ec2_object, return dictionary of existing tags
    # From https://github.com/boto/boto3/issues/264#issuecomment-148735429
    tag_dict = {}
    if ec2_object['Tags'] is None: return tag_dict
    for tag in ec2_object['Tags']:
        tag_dict[tag['Key']] = tag['Value']
    return tag_dict

def lambda_handler(event, context):
    print('Running from Lambda')
    arn = context.invoked_function_arn
    aws_account_number = arn.split(':')[4]
    region = arn.split(':')[3]

    # Build a ec2 object
    ec2 = boto3.client('ec2', region_name=region)

    ec2instances = ec2.describe_instances()  # Find all the instances in the account

    # instance = ec2instances['Reservations'][1]
    for instance in ec2instances['Reservations']:
        # Set loop variables
        instance_tags = make_tag_dict(instance['Instances'][0])
        instance_name = instance_tags.get('Name')

        # Find volume related stuff
        instance_volumes = instance['Instances'][0]['BlockDeviceMappings']  # Find all attaches volumes to the instance

        # Loop through the instance volumes to find the IDs, and see if we should snapshot the volume
        for volume in instance_volumes:
            volume_tag = instance_name + '(' + volume['DeviceName'] + ')'  # Create the volume name tag
            # Tag the Volume
            ec2.create_tags(
                Resources=[
                    volume['Ebs']['VolumeId']
                ],
                Tags=[
                    {
                        'Key': 'Name',
                        'Value': volume_tag
                    }
                ]
            )
