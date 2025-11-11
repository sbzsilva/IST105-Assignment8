#!/bin/bash

# Update system
sudo yum update -y

# Create MongoDB repo file
echo "[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.4.repo

# Install MongoDB
sudo yum install -y mongodb-org

# Configure MongoDB to accept remote connections
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

# Start MongoDB service
sudo systemctl start mongod
sudo systemctl enable mongod

# Create the assignment8 database and results collection
mongo --eval "use assignment8; db.createCollection('results')"

echo "MongoDB installation completed!"
echo "MongoDB is now listening on 0.0.0.0:27017"