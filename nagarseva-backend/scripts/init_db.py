import psycopg2
import sys

def drop_all_tables(cursor):
    """Drop all existing tables and types"""
    print("🗑️  Dropping existing tables and types...")
    
    # Drop tables in correct order (respecting foreign keys)
    tables = [
        'user_notifications',
        'notifications',
        'complaint_logs',
        'complaint_media',
        'complaints',
        'complaint_categories',
        'job_vacancies',
        'rti_info',
        'transports',
        'government_schemes',
        'contacts',
        'emergency_services',
        'users',
        'wards'
    ]
    
    for table in tables:
        try:
            cursor.execute(f"DROP TABLE IF EXISTS {table} CASCADE;")
            print(f"  ✓ Dropped table: {table}")
        except Exception as e:
            print(f"  ⚠ Warning dropping {table}: {e}")
    
    # Drop ENUM types
    enums = [
        'userrole',
        'contacttype',
        'notificationtype',
        'schemecategory',
        'transporttype'
    ]
    
    for enum in enums:
        try:
            cursor.execute(f"DROP TYPE IF EXISTS {enum} CASCADE;")
            print(f"  ✓ Dropped type: {enum}")
        except Exception as e:
            print(f"  ⚠ Warning dropping {enum}: {e}")
    
    print("✅ Cleanup completed\n")


def check_database_empty(cursor):
    """Check if database has any tables"""
    cursor.execute("""
        SELECT COUNT(*) 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE';
    """)
    count = cursor.fetchone()[0]
    return count == 0


def create_schema(cursor):
    """Create database schema"""
    
    print("📋 Creating database schema...")
    
    # Create ENUMs
    cursor.execute("""
        CREATE TYPE userrole AS ENUM ('CITIZEN', 'FIELD_OFFICER', 'WARD_ADMIN', 'SUPER_ADMIN');
    """)
    print("  ✓ Created ENUM: userrole")
    
    cursor.execute("""
        CREATE TYPE notificationtype AS ENUM ('NOTICE', 'ALERT', 'EVENT', 'CIRCULAR', 'UPDATE');
    """)
    print("  ✓ Created ENUM: notificationtype")
    
    cursor.execute("""
        CREATE TYPE schemecategory AS ENUM ('HEALTH', 'EDUCATION', 'WOMEN', 'SENIOR_CITIZEN', 'YOUTH', 'FARMER', 'HOUSING', 'EMPLOYMENT', 'OTHER');
    """)
    print("  ✓ Created ENUM: schemecategory")
    
    cursor.execute("""
        CREATE TYPE transporttype AS ENUM ('RAILWAY', 'BUS', 'METRO', 'AUTO');
    """)
    print("  ✓ Created ENUM: transporttype")
    
    # Wards Table (Base table - no dependencies)
    cursor.execute("""
        CREATE TABLE wards (
            id SERIAL PRIMARY KEY,
            ward_number INTEGER UNIQUE NOT NULL,
            name VARCHAR(100) NOT NULL,
            city VARCHAR(100) NOT NULL,
            state VARCHAR(100) NOT NULL,
            area VARCHAR(500),
            officer_name VARCHAR(255),
            officer_phone VARCHAR(20),
            officer_email VARCHAR(255),
            description VARCHAR(500),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: wards")
    
    # Users Table (depends on wards)
    cursor.execute("""
        CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            mobile VARCHAR(15) UNIQUE NOT NULL,
            email VARCHAR(100),
            password_hash VARCHAR(255),
            role userrole DEFAULT 'CITIZEN',
            ward_id INTEGER NOT NULL REFERENCES wards(id) ON DELETE RESTRICT,
            address VARCHAR(500) NOT NULL,
            profile_image VARCHAR(255),
            is_active BOOLEAN DEFAULT TRUE,
            is_verified BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: users")
    
    # Complaint Categories Table (no dependencies)
    cursor.execute("""
        CREATE TABLE complaint_categories (
            id SERIAL PRIMARY KEY,
            code VARCHAR(50) UNIQUE NOT NULL,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            icon VARCHAR(50),
            department VARCHAR(100),
            is_active VARCHAR(1) DEFAULT 'Y',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: complaint_categories")
    
    # Complaints Table (depends on users, wards, complaint_categories)
    cursor.execute("""
        CREATE TABLE complaints (
            id SERIAL PRIMARY KEY,
            complaint_number VARCHAR(20) UNIQUE NOT NULL,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            ward_id INTEGER NOT NULL REFERENCES wards(id) ON DELETE RESTRICT,
            category VARCHAR(50) NOT NULL REFERENCES complaint_categories(code) ON DELETE RESTRICT,
            title VARCHAR(200) NOT NULL,
            description TEXT NOT NULL,
            address VARCHAR(500) NOT NULL,
            latitude VARCHAR(20),
            longitude VARCHAR(20),
            status VARCHAR(20) DEFAULT 'PENDING',
            priority VARCHAR(20) DEFAULT 'MEDIUM',
            assigned_officer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
            resolution_remarks TEXT,
            feedback TEXT,
            rating INTEGER CHECK (rating >= 1 AND rating <= 5),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            resolved_at TIMESTAMP WITH TIME ZONE
        );
    """)
    print("  ✓ Created table: complaints")
    
    # Complaint Media Table (depends on complaints)
    cursor.execute("""
        CREATE TABLE complaint_media (
            id SERIAL PRIMARY KEY,
            complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
            file_path VARCHAR(500) NOT NULL,
            file_type VARCHAR(20) NOT NULL,
            file_name VARCHAR(255),
            file_size INTEGER,
            uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: complaint_media")
    
    # Complaint Logs Table (depends on complaints, users)
    cursor.execute("""
        CREATE TABLE complaint_logs (
            id SERIAL PRIMARY KEY,
            complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
            action_by_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
            action VARCHAR(50) NOT NULL,
            old_status VARCHAR(20),
            new_status VARCHAR(20),
            remarks TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: complaint_logs")
    
    # Emergency Services Table (depends on wards, users)
    cursor.execute("""
        CREATE TABLE emergency_services (
            id SERIAL PRIMARY KEY,
            name VARCHAR(200) NOT NULL,
            type VARCHAR(50) NOT NULL,
            phone VARCHAR(20),
            alternate_phone VARCHAR(20),
            email VARCHAR(100),
            address VARCHAR(500),
            google_maps_link VARCHAR(500),
            latitude FLOAT,
            longitude FLOAT,
            ward_id INTEGER REFERENCES wards(id) ON DELETE SET NULL,
            category VARCHAR(100),
            is_24x7 VARCHAR(1) DEFAULT 'N',
            is_citywide VARCHAR(1) DEFAULT 'N',
            is_active VARCHAR(1) DEFAULT 'Y',
            created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: emergency_services")
    
    # Contacts Table (no dependencies in your models, but keeping consistent)
    cursor.execute("""
        CREATE TABLE contacts (
            id SERIAL PRIMARY KEY,
            name VARCHAR(200) NOT NULL,
            designation VARCHAR(200) NOT NULL,
            department VARCHAR(200) NOT NULL,
            phone VARCHAR(20) NOT NULL,
            email VARCHAR(100),
            office_address VARCHAR(500),
            is_active VARCHAR(1) DEFAULT 'Y',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: contacts")
    
    # Government Schemes Table (no dependencies)
    cursor.execute("""
        CREATE TABLE government_schemes (
            id SERIAL PRIMARY KEY,
            name VARCHAR(300) NOT NULL,
            description TEXT NOT NULL,
            category VARCHAR(50) NOT NULL,
            eligibility TEXT,
            benefits TEXT,
            documents TEXT,
            application_url VARCHAR(500),
            deadline TIMESTAMP WITH TIME ZONE,
            is_active VARCHAR(1) DEFAULT 'Y',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: government_schemes")
    
    # Transports Table (no dependencies)
    cursor.execute("""
        CREATE TABLE transports (
            id SERIAL PRIMARY KEY,
            transport_type transporttype NOT NULL,
            name VARCHAR(200) NOT NULL,
            route_number VARCHAR(50),
            source VARCHAR(200) NOT NULL,
            destination VARCHAR(200) NOT NULL,
            via_stops TEXT,
            departure_time TIME,
            arrival_time TIME,
            frequency VARCHAR(100),
            fare VARCHAR(100),
            map_link VARCHAR(500),
            is_active VARCHAR(1) DEFAULT 'Y',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: transports")
    
    # Notifications Table (depends on wards)
    cursor.execute("""
        CREATE TABLE notifications (
            id SERIAL PRIMARY KEY,
            title VARCHAR(300) NOT NULL,
            message TEXT NOT NULL,
            notification_type notificationtype DEFAULT 'NOTICE',
            ward_id INTEGER REFERENCES wards(id) ON DELETE SET NULL,
            target_role userrole,
            is_active VARCHAR(1) DEFAULT 'Y',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP WITH TIME ZONE
        );
    """)
    print("  ✓ Created table: notifications")
    
    # User Notifications Table (depends on users, notifications)
    cursor.execute("""
        CREATE TABLE user_notifications (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            notification_id INTEGER NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
            is_read VARCHAR(1) DEFAULT 'N',
            read_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: user_notifications")
    
    # Job Vacancies Table (no dependencies)
    cursor.execute("""
        CREATE TABLE job_vacancies (
            id SERIAL PRIMARY KEY,
            title VARCHAR(300) NOT NULL,
            organization VARCHAR(200) NOT NULL,
            job_type VARCHAR(50),
            location VARCHAR(200),
            description TEXT,
            eligibility TEXT,
            salary_range VARCHAR(100),
            application_link VARCHAR(500),
            last_date TIMESTAMP WITH TIME ZONE,
            is_active VARCHAR(1) DEFAULT 'Y',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: job_vacancies")
    
    # RTI Info Table (no dependencies)
    cursor.execute("""
        CREATE TABLE rti_info (
            id SERIAL PRIMARY KEY,
            title VARCHAR(300) NOT NULL,
            description TEXT,
            content TEXT,
            form_link VARCHAR(500),
            portal_link VARCHAR(500),
            display_order INTEGER DEFAULT 0,
            is_active VARCHAR(1) DEFAULT 'Y',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    """)
    print("  ✓ Created table: rti_info")
    
    # Create Indexes for better performance
    print("\n📑 Creating indexes...")
    cursor.execute("CREATE INDEX idx_users_mobile ON users(mobile);")
    cursor.execute("CREATE INDEX idx_users_ward ON users(ward_id);")
    cursor.execute("CREATE INDEX idx_users_role ON users(role);")
    
    cursor.execute("CREATE INDEX idx_complaints_user ON complaints(user_id);")
    cursor.execute("CREATE INDEX idx_complaints_status ON complaints(status);")
    cursor.execute("CREATE INDEX idx_complaints_ward ON complaints(ward_id);")
    cursor.execute("CREATE INDEX idx_complaints_category ON complaints(category);")
    cursor.execute("CREATE INDEX idx_complaints_assigned_officer ON complaints(assigned_officer_id);")
    cursor.execute("CREATE INDEX idx_complaints_number ON complaints(complaint_number);")
    
    cursor.execute("CREATE INDEX idx_complaint_media_complaint ON complaint_media(complaint_id);")
    cursor.execute("CREATE INDEX idx_complaint_logs_complaint ON complaint_logs(complaint_id);")
    cursor.execute("CREATE INDEX idx_complaint_logs_action_by ON complaint_logs(action_by_id);")
    
    cursor.execute("CREATE INDEX idx_emergency_ward ON emergency_services(ward_id);")
    cursor.execute("CREATE INDEX idx_emergency_type ON emergency_services(type);")
    cursor.execute("CREATE INDEX idx_emergency_created_by ON emergency_services(created_by);")
    
    cursor.execute("CREATE INDEX idx_notifications_ward ON notifications(ward_id);")
    cursor.execute("CREATE INDEX idx_notifications_type ON notifications(notification_type);")
    cursor.execute("CREATE INDEX idx_notifications_target_role ON notifications(target_role);")
    
    cursor.execute("CREATE INDEX idx_user_notifications_user ON user_notifications(user_id);")
    cursor.execute("CREATE INDEX idx_user_notifications_notification ON user_notifications(notification_id);")
    cursor.execute("CREATE INDEX idx_user_notifications_read ON user_notifications(is_read);")
    
    cursor.execute("CREATE INDEX idx_complaint_categories_code ON complaint_categories(code);")
    cursor.execute("CREATE INDEX idx_wards_number ON wards(ward_number);")
    
    print("  ✓ Created all indexes")
    
    print("\n✅ Schema created successfully!\n")


def init_database(force_reset=False):
    """Initialize database with schema and seed data"""
    
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
        print("\nMake sure PostgreSQL is running and the database 'LOKseva' exists.")
        print("You can create it with: createdb -U postgres LOKseva")
        return
    
    conn.autocommit = True
    cursor = conn.cursor()
    
    try:
        # Check if database is empty
        is_empty = check_database_empty(cursor)
        
        if not is_empty and not force_reset:
            print("⚠️  Database already contains tables!")
            response = input("Do you want to DROP ALL TABLES and recreate? (yes/no): ")
            if response.lower() != 'yes':
                print("❌ Aborted. No changes made.")
                return
            force_reset = True
        
        # Drop existing tables if force_reset
        if force_reset:
            drop_all_tables(cursor)
        
        # Create schema
        create_schema(cursor)
        
        print("\n✅ Database initialized successfully!")
        print("\n📝 Next steps:")
        print("  1. Run seed data script to populate initial data")
        print("  2. Create admin user")
        print("  3. Start the application")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    force = '--force' in sys.argv or '-f' in sys.argv
    init_database(force_reset=force)