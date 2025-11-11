# IST105 Assignment 8: Network Automation Web Application

## Description
This is a Django web application that simulates DHCPv4 and DHCPv6 IP assignment. It accepts MAC addresses and DHCP versions as input, generates appropriate IP addresses, and stores the lease information in a MongoDB database.

## Features
- Accepts MAC address and DHCP version (DHCPv4 or DHCPv6) through a web form
- Validates MAC address format
- Generates IPv4 addresses from 192.168.1.0/24 pool for DHCPv4
- Generates IPv6 addresses using EUI-64 format for DHCPv6
- Uses bitwise operations to manipulate MAC address bytes
- Stores all lease information in MongoDB
- Provides a page to view all DHCP leases

## Setup Instructions
1. Create two EC2 instances: one for the Django web server (Amazon Linux 2) and one for MongoDB (Ubuntu)
2. Configure security groups appropriately
3. Install required software on both instances
4. Clone this repository on the web server instance
5. Update the MongoDB connection string in views.py with the private IP of the MongoDB instance
6. Run the Django application

## Branches
- main: Final stable code
- development: Testing integration
- feature1: For initial bitwise/IP assignment logic

## How to Run
1. Navigate to the project directory
2. Run migrations: 
   ```
   python3 manage.py makemigrations
   python3 manage.py migrate
   ```
3. Start the development server:
   ```
   python3 manage.py runserver 0.0.0.0:8000
   ```
4. Access the application at http://<WebServer-EC2-Public-IP>:8000