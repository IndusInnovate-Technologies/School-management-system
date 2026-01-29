#!/usr/bin/env python3
import sqlite3
import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
DB_PATH = os.path.join(BASE_DIR, 'db.sqlite3')

def query_user(email):
    if not os.path.exists(DB_PATH):
        print(f"DB not found at: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cur.execute('SELECT id, username, email, password, is_active, role_id FROM users WHERE email = ?', (email,))
    row = cur.fetchone()
    if not row:
        print(f'No user found with email: {email}')
        conn.close()
        return

    print('User record:')
    print(f"  id: {row['id']}")
    print(f"  username: {row['username']}")
    print(f"  email: {row['email']}")
    print(f"  password_hash: {row['password']}")
    print(f"  is_active: {row['is_active']}")
    print(f"  role_id: {row['role_id']}")

    role_id = row['role_id']
    if role_id:
        cur.execute('SELECT id, name, description FROM roles WHERE id = ?', (role_id,))
        r = cur.fetchone()
        if r:
            print('Role record:')
            print(f"  id: {r['id']}")
            print(f"  name: {r['name']}")
            print(f"  description: {r['description']}")
        else:
            print(f'No role record with id {role_id}')
    else:
        print('User has no role assigned (role_id is NULL)')

    conn.close()

if __name__ == '__main__':
    emails = [
        'admin@school.com',
        'management@school.com',
        'teacher@school.com',
        'parent@school.com'
    ]
    for e in emails:
        print('\n---')
        query_user(e)
