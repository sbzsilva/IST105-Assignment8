from django.shortcuts import render
from .forms import NetworkConfigForm
import pymongo
from datetime import datetime, timedelta
import re

# MongoDB connection - REMOTE SERVER
client = pymongo.MongoClient("mongodb://3.239.80.34:27017/")
db = client["assignment8"]
leases_collection = db["results"]

# Dictionary to maintain current leases
current_leases = {}

def validate_mac_address(mac):
    """Validate MAC address format"""
    pattern = r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'
    return re.match(pattern, mac) is not None

def generate_ipv4():
    """Generate a dynamic IPv4 address from 192.168.1.0/24 pool"""
    import random
    return f"192.168.1.{random.randint(1, 254)}"

def generate_ipv6_from_mac(mac):
    """Generate IPv6 address using EUI-64 from MAC address"""
    # Remove colons and convert to lowercase
    mac_clean = mac.replace(":", "").lower()
    
    # Split MAC into two parts
    first_part = mac_clean[:6]
    second_part = mac_clean[6:]
    
    # Insert FFFE in the middle
    middle = "fffe"
    
    # Toggle the 7th bit (universal/local bit)
    first_byte = first_part[:2]
    first_byte_int = int(first_byte, 16)
    # Toggle the 7th bit (0x02)
    first_byte_int ^= 0x02
    first_byte_modified = format(first_byte_int, '02x')
    
    # Construct the interface identifier
    interface_id = first_byte_modified + first_part[2:6] + middle + second_part
    
    # Return the full IPv6 address
    return f"2001:db8::{interface_id}"

def check_mac_sum_even_odd(mac):
    """Check if the sum of MAC address bytes is even or odd using bitwise operations"""
    # Remove colons and convert to bytes
    mac_clean = mac.replace(":", "")
    bytes_list = [int(mac_clean[i:i+2], 16) for i in range(0, len(mac_clean), 2)]
    
    # Calculate sum
    total = sum(bytes_list)
    
    # Check if even or odd using bitwise AND
    is_even = (total & 1) == 0
    
    return "even" if is_even else "odd"

def index(request):
    if request.method == 'POST':
        form = NetworkConfigForm(request.POST)
        if form.is_valid():
            mac_address = form.cleaned_data['mac_address']
            dhcp_version = form.cleaned_data['dhcp_version']
            
            # Validate MAC address
            if not validate_mac_address(mac_address):
                return render(request, 'network/index.html', {
                    'form': form,
                    'error': 'Invalid MAC address format. Please use format like 00:1A:2B:3C:4D:5E'
                })
            
            # Check if we already have a lease for this MAC
            current_time = datetime.now()
            lease_time = 3600  # 1 hour in seconds
            
            # Check if MAC exists in current leases and is still valid
            if mac_address in current_leases:
                lease_info = current_leases[mac_address]
                lease_start = lease_info['timestamp']
                # Check if the existing lease matches the requested DHCP version
                existing_ip = lease_info['assigned_ip']
                existing_is_ipv4 = existing_ip.startswith('192.168.1.')
                requested_is_ipv4 = (dhcp_version == 'DHCPv4')
                
                if (current_time - lease_start).total_seconds() < lease_time and existing_is_ipv4 == requested_is_ipv4:
                    # Lease is still valid and matches the requested version, return the same IP
                    assigned_ip = lease_info['assigned_ip']
                else:
                    # Lease expired or version mismatch, generate a new IP
                    if dhcp_version == 'DHCPv4':
                        assigned_ip = generate_ipv4()
                    else:  # DHCPv6
                        assigned_ip = generate_ipv6_from_mac(mac_address)
                    
                    # Update the lease
                    current_leases[mac_address] = {
                        'assigned_ip': assigned_ip,
                        'timestamp': current_time
                    }
            else:
                # New lease
                if dhcp_version == 'DHCPv4':
                    assigned_ip = generate_ipv4()
                else:  # DHCPv6
                    assigned_ip = generate_ipv6_from_mac(mac_address)
                
                # Add to current leases
                current_leases[mac_address] = {
                    'assigned_ip': assigned_ip,
                    'timestamp': current_time
                }
            
            # Check MAC sum even/odd
            mac_sum_parity = check_mac_sum_even_odd(mac_address)
            
            # Prepare data for MongoDB
            lease_data = {
                "mac_address": mac_address,
                "dhcp_version": dhcp_version,
                "assigned_ip": assigned_ip,
                "lease_time": f"{lease_time} seconds",
                "timestamp": current_time.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "mac_sum_parity": mac_sum_parity
            }
            
            # Save to MongoDB
            leases_collection.insert_one(lease_data)
            
            # Display result
            return render(request, 'network/results.html', {
                'mac_address': mac_address,
                'dhcp_version': dhcp_version,
                'assigned_ip': assigned_ip,
                'lease_time': f"{lease_time} seconds",
                'mac_sum_parity': mac_sum_parity
            })
    else:
        form = NetworkConfigForm()
    
    return render(request, 'network/index.html', {'form': form})

def view_leases(request):
    """View all DHCP leases from MongoDB"""
    leases = list(leases_collection.find().sort("timestamp", -1))  # Sort by timestamp, newest first
    
    return render(request, 'network/leases.html', {'leases': leases})