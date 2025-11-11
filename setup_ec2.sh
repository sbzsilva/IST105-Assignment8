#!/bin/bash

# Configuration variables
KEY_NAME="IST105-Assignment8"
INSTANCE_TYPE="t3.medium"
TAG_NAME="Assignment8"
SECURITY_GROUP_WEB="webserver-sg"
SECURITY_GROUP_MONGO="mongodb-sg"

# Fetch the latest Amazon Linux 2023 AMI ID dynamically
echo "Fetching latest Amazon Linux 2023 AMI ID..."
AMI_ID=$(aws ssm get-parameters \
    --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
    --query 'Parameters[0].Value' \
    --output text)

# Check if AMI ID was obtained successfully
if [ $? -ne 0 ] || [ -z "$AMI_ID" ]; then
    echo "Error: Failed to retrieve AMI ID. Please check your AWS credentials and region configuration."
    exit 1
fi

echo "Using AMI ID: $AMI_ID"

# Create security groups
echo "Creating security groups..."
aws ec2 create-security-group --group-name $SECURITY_GROUP_WEB --description "Security group for web server"
aws ec2 create-security-group --group-name $SECURITY_GROUP_MONGO --description "Security group for MongoDB"

# Get security group IDs
WEB_SG_ID=$(aws ec2 describe-security-groups --group-names $SECURITY_GROUP_WEB --query "SecurityGroups[0].GroupId" --output text)
MONGO_SG_ID=$(aws ec2 describe-security-groups --group-names $SECURITY_GROUP_MONGO --query "SecurityGroups[0].GroupId" --output text)

# Configure security group rules
echo "Configuring security group rules..."
# WebServer security group
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 8000 --cidr 0.0.0.0/0

# MongoDB security group
aws ec2 authorize-security-group-ingress --group-id $MONGO_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $MONGO_SG_ID --protocol tcp --port 27017 --source-group $WEB_SG_ID

# Launch instances
echo "Launching EC2 instances..."
WEB_INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $WEB_SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME-WebServer}]" --query "Instances[0].InstanceId" --output text)
MONGO_INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $MONGO_SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME-MongoDB}]" --query "Instances[0].InstanceId" --output text)

# Wait for instances to be running
echo "Waiting for instances to be running..."
aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID $MONGO_INSTANCE_ID

# Get instance IPs
WEB_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $WEB_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
WEB_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $WEB_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
MONGO_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $MONGO_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
MONGO_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $MONGO_INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)

echo "Instance IPs:"
echo "WebServer Public IP: $WEB_PUBLIC_IP"
echo "WebServer Private IP: $WEB_PRIVATE_IP"
echo "MongoDB Public IP: $MONGO_PUBLIC_IP"
echo "MongoDB Private IP: $MONGO_PRIVATE_IP"

echo "EC2 setup complete!"
echo "Next steps:"
echo "1. Run install_mongodb.sh on MongoDB instance: $MONGO_PUBLIC_IP"
echo "2. Run install_webserver.sh on WebServer instance: $WEB_PUBLIC_IP"