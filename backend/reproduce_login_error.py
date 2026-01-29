import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

def test_teacher_login():
    print("Testing Teacher Login...")
    
    # 1. Role Login
    login_url = f"{BASE_URL}/auth/role-login/"
    payload = {
        "email": "venu@teacher.com",
        "password": "password123", # Assuming this is the password
        "role": "teacher"
    }
    
    try:
        response = requests.post(login_url, json=payload)
        print(f"Role Login Status: {response.status_code}")
        print(f"Role Login Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('tokens', {}).get('access')
            
            if token:
                # 2. Teacher Profile
                print("\nFetching Teacher Profile...")
                profile_url = f"{BASE_URL}/teacher/profile/"
                headers = {"Authorization": f"Bearer {token}"}
                
                prof_resp = requests.get(profile_url, headers=headers)
                print(f"Profile Status: {prof_resp.status_code}")
                print(f"Profile Response: {prof_resp.text}")
                
                # 3. Dashboard Stats
                print("\nFetching Dashboard Stats...")
                stats_url = f"{BASE_URL}/teacher/dashboard-stats/"
                stats_resp = requests.get(stats_url, headers=headers)
                print(f"Stats Status: {stats_resp.status_code}")
                print(f"Stats Response: {stats_resp.text}")
            else:
                print("No token received")
        else:
            print("Login failed")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_teacher_login()
