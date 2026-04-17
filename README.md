# JanSeva - Civic Services & Matrimonial Platform

A comprehensive civic services and matrimonial matching platform that connects citizens with municipal services, government schemes, emergency support, and matrimonial services. Built with FastAPI backend, Next.js admin panel, and Flutter mobile application.



## Project Overview

JanSeva (Jan = People, Seva = Service) is a comprehensive digital platform that provides:

1. **Civic Services** - File complaints, access emergency services, view government schemes, transport info, and important contacts
2. **Matrimonial Services** - Individuals and agencies can register to find matches
3. **Admin Management** - Centralized dashboard to manage users, roles, content, and all platform features

### Key Modules

- **Civic Services Module**: Emergency services, complaints, government schemes, transport, contacts
- **Matrimonial Module**: Individual registration, agency registration, match requests, messaging
- **Admin Panel**: User management, role assignment, content management, field users, ward admins
- **Field Users**: Ground-level staff managing specific areas and regions
- **Ward Admins**: Administrative staff overseeing specific wards/jurisdictions
- **Home Content Management**: Dynamic home screen content via admin CMS

## Features

### Civic Services
- Emergency Services Access
- Complaint Filing & Tracking
- Government Schemes & Benefits
- Transport Information
- Important Contacts Directory

### Matrimonial Services
- Individual User Registration
- Matrimonial Agency Registration
- Profile Browsing & Filtering
- Match Requests
- Direct Messaging
- Verified Profiles

### Admin Dashboard
- User Management (CRUD, role assignment)
- Field User Management (area assignment, status tracking)
- Ward Admin Management (jurisdiction assignment)
- Home Screen Content Management (CMS)
- Matrimonial Users & Agencies Management
- Match Management
- Role & Permission Management
- Statistics & Analytics

### Mobile App
- Native Flutter Application
- Dynamic Home Screen Content
- User Authentication
- Matrimonial Module Integration
- Complaint Management
- Service Browsing

## Tech Stack

### Backend
- **Framework**: FastAPI (Python)
- **Database**: PostgreSQL
- **ORM**: SQLAlchemy
- **Authentication**: JWT (JSON Web Tokens)
- **API Style**: RESTful
- **Server**: Uvicorn

### Frontend (Admin Panel)
- **Framework**: Next.js 14
- **UI Library**: Tailwind CSS, NextUI
- **State Management**: Zustand
- **HTTP Client**: Axios
- **Authentication**: JWT with Cookies

### Mobile App
- **Framework**: Flutter
- **State Management**: Provider
- **HTTP Client**: Dio
- **Local Storage**: Shared Preferences
- **Database**: SQLite (local)

## Project Structure

```
janseva/
├── nagarseva-backend/          # FastAPI Backend
│   ├── app/
│   │   ├── main.py            # Application entry point
│   │   ├── models/            # Database models
│   │   │   ├── user.py
│   │   │   ├── matrimonial.py
│   │   │   ├── admin.py
│   │   │   ├── home_content.py
│   │   │   ├── ward.py
│   │   │   ├── complaint.py
│   │   │   └── ...
│   │   ├── api/               # API route handlers
│   │   │   ├── auth.py
│   │   │   ├── matrimonial.py
│   │   │   ├── admin_extended.py
│   │   │   ├── complaints.py
│   │   │   └── ...
│   │   ├── core/              # Core utilities
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── security.py
│   │   │   └── constants.py
│   │   └── schemas/           # Pydantic models
│   ├── requirements.txt
│   └── .env.example
│
├── admin-panel/               # Next.js Admin Dashboard
│   ├── app/
│   │   ├── layout.tsx         # Root layout
│   │   ├── page.tsx           # Home page
│   │   ├── login/page.tsx     # Login page
│   │   └── dashboard/
│   │       ├── page.tsx       # Dashboard home
│   │       ├── users/         # User management
│   │       ├── roles/         # Role management
│   │       ├── field-users/   # Field user management
│   │       ├── ward-admins/   # Ward admin management
│   │       ├── home-content/  # Content management
│   │       ├── civic-data/    # Civic data management
│   │       └── matrimonial/   # Matrimonial management
│   ├── components/            # React components
│   │   ├── Sidebar.tsx
│   │   ├── DataTable.tsx
│   │   └── Forms/
│   ├── lib/
│   │   ├── api-client.ts      # API client
│   │   ├── auth-store.ts      # Auth state management
│   │   └── validators.ts
│   ├── next.config.js
│   └── package.json
│
├── android_app/               # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── core/
│   │   │   ├── constants/     # App constants
│   │   │   ├── services/      # API service, home content service
│   │   │   └── providers/     # State management
│   │   │       ├── auth_provider.dart
│   │   │       ├── matrimonial_provider.dart
│   │   │       └── ...
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── home/
│   │       │   ├── matrimonial/
│   │       │   ├── services/
│   │       │   ├── complaints/
│   │       │   └── ...
│   │       └── widgets/
│   ├── pubspec.yaml
│   └── README.md
│
└── README.md                  # This file
```

## Getting Started

### Prerequisites

- Python 3.9+
- Node.js 18+
- Flutter SDK
- PostgreSQL 12+
- Git

### Backend Setup

1. **Clone and navigate to backend**
   ```bash
   cd nagarseva-backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and settings
   ```

5. **Initialize database**
   ```bash
   python -m app.core.database
   # This creates all tables
   ```


6. **Run development server**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

Backend will be available at: `http://localhost:8000`
API docs: `http://localhost:8000/docs`

### Admin Panel Setup

1. **Navigate to admin-panel**
   ```bash
   cd admin-panel
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cat > .env.local << EOF
   NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
   EOF
   ```

4. **Run development server**
   ```bash
   npm run dev
   ```

Admin panel will be available at: `http://localhost:3000`

### Mobile App Setup

1. **Navigate to mobile app**
   ```bash
   cd android_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API URL**
   - Edit `lib/core/constants/app_constants.dart`
   - Set `API_BASE_URL` to your backend URL

4. **Run on emulator or device**
   ```bash
   flutter run
   ```

## API Documentation

### Authentication Endpoints

```
POST   /api/v1/auth/login              - User login
POST   /api/v1/auth/register           - User registration
POST   /api/v1/auth/admin-login        - Admin login
POST   /api/v1/auth/logout             - Logout
POST   /api/v1/auth/refresh            - Refresh token
```

### Matrimonial Endpoints

```
POST   /api/v1/matrimonial/users/register        - Register as individual
POST   /api/v1/matrimonial/agencies/register     - Register as agency
GET    /api/v1/matrimonial/users                 - List matrimonial users
GET    /api/v1/matrimonial/agencies              - List matrimonial agencies
GET    /api/v1/matrimonial/users/{id}            - Get user profile
GET    /api/v1/matrimonial/agencies/{id}         - Get agency profile
POST   /api/v1/matrimonial/matches               - Request match
POST   /api/v1/matrimonial/messages              - Send message
GET    /api/v1/matrimonial/messages/{user_id}   - Get message thread
```

### Admin Endpoints

```
GET    /api/v1/admin/users                       - List all users
POST   /api/v1/admin/users                       - Create user
PUT    /api/v1/admin/users/{id}                  - Update user
DELETE /api/v1/admin/users/{id}                  - Delete user
POST   /api/v1/admin/users/{id}/assign-role      - Assign role to user

GET    /api/v1/admin/field-users                 - List field users
POST   /api/v1/admin/field-users                 - Create field user
PUT    /api/v1/admin/field-users/{id}            - Update field user
DELETE /api/v1/admin/field-users/{id}            - Delete field user

GET    /api/v1/admin/ward-admins                 - List ward admins
POST   /api/v1/admin/ward-admins                 - Create ward admin
PUT    /api/v1/admin/ward-admins/{id}            - Update ward admin
DELETE /api/v1/admin/ward-admins/{id}            - Delete ward admin

GET    /api/v1/admin/home-content                - List home content
POST   /api/v1/admin/home-content                - Create home content
PUT    /api/v1/admin/home-content/{id}           - Update home content
DELETE /api/v1/admin/home-content/{id}           - Delete home content

GET    /api/v1/admin/roles                       - List roles
POST   /api/v1/admin/roles                       - Create role
PUT    /api/v1/admin/roles/{id}                  - Update role
DELETE /api/v1/admin/roles/{id}                  - Delete role

GET    /api/v1/admin/dashboard-stats             - Dashboard statistics
```

### Public Endpoints

```
GET    /api/v1/public/home-content               - Get home content for app
GET    /api/v1/public/civic-services             - Get civic services
```

## Database Schema

### Core Tables

**users** - System users
- id (UUID, PK)
- email (VARCHAR, unique)
- password_hash (VARCHAR)
- name (VARCHAR)
- phone (VARCHAR)
- role (VARCHAR, FK -> roles)
- is_active (BOOLEAN)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

**roles** - User roles
- id (UUID, PK)
- role_name (VARCHAR, unique)
- permissions (JSON)
- description (TEXT)
- created_at (TIMESTAMP)

### Matrimonial Tables

**matrimonial_users** - Individual matrimonial profiles
- id (UUID, PK)
- user_id (UUID, FK -> users)
- gender (VARCHAR)
- age (INTEGER)
- marital_status (VARCHAR)
- religion (VARCHAR)
- caste (VARCHAR)
- location (VARCHAR)
- description (TEXT)
- profile_images (JSON)
- status (VARCHAR)
- created_at (TIMESTAMP)

**matrimonial_agencies** - Matrimonial service agencies
- id (UUID, PK)
- user_id (UUID, FK -> users)
- business_name (VARCHAR)
- registration_number (VARCHAR)
- contact_person (VARCHAR)
- email (VARCHAR)
- phone (VARCHAR)
- address (TEXT)
- verification_status (VARCHAR)
- created_at (TIMESTAMP)

**matches** - Match requests between users/agencies
- id (UUID, PK)
- initiator_id (UUID)
- receiver_id (UUID)
- status (VARCHAR)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

**matrimonial_messages** - Messages between users/agencies
- id (UUID, PK)
- sender_id (UUID)
- receiver_id (UUID)
- message (TEXT)
- is_read (BOOLEAN)
- created_at (TIMESTAMP)

### Admin Tables

**field_users** - Ground-level field staff
- id (UUID, PK)
- user_id (UUID, FK -> users)
- location (VARCHAR)
- area (VARCHAR)
- assigned_region (VARCHAR)
- contact_info (VARCHAR)
- status (VARCHAR)
- created_at (TIMESTAMP)

**ward_admins** - Ward administrators
- id (UUID, PK)
- admin_id (UUID, FK -> users)
- ward_id (VARCHAR)
- ward_name (VARCHAR)
- jurisdiction_area (TEXT)
- status (VARCHAR)
- created_at (TIMESTAMP)

**home_content** - Dynamic home screen content
- id (UUID, PK)
- content_type (VARCHAR)
- title (VARCHAR)
- description (TEXT)
- image_url (VARCHAR)
- order (INTEGER)
- is_active (BOOLEAN)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

## Configuration

### Environment Variables

**Backend (.env)**
```
DATABASE_URL=postgresql://user:password@localhost/janseva
SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24
API_BASE_URL=http://localhost:8000
UPLOAD_DIR=./uploads
DEBUG=True
```

**Admin Panel (.env.local)**
```
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

**Mobile App (lib/core/constants/app_constants.dart)**
```dart
const String API_BASE_URL = 'http://your-api-url.com/api/v1';
```

## Deployment

### Backend Deployment (Using Vercel or Heroku)

1. Set up PostgreSQL database
2. Configure environment variables
3. Deploy with Gunicorn:
   ```bash
   gunicorn app.main:app --workers 4
   ```

### Admin Panel Deployment (Vercel)

1. Connect GitHub repository to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy using Vercel CLI or GitHub integration

### Mobile App Deployment

1. **Android APK**
   ```bash
   flutter build apk --release
   ```

2. **iOS IPA**
   ```bash
   flutter build ios --release
   ```

## Security Best Practices

- Use HTTPS in production
- Set strong JWT secrets
- Implement rate limiting
- Validate all inputs
- Use SQL parameterized queries (SQLAlchemy handles this)
- Secure password hashing with bcrypt
- CORS configuration for allowed origins
- Regular security audits

## API Error Responses

All errors follow consistent format:

```json
{
  "detail": "Error message",
  "status_code": 400,
  "timestamp": "2024-04-17T10:30:00Z"
}
```

### Common Status Codes
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error

## Development Workflow

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Create pull request
5. Code review
6. Merge to main
7. Deploy to production

## Testing

### Backend
```bash
pytest tests/
```

### Admin Panel
```bash
npm run test
```

### Mobile App
```bash
flutter test
```

## Performance Optimization

- Database indexing on frequently queried fields
- API response caching
- Image optimization and lazy loading
- Bundle size optimization
- Code splitting in Next.js

## Monitoring & Logging

- Application logs in `/logs` directory
- Database query logging
- API request/response logging
- Error tracking with timestamps
- User activity audit trails

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For issues, feature requests, or questions, please open an issue on the GitHub repository or contact the development team.

## Changelog

### Version 1.0.0 (Current)
- Initial release with civic services and matrimonial modules
- Admin dashboard for content and user management
- Field users and ward admins management
- Dynamic home screen content management
- Complete Flutter mobile application

---

**Last Updated**: April 17, 2026
**Maintainers**: Development Team
