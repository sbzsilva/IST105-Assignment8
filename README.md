# IST105 - Assignment 8

## Description
This is a Django web application that processes numerical inputs, performs various calculations and checks, and stores the data in MongoDB.

## Features
- Accepts five numerical inputs
- Validates inputs (numeric, non-negative)
- Calculates average and checks if it's greater than 50
- Counts positive values and determines if the count is even or odd using bitwise operations
- Creates a new list with values greater than 10 and sorts it
- Saves input and output to MongoDB
- Displays results in a formatted HTML page

## Setup Instructions

### Option 1: Automated Setup (using setup.sh)
1. Create two EC2 instances (WebServer-EC2 and MongoDB-EC2)
2. Install Django on WebServer-EC2
3. Install MongoDB on MongoDB-EC2
4. Clone this repository to WebServer-EC2
5. Set environment variables for MongoDB connection
6. Run migrations and start the Django server

### Option 2: Manual Setup (using individual scripts)
1. Run `setup_ec2.sh` to create EC2 instances and security groups
2. Run `install_mongodb.sh` on the MongoDB instance
3. Run `install_webserver.sh` on the WebServer instance
4. Update MongoDB connection settings in environment variables
5. Run migrations and start the Django server

## Usage
Access the application at http://<WebServer-EC2-Public-IP>:8000