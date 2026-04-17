"""
Script to generate correct password hash and update database
Run this to fix password authentication issues
"""

import bcrypt
import psycopg2

def generate_correct_hash(password: str) -> str:
    """Generate bcrypt hash for password"""
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(password_bytes, salt)
    return hashed.decode('utf-8')

def verify_hash(password: str, hash_str: str) -> bool:
    """Verify password against hash"""
    try:
        return bcrypt.checkpw(password.encode('utf-8'), hash_str.encode('utf-8'))
    except Exception as e:
        print(f"Error: {e}")
        return False

def update_database_passwords():
    """Update all user passwords in database"""
    
    # Database connection
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="LOKseva",
            user="postgres",
            password="Rootdmin@1234"
        )
        conn.autocommit = True
        cursor = conn.cursor()
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return
    
    print("=" * 70)
    print("Password Hash Fix Script")
    print("=" * 70)
    
    # Generate new hash for "admin123"
    password = "admin123"
    new_hash = generate_correct_hash(password)
    
    print(f"\n✓ Generated new hash for password: {password}")
    print(f"  Hash: {new_hash}")
    
    # Verify the new hash works
    is_valid = verify_hash(password, new_hash)
    print(f"  Verification: {'✓ PASS' if is_valid else '✗ FAIL'}")
    
    if not is_valid:
        print("\n❌ Hash generation failed! Aborting.")
        return
    
    print("\n" + "-" * 70)
    print("Updating all users with correct password hash...")
    print("-" * 70)
    
    try:
        # Update all users
        cursor.execute("""
            UPDATE users 
            SET password_hash = %s
            WHERE password_hash IS NOT NULL;
        """, (new_hash,))
        
        # Get count of updated users
        cursor.execute("SELECT COUNT(*) FROM users WHERE password_hash IS NOT NULL;")
        count = cursor.fetchone()[0]
        
        print(f"\n✓ Updated {count} users with new password hash")
        
        # Show updated users
        cursor.execute("""
            SELECT id, name, mobile, role 
            FROM users 
            WHERE password_hash IS NOT NULL
            ORDER BY id;
        """)
        
        print("\n" + "=" * 70)
        print("Updated Users:")
        print("=" * 70)
        print(f"{'ID':<5} {'Name':<25} {'Mobile':<15} {'Role':<15}")
        print("-" * 70)
        
        for row in cursor.fetchall():
            user_id, name, mobile, role = row
            print(f"{user_id:<5} {name:<25} {mobile:<15} {role:<15}")
        
        print("\n" + "=" * 70)
        print("✓ All passwords updated successfully!")
        print("=" * 70)
        print(f"\nDefault password for all users: {password}")
        print("\nTest login credentials:")
        print("  Super Admin - Mobile: 9999999999, Password: admin123")
        print("  Citizen - Mobile: 9123456780, Password: admin123")
        print("  Citizen - Mobile: 9123456781, Password: admin123")
        print("  Citizen - Mobile: 9123456782, Password: admin123")
        
    except Exception as e:
        print(f"\n❌ Error updating database: {e}")
        
    finally:
        cursor.close()
        conn.close()

def test_specific_user(mobile: str):
    """Test login for a specific user"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="LOKseva",
            user="postgres",
            password="Rootdmin@1234"
        )
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, name, mobile, password_hash 
            FROM users 
            WHERE mobile = %s;
        """, (mobile,))
        
        user = cursor.fetchone()
        
        if not user:
            print(f"❌ User with mobile {mobile} not found")
            return
        
        user_id, name, user_mobile, stored_hash = user
        
        print("\n" + "=" * 70)
        print(f"Testing User: {name} ({user_mobile})")
        print("=" * 70)
        
        print(f"\nUser ID: {user_id}")
        print(f"Stored Hash: {stored_hash[:60]}...")
        
        # Test with correct password
        test_password = "admin123"
        is_valid = verify_hash(test_password, stored_hash)
        
        print(f"\nPassword: {test_password}")
        print(f"Verification: {'✓ PASS - Login should work!' if is_valid else '✗ FAIL - Login will fail'}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    import sys
    
    print("\n")
    
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        # Test specific user
        mobile = sys.argv[2] if len(sys.argv) > 2 else "9123456782"
        test_specific_user(mobile)
    else:
        # Update all passwords
        update_database_passwords()
    
    print()