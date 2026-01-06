# Test script to verify customer creation works
import requests
import json

# Get a token first (login as admin)
login_data = {
    "username": "admin",
    "password": "admin123"
}

print("1. Logging in as admin...")
login_response = requests.post('http://127.0.0.1:5000/api/auth/login', json=login_data)
print(f"Login status: {login_response.status_code}")

if login_response.status_code == 200:
    token = login_response.json().get('access_token')
    print(f"✓ Got token: {token[:20]}...")
    
    # Try to create a customer
    customer_data = {
        "name": "Test Customer",
        "mobile_number": "9999999999",
        "address": "123 Test St",
        "area": "Test Area",
        "id_proof_number": "TEST123"
    }
    
    print("\n2. Creating customer...")
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    create_response = requests.post('http://127.0.0.1:5000/api/customer/create', 
                                   json=customer_data, headers=headers)
    
    print(f"Create status: {create_response.status_code}")
    print(f"Response: {create_response.json()}")
else:
    print(f"✗ Login failed: {login_response.json()}")
