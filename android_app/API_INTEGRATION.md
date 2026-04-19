# Nagarseva API Integration Guide

This document provides detailed information about API integration, expected responses, and troubleshooting.

## API Configuration

### Base URL Setup
File: `lib/core/constants/app_constants.dart`

```dart
// For local development (Android Emulator)
const String API_BASE_URL = 'http://10.0.2.2:8000/api';

// For local development (Physical device on same network)
const String API_BASE_URL = 'http://192.168.1.100:8000/api';  // Replace with your IP

// For production
const String API_BASE_URL = 'https://api.nagarseva.gov.in/api';
```

## Authentication Endpoints

### 1. Register User
**Endpoint:** `POST /auth/register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "password": "securepassword123",
  "role": "CITIZEN"
}
```

**Success Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "role": "CITIZEN",
    "ward_id": 5,
    "ward_name": "Ward 5",
    "is_active": true,
    "created_at": "2026-01-22T10:30:00"
  }
}
```

**Error Response (400):**
```json
{
  "message": "Email already exists",
  "status": 400
}
```

### 2. Login User
**Endpoint:** `POST /auth/login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Success Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "role": "CITIZEN",
    "ward_id": 5,
    "ward_name": "Ward 5",
    "is_active": true,
    "created_at": "2026-01-22T10:30:00"
  }
}
```

**Error Response (401):**
```json
{
  "message": "Invalid credentials",
  "status": 401
}
```

### 3. Get User Profile
**Endpoint:** `GET /auth/profile`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "role": "CITIZEN",
  "ward_id": 5,
  "ward_name": "Ward 5",
  "is_active": true,
  "created_at": "2026-01-22T10:30:00"
}
```

### 4. Update Profile
**Endpoint:** `PUT /auth/profile`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body:**
```json
{
  "name": "John Doe Updated",
  "phone": "9876543211"
}
```

**Success Response (200):**
```json
{
  "id": 1,
  "name": "John Doe Updated",
  "email": "john@example.com",
  "phone": "9876543211",
  "role": "CITIZEN",
  "ward_id": 5,
  "ward_name": "Ward 5",
  "is_active": true,
  "created_at": "2026-01-22T10:30:00"
}
```

### 5. Logout
**Endpoint:** `POST /auth/logout`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

## Complaint Endpoints

### 1. Get Complaint Categories
**Endpoint:** `GET /complaints/categories`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "categories": [
    "Pothole",
    "Water Supply",
    "Street Light",
    "Garbage",
    "Road Maintenance",
    "Drainage",
    "Parks",
    "Other"
  ]
}
```

### 2. Create Complaint
**Endpoint:** `POST /complaints/create`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Request Body:**
```json
{
  "title": "Pothole on Main Street",
  "description": "There is a large pothole on main street near the market that needs urgent repair",
  "category": "Pothole",
  "address": "Main Street, Ward 5",
  "latitude": 19.0176,
  "longitude": 73.0193,
  "image_url": null
}
```

**Success Response (201):**
```json
{
  "id": 101,
  "citizen_id": 1,
  "citizen_name": "John Doe",
  "ward_id": 5,
  "ward_name": "Ward 5",
  "title": "Pothole on Main Street",
  "description": "There is a large pothole on main street near the market that needs urgent repair",
  "category": "Pothole",
  "status": "OPEN",
  "image_url": null,
  "latitude": 19.0176,
  "longitude": 73.0193,
  "address": "Main Street, Ward 5",
  "created_at": "2026-01-22T10:30:00",
  "updated_at": null,
  "resolved_notes": null
}
```

### 3. Get My Complaints
**Endpoint:** `GET /complaints/my?skip=0&limit=20`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 101,
      "citizen_id": 1,
      "citizen_name": "John Doe",
      "ward_id": 5,
      "ward_name": "Ward 5",
      "title": "Pothole on Main Street",
      "description": "There is a large pothole on main street near the market that needs urgent repair",
      "category": "Pothole",
      "status": "IN_PROGRESS",
      "image_url": null,
      "latitude": 19.0176,
      "longitude": 73.0193,
      "address": "Main Street, Ward 5",
      "created_at": "2026-01-22T10:30:00",
      "updated_at": "2026-01-22T14:30:00",
      "resolved_notes": null
    }
  ],
  "total": 1
}
```

### 4. Get Complaint Details
**Endpoint:** `GET /complaints/{complaint_id}`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "id": 101,
  "citizen_id": 1,
  "citizen_name": "John Doe",
  "ward_id": 5,
  "ward_name": "Ward 5",
  "title": "Pothole on Main Street",
  "description": "There is a large pothole on main street near the market that needs urgent repair",
  "category": "Pothole",
  "status": "RESOLVED",
  "image_url": null,
  "latitude": 19.0176,
  "longitude": 73.0193,
  "address": "Main Street, Ward 5",
  "created_at": "2026-01-22T10:30:00",
  "updated_at": "2026-01-22T15:30:00",
  "resolved_notes": "Pothole has been filled and surface has been leveled."
}
```

## Services Endpoints

### 1. Get Emergency Services
**Endpoint:** `GET /services/emergency?ward_id=5`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Emergency Medical",
      "description": "24/7 ambulance and medical emergency services",
      "phone": "102",
      "email": "emergency@med.gov.in",
      "website": null,
      "category": "Medical",
      "ward_id": 5,
      "ward_name": "Ward 5",
      "latitude": 19.0176,
      "longitude": 73.0193,
      "address": "City Hospital, Ward 5",
      "is_active": true
    },
    {
      "id": 2,
      "name": "Fire Department",
      "description": "Fire emergency services",
      "phone": "101",
      "email": "fire@dept.gov.in",
      "website": null,
      "category": "Fire",
      "ward_id": 5,
      "ward_name": "Ward 5",
      "latitude": 19.0170,
      "longitude": 73.0190,
      "address": "Fire Station, Ward 5",
      "is_active": true
    }
  ]
}
```

### 2. Get Schemes
**Endpoint:** `GET /services/schemes`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Senior Citizen Pension",
      "description": "Monthly pension for senior citizens above 60 years",
      "benefits_description": "₹1000 per month for eligible senior citizens",
      "eligibility": "Age above 60 years and annual income less than Rs. 24000",
      "application_process": "Apply at ward office with Aadhaar and proof of age",
      "contact_info": "Ward Office: 020-1234-5678",
      "last_updated": "2026-01-15T10:00:00"
    }
  ]
}
```

### 3. Get Transport Information
**Endpoint:** `GET /services/transport`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "route_name": "Route 101 - CBD to Vashi",
      "from_location": "CBD Belapur",
      "to_location": "Vashi",
      "schedule": "Every 15 minutes from 6 AM to 10 PM",
      "fare": "₹10-15",
      "contact_info": "NMMT: 1800-233-0011",
      "last_updated": "2026-01-15T10:00:00"
    }
  ]
}
```

### 4. Get Important Contacts
**Endpoint:** `GET /services/contacts`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Ward Office - Ward 5",
      "department": "Municipal Corporation",
      "phone": "020-1234-5678",
      "email": "ward5@nmmc.gov.in",
      "address": "Ward Office Complex, Ward 5",
      "website": "www.nmmc.gov.in"
    }
  ]
}
```

## Common Error Responses

### 401 Unauthorized
```json
{
  "message": "Invalid or expired token",
  "status": 401
}
```

### 403 Forbidden
```json
{
  "message": "You don't have permission to perform this action",
  "status": 403
}
```

### 404 Not Found
```json
{
  "message": "Complaint not found",
  "status": 404
}
```

### 422 Validation Error
```json
{
  "message": "Validation failed",
  "status": 422,
  "errors": {
    "email": "Invalid email format"
  }
}
```

### 500 Server Error
```json
{
  "message": "Internal server error",
  "status": 500
}
```

## Token Management

### How Tokens Work
1. User logs in and receives `access_token` and `refresh_token`
2. `access_token` is used for all API requests (valid for ~30 minutes)
3. `refresh_token` is used to get a new `access_token` when expired
4. Both tokens are stored in `SharedPreferences` locally
5. Tokens are automatically cleared on logout

### Token Format
Tokens are JWT (JSON Web Tokens) with format: `header.payload.signature`

Example:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwibmFtZSI6IkpvaG4gRG9lIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

### Token in Headers
All requests must include:
```
Authorization: Bearer <access_token>
```

## Testing with cURL

### Test Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "citizen@example.com",
    "password": "password123"
  }'
```

### Test with Token
```bash
curl -X GET http://localhost:8000/api/auth/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Test Create Complaint
```bash
curl -X POST http://localhost:8000/api/complaints/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "title": "Pothole",
    "description": "Deep pothole on main street",
    "category": "Pothole",
    "address": "Main Street",
    "latitude": 19.0176,
    "longitude": 73.0193
  }'
```

## Debugging API Issues

### 1. Check Network
```bash
# Test if API server is running
curl http://localhost:8000/api/health

# Test connectivity
ping 8.8.8.8
```

### 2. View Flutter Logs
```bash
flutter logs
```

### 3. Enable HTTP Debugging
In `lib/core/services/api_service.dart`, add:
```dart
_dio.interceptors.add(LoggingInterceptor());
```

### 4. Check Backend Logs
Monitor your FastAPI backend logs for errors:
```bash
# If running with uvicorn
# Look for status codes and error messages
```

### 5. Test Endpoints Directly
Use Postman or Insomnia to test API endpoints before running app.

## Expected Response Times

- Login/Register: 200-500ms
- Get User Profile: 100-200ms
- Get Complaints: 300-800ms
- Create Complaint: 500-1000ms
- Get Services: 200-500ms

## Rate Limiting

The backend should implement rate limiting:
- Login attempts: 5 per minute per IP
- API requests: 1000 per hour per token
- File upload: 10 per hour per user

## CORS Configuration

Your FastAPI backend should have CORS configured:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or specific domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Security Best Practices

1. Always use HTTPS in production
2. Never log sensitive data (tokens, passwords)
3. Implement token refresh logic
4. Set appropriate token expiration times
5. Use secure random tokens
6. Validate all inputs on backend
7. Implement rate limiting
8. Use CORS properly
9. Implement request signing for sensitive operations
10. Regular security audits

## Support & Troubleshooting

If API integration fails:

1. Verify `API_BASE_URL` is correct
2. Ensure backend server is running
3. Check backend logs for errors
4. Verify request body format matches examples
5. Check authorization headers are correct
6. Ensure user role has necessary permissions
7. Test with cURL first before app testing

---

**Last Updated:** January 2026
**API Version:** 1.0.0
