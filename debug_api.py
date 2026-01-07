import requests

def debug_connection():
    base_url = "http://127.0.0.1:5000/api"
    print(f"Testing connectivity to {base_url}")
    
    try:
        # 1. Test unprotected route (if any) or just the prefix
        resp = requests.get(f"{base_url}/auth/admin-login", timeout=5)
        print(f"Admin Login endpoint check (OPTIONS/GET expected 405 or CORS): {resp.status_code}")
    except Exception as e:
        print(f"Failed to reach server: {e}")
        return

    passwords = ["admin", "password", "admin123", "123456"]
    token = None
    
    for pwd in passwords:
        print(f"\nAttempting Login with '{pwd}'...")
        login_resp = requests.post(
            f"{base_url}/auth/admin-login",
            json={"username": "admin", "password": pwd}, 
            timeout=5
        )
        if login_resp.status_code == 200:
            token = login_resp.json().get('access_token')
            print(f"Login Successful with '{pwd}'!")
            break
        else:
            print(f"Failed ({login_resp.status_code}): {login_resp.text}")
    
    if token:
        
        print("\nTesting Customer Detail with Token...")
        cust_resp = requests.get(
            f"{base_url}/customer/5",
            headers={"Authorization": f"Bearer {token}"},
            timeout=5
        )
        print(f"Customer Detail Status: {cust_resp.status_code}")
        if cust_resp.status_code == 200:
            print("Success! Data received.")
        else:
            print(f"Error Response: {cust_resp.text}")
    else:
        print(f"Login Failed ({login_resp.status_code}): {login_resp.text}")

if __name__ == "__main__":
    debug_connection()
