# NagarSeva API Endpoints - Complete Guide

## Authentication

All endpoints (except `/auth/register`, `/auth/login`) require:
- **Header**: `Authorization: Bearer {access_token}`

---

## Emergency Services Endpoints

### 1. Get Emergency Services (Citizen/Ward Admin)
```
GET /emergency
```

**Query Parameters**:
- `type` (optional): Hospital, Police, Fire, Ambulance, Municipal
- `category` (optional): Custom category string
- `ward_id` (optional): For super admin filtering only

**Auto-Filtering**:
- **CITIZEN**: Services for their ward + citywide services
- **FIELD_OFFICER**: Services for their ward + citywide services
- **WARD_ADMIN**: Services for their ward + citywide services
- **SUPER_ADMIN**: All services (or filter by ward_id if provided)

**Response**:
```json
[
  {
    "id": 1,
    "name": "City General Hospital",
    "type": "Hospital",
    "category": "Government",
    "phone": "9876543210",
    "alternate_phone": "9876543211",
    "email": "hospital@city.gov",
    "address": "123 Main Street",
    "google_maps_link": "https://maps.google.com/...",
    "ward_id": 1,
    "is_citywide": false,
    "is_active": "Y",
    "created_at": "2024-01-01T10:00:00",
    "updated_at": "2024-01-15T12:30:00"
  }
]
```

---

## Admin Emergency Services Endpoints

### 2. List Emergency Services (Admin Only)
```
GET /admin/emergency
```

**Required Role**: WARD_ADMIN or SUPER_ADMIN

**Query Parameters**:
- `category` (optional): Filter by category
- `ward_id` (optional): Filter by ward (SUPER_ADMIN only)

**Auto-Filtering**:
- **WARD_ADMIN**: Only their ward services
- **SUPER_ADMIN**: All services or filtered by ward_id

**Response**: Same as GET /emergency

---

### 3. Create Emergency Service
```
POST /admin/emergency
```

**Required Role**: WARD_ADMIN or SUPER_ADMIN

**Request Body** (form-data or JSON):
```json
{
  "name": "City Hospital",
  "type": "Hospital",
  "ward_id": 1,
  "phone": "9876543210",
  "alternate_phone": "9876543211",
  "email": "hospital@city.gov",
  "address": "123 Main Street",
  "google_maps_link": "https://maps.google.com/...",
  "category": "Government",
  "is_citywide": false
}
```

**Validation**:
- `name`: Required, 2-200 characters
- `type`: Required, one of (Hospital, Police, Fire, Ambulance, Municipal)
- `ward_id`: Auto-assigned for WARD_ADMIN, required for SUPER_ADMIN
- `phone`: Optional
- `email`: Optional
- All other fields: Optional

**Auto-Assignments**:
- WARD_ADMIN: ward_id is set to their ward automatically
- created_by: Set to current user ID

**Response**: Same as GET /emergency (single object)

---

### 4. Update Emergency Service
```
PUT /admin/emergency/{id}
```

**Required Role**: WARD_ADMIN or SUPER_ADMIN

**Authorization**:
- WARD_ADMIN: Can only update services in their ward
- SUPER_ADMIN: Can update any service

**Request Body** (all fields optional):
```json
{
  "name": "Updated Hospital Name",
  "type": "Hospital",
  "phone": "9876543210",
  "alternate_phone": "9876543211",
  "email": "hospital@city.gov",
  "address": "New Address",
  "google_maps_link": "https://maps.google.com/...",
  "category": "Government"
}
```

**Response**: Updated service object

---

### 5. Delete Emergency Service (Soft Delete)
```
DELETE /admin/emergency/{id}
```

**Required Role**: WARD_ADMIN or SUPER_ADMIN

**Authorization**:
- WARD_ADMIN: Can only delete services in their ward
- SUPER_ADMIN: Can delete any service

**Response**:
```json
{
  "message": "Service deleted successfully"
}
```

---

## Complaints Endpoints

### 6. Get Complaints
```
GET /complaints/
```

**Query Parameters**:
- `page` (optional): Page number, default 1
- `page_size` (optional): Items per page, default 10, max 50
- `status` (optional): PENDING, IN_PROGRESS, RESOLVED, REJECTED
- `category` (optional): Category filter
- `priority` (optional): LOW, MEDIUM, HIGH
- `search` (optional): Search by complaint number, title, description

**Auto-Filtering**:
- **CITIZEN**: Only their own complaints
- **FIELD_OFFICER**: Only assigned complaints
- **WARD_ADMIN**: Only complaints from their ward
- **SUPER_ADMIN**: All complaints

**Response**:
```json
{
  "complaints": [
    {
      "id": 1,
      "complaint_number": "CMP202401011234AB12",
      "category": "Pothole",
      "title": "Large pothole on Main Street",
      "description": "Dangerous pothole affecting traffic",
      "address": "123 Main Street",
      "latitude": "12.9716",
      "longitude": "77.5946",
      "status": "PENDING",
      "priority": "HIGH",
      "user_name": "John Doe",
      "user_mobile": "9876543210",
      "ward_name": "Ward 1",
      "assigned_officer_name": "Officer Smith",
      "media": [
        {
          "id": 1,
          "file_path": "/uploads/complaints/image123.jpg",
          "file_type": "IMAGE",
          "file_name": "pothole.jpg",
          "uploaded_at": "2024-01-01T10:00:00"
        }
      ],
      "created_at": "2024-01-01T10:00:00",
      "updated_at": "2024-01-01T15:30:00",
      "resolved_at": null
    }
  ],
  "total": 45,
  "page": 1,
  "page_size": 10
}
```

---

### 7. Create Complaint
```
POST /complaints/
```

**Required Role**: CITIZEN, FIELD_OFFICER, WARD_ADMIN (creates for ward)

**Request Body** (form-data):
- `category` (required): Complaint category
- `title` (required): Complaint title
- `description` (required): Detailed description
- `address` (required): Location address
- `latitude` (optional): GPS latitude
- `longitude` (optional): GPS longitude
- `media_files` (optional): Images/videos

**Auto-Assignments**:
- `user_id`: Current user
- `ward_id`: User's ward
- `status`: PENDING
- `priority`: MEDIUM

**Response**: Created complaint object

---

## Admin Dashboard Endpoints

### 8. Get Dashboard Statistics
```
GET /admin/dashboard
```

**Required Role**: WARD_ADMIN or SUPER_ADMIN

**Auto-Filtering**:
- WARD_ADMIN: Ward statistics only
- SUPER_ADMIN: Global statistics

**Response**:
```json
{
  "total_complaints": 156,
  "pending_complaints": 45,
  "resolved_complaints": 98,
  "in_progress_complaints": 13,
  "total_citizens": 2450,
  "total_officers": 23,
  "complaints_today": 3,
  "complaints_this_week": 28,
  "category_wise": {
    "Pothole": 45,
    "Streetlight": 38,
    "Water": 32,
    "Garbage": 28,
    "Other": 13
  },
  "status_wise": {
    "PENDING": 45,
    "IN_PROGRESS": 13,
    "RESOLVED": 98
  }
}
```

---

## Schemes Endpoints

### 9. Get Schemes
```
GET /schemes
```

**Query Parameters**:
- `category` (optional): Filter by category
- `search` (optional): Search by title or description

**Response**:
```json
[
  {
    "id": 1,
    "title": "Healthcare for All",
    "description": "Free healthcare scheme",
    "category": "Health",
    "eligibility": "All citizens",
    "benefits": "Free medical treatment",
    "how_to_apply": "Visit nearby center",
    "documents_required": "Aadhar, Medical report",
    "application_deadline": "2024-12-31",
    "is_active": "Y",
    "created_at": "2024-01-01T10:00:00"
  }
]
```

---

## Jobs Endpoints

### 10. Get Job Vacancies
```
GET /jobs
```

**Query Parameters**:
- `search` (optional): Search by job title or organization

**Response**:
```json
[
  {
    "id": 1,
    "title": "Junior Engineer",
    "organization": "Municipal Corporation",
    "posts_available": 5,
    "age_limit": "18-45",
    "qualifications": "Bachelor's in Engineering",
    "salary": "25000-35000",
    "job_description": "Maintain city infrastructure",
    "how_to_apply": "Apply online at official portal",
    "application_deadline": "2024-12-31",
    "is_active": "Y",
    "created_at": "2024-01-01T10:00:00"
  }
]
```

---

## RTI Endpoints

### 11. Get RTI Information
```
GET /rti
```

**Response**:
```json
[
  {
    "id": 1,
    "title": "Filing RTI Request",
    "content": "How to file RTI requests...",
    "display_order": 1,
    "is_active": "Y"
  }
]
```

---

## Notices Endpoints

### 12. Get Notices
```
GET /notices
```

**Auto-Filtering**:
- CITIZEN: Ward notices + citywide + their role
- WARD_ADMIN: Ward notices only + citywide
- SUPER_ADMIN: All notices

**Response**:
```json
[
  {
    "id": 1,
    "title": "Water Pipeline Maintenance",
    "message": "Water supply will be cut off tomorrow",
    "notice_type": "WARNING",
    "ward_id": 1,
    "target_role": "CITIZEN",
    "is_active": "Y",
    "created_at": "2024-01-01T10:00:00",
    "expires_at": "2024-01-05T10:00:00"
  }
]
```

### 13. Create Notice
```
POST /admin/notices
```

**Required Role**: WARD_ADMIN or SUPER_ADMIN

**Request Body**:
```json
{
  "title": "Notice Title",
  "message": "Notice message",
  "notice_type": "INFO|WARNING|ALERT",
  "ward_id": 1,
  "target_role": "CITIZEN|WARD_ADMIN|FIELD_OFFICER|null",
  "expires_at": "2024-01-05T10:00:00"
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "detail": "Invalid request parameters"
}
```

### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```

### 403 Forbidden
```json
{
  "detail": "You can only manage services for your ward"
}
```

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```

### 500 Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## Rate Limiting

- Standard: 100 requests per minute
- Admin: 500 requests per minute

---

## Pagination

Standard pagination for list endpoints:
- `page`: 1-based page number
- `page_size`: 1-50 items per page
- Response includes `total` count and metadata

---

## Best Practices

1. **Always include Authorization header** for authenticated endpoints
2. **Use query parameters** for filtering, not in request body
3. **Handle pagination** when total > page_size
4. **Validate input** on client side before sending
5. **Handle error responses** appropriately
6. **Use appropriate HTTP methods**: GET for reading, POST for creating, PUT for updating, DELETE for removing
