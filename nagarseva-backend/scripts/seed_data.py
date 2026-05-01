import psycopg2
import sys
import os

def seed_database():
    """Seed database from SQL file"""
    
    # Check if seed file exists
    seed_file = 'scripts/002_seed_data.sql'
    if not os.path.exists(seed_file):
        print(f"❌ Error: Seed file not found: {seed_file}")
        print("\nPlease create the file with your seed data.")
        return False
    
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="LOKseva",
            user="postgres",
            password="Rootdmin@1234"
        )
    except Exception as e:
        print(f"❌ Error connecting to database: {e}")
        return False
    
    conn.autocommit = False  # Use transaction for seed data
    cursor = conn.cursor()
    
    try:
        print("🌱 Seeding database from SQL file...")
        print(f"📄 Reading: {seed_file}\n")
        
        # Read the entire SQL file
        with open(seed_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Split by INSERT statements to track progress
        statements = []
        current_statement = []
        
        for line in sql_content.split('\n'):
            line = line.strip()
            
            # Skip comments and empty lines
            if not line or line.startswith('--'):
                continue
            
            current_statement.append(line)
            
            # Check if statement is complete (ends with semicolon)
            if line.endswith(';'):
                full_statement = ' '.join(current_statement)
                if full_statement.strip():
                    statements.append(full_statement)
                current_statement = []
        
        # Execute statements one by one
        total = len(statements)
        success_count = 0
        error_count = 0
        
        for i, statement in enumerate(statements, 1):
            try:
                cursor.execute(statement)
                
                # Try to extract table name for better logging
                if 'INSERT INTO' in statement.upper():
                    table_name = statement.upper().split('INSERT INTO')[1].split('(')[0].strip()
                    # Get row count
                    if cursor.rowcount > 0:
                        print(f"  ✓ [{i}/{total}] Inserted {cursor.rowcount} row(s) into: {table_name}")
                    success_count += 1
                else:
                    print(f"  ✓ [{i}/{total}] Executed statement")
                    success_count += 1
                    
            except Exception as e:
                error_count += 1
                # Show first 100 chars of statement
                stmt_preview = statement[:100] + "..." if len(statement) > 100 else statement
                print(f"  ✗ [{i}/{total}] Error: {e}")
                print(f"     Statement: {stmt_preview}")
                
                # Ask whether to continue
                if error_count < 5:  # Auto-continue for first few errors
                    continue
                else:
                    response = input("\n⚠️  Multiple errors detected. Continue? (yes/no): ")
                    if response.lower() != 'yes':
                        raise Exception("Aborted by user")
        
        # Commit all changes
        conn.commit()
        
        print(f"\n✅ Seeding completed!")
        print(f"   Success: {success_count}/{total}")
        print(f"   Errors: {error_count}/{total}")
        
        # Show table statistics
        print("\n📊 Database Statistics:")
        
        tables_to_count = [
            'wards',
            'users',
            'complaint_categories',
            'emergency_services',
            'government_schemes',
            'contacts',
            'transports',
            'notifications'
        ]
        
        for table in tables_to_count:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                if count > 0:
                    print(f"  • {table}: {count} records")
            except Exception as e:
                print(f"  • {table}: Error - {e}")
        
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"\n❌ Error during seeding: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        cursor.close()
        conn.close()


def verify_schema_exists(cursor):
    """Check if required tables exist"""
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('wards', 'users', 'complaints')
    """)
    tables = [row[0] for row in cursor.fetchall()]
    return len(tables) == 3


def check_before_seed():
    """Check if schema exists before seeding"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="LOKseva",
            user="postgres",
            password="Rootdmin@1234"
        )
        cursor = conn.cursor()
        
        if not verify_schema_exists(cursor):
            print("⚠️  Warning: Required tables not found!")
            print("Please run 'python scripts/init_db.py' first to create the schema.")
            cursor.close()
            conn.close()
            return False
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error checking schema: {e}")
        return False


if __name__ == "__main__":
    print("=" * 60)
    print("  LOKseva Database Seeding")
    print("=" * 60)
    print()
    
    # Check if schema exists
    if not check_before_seed():
        sys.exit(1)
    
    # Ask for confirmation
    if '--force' not in sys.argv and '-f' not in sys.argv:
        print("⚠️  This will insert seed data into the database.")
        print("    Make sure the database schema is properly initialized.")
        response = input("\nContinue? (yes/no): ")
        if response.lower() != 'yes':
            print("❌ Aborted.")
            sys.exit(0)
    
    # Run seeding
    success = seed_database()
    
    if success:
        print("\n✅ Database seeding completed successfully!")
        print("\n📝 Next steps:")
        print("  1. Create admin user (if not created)")
        print("  2. Start the application")
        print("  3. Test the API endpoints")
        sys.exit(0)
    else:
        print("\n❌ Database seeding failed!")
        sys.exit(1)