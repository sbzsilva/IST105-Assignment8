#!/bin/bash

# Configuration variables
KEY_NAME="IST105-Assignment8"  # Using the provided key pair name
AMI_ID="ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
INSTANCE_TYPE="t2.micro"
TAG_NAME="Assignment8"
SECURITY_GROUP_WEB="webserver-sg"
SECURITY_GROUP_MONGO="mongodb-sg"

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

# Install MongoDB on MongoDB instance
echo "Installing MongoDB on MongoDB instance..."
ssh -i $KEY_NAME.pem ec2-user@$MONGO_PUBLIC_IP << EOF
    sudo yum update -y
    echo "[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.4.repo
    sudo yum install -y mongodb-org
    sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
    sudo systemctl start mongod
    sudo systemctl enable mongod
    mongo --eval "use assignment8; db.createCollection('results')"
EOF

# Install Django and set up project on WebServer instance
echo "Installing Django and setting up project on WebServer instance..."
ssh -i $KEY_NAME.pem ec2-user@$WEB_PUBLIC_IP << EOF
    sudo yum update -y
    sudo yum install python3 python3-pip git -y
    pip3 install django pymongo
    
    # Configure Git
    git config --global user.name "Sergio Silva"
    git config --global user.email "sergio.silva@example.com"
    
    # Clone the repository
    git clone https://github.com/sbzsilva/IST105-Assignment8.git ~/projects/assignment8
    cd ~/projects/assignment8
EOF

# Configure Django application
echo "Configuring Django application..."
ssh -i $KEY_NAME.pem ec2-user@$WEB_PUBLIC_IP << EOF
    cd ~/projects/assignment8
    
    # Update settings.py with the provided SECRET_KEY
    sed -i "s/django-insecure-your-secret-key-here/wqqz(a6^9#c2j2v!^0u2btdm\$!^18_6pj*dmge5tnm85hx8gxc/" assignment8/settings.py
    
    # Set environment variables for MongoDB connection
    echo "export MONGODB_HOST='$MONGO_PRIVATE_IP'" >> ~/.bashrc
    echo "export MONGODB_PORT=27017" >> ~/.bashrc
    echo "export MONGODB_DB='assignment8'" >> ~/.bashrc
    echo "export MONGODB_COLLECTION='results'" >> ~/.bashrc
    source ~/.bashrc
EOF

# Start Django application
echo "Starting Django application..."
ssh -i $KEY_NAME.pem ec2-user@$WEB_PUBLIC_IP << EOF
    cd ~/projects/assignment8
    python3 manage.py migrate
    nohup python3 manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &
    echo "Django application started. Access at http://$WEB_PUBLIC_IP:8000"
EOF

echo "Deployment complete!"
echo "Access the application at: http://$WEB_PUBLIC_IP:8000"
echo "MongoDB is running at: $MONGO_PUBLIC_IP:27017"
echo "Repository: https://github.com/sbzsilva/IST105-Assignment8.git"