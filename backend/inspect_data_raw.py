
from django.db import connection, connections
from main_login.models import User
from management_admin.models import Student

def run():
    print("--- RAW DATA INSPECTION ---")
    
    # 1. Django View
    try:
        u = User.objects.get(username='k')
        s = Student.objects.filter(user=u).first()
        if s:
            print(f"Django sees Student Email: '{s.email}'")
            print(f"Hex: {s.email.encode('utf-8').hex()}")
        else:
            print("Django sees NO student for 'k'")
            return
    except Exception as e:
        print(f"Django Error: {e}")
        return

    # 2. SQL View
    email_to_find = s.email
    print(f"\nSearching for '{email_to_find}' in DB via SQL...")
    
    with connection.cursor() as cursor:
        # Fetch ALL emails to check for near-matches
        cursor.execute("SELECT email FROM students")
        rows = cursor.fetchall()
        
        found = False
        print(f"Total students in DB: {len(rows)}")
        for r in rows:
            db_email = r[0]
            if db_email == email_to_find:
                found = True
                print(f"MATCH FOUND EXACTLY: '{db_email}'")
                break
            
            # Check for loose match
            if db_email.strip().lower() == email_to_find.strip().lower():
                print(f"NEAR MATCH found: '{db_email}'")
                print(f"Django Hex: {email_to_find.encode('utf-8').hex()}")
                print(f"DB     Hex: {db_email.encode('utf-8').hex()}")
        
        if not found:
            print("NO EXACT MATCH FOUND IN DB!")

run()
