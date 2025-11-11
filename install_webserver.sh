#!/bin/bash

# Update system
sudo yum update -y

# Install Python and pip
sudo yum install python3 python3-pip git -y

# Install Django and pymongo
pip3 install django pymongo

# Configure Git
git config --global user.name "Sergio Silva"
git config --global user.email "sergio.silva@example.com"

# Clone the repository
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/sbzsilva/IST105-Assignment8.git
cd ~/projects/assignment8

# Set environment variables for MongoDB connection (these need to be updated with actual IPs)
echo "export MONGODB_HOST='localhost'" >> ~/.bashrc
echo "export MONGODB_PORT=27017" >> ~/.bashrc
echo "export MONGODB_DB='assignment8'" >> ~/.bashrc
echo "export MONGODB_COLLECTION='results'" >> ~/.bashrc

echo "Web server installation completed!"
echo "Next steps:"
echo "1. Update the MONGODB_HOST environment variable in ~/.bashrc with the actual MongoDB private IP"
echo "2. Source the environment: source ~/.bashrc"
echo "3. Run migrations: python3 manage.py migrate"
echo "4. Start the server: python3 manage.py runserver 0.0.0.0:8000"