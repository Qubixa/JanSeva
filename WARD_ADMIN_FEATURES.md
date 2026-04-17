# NagarSeva: Ward-Specific and Admin Features Implementation

## Overview
This document outlines all the ward-specific and admin features implemented to provide citizens, ward admins, and super admins with appropriate views and controls.

---

## 1. Citizen View - Ward-Specific Services

### Emergency Services Screen
- **Auto-filtering by Ward**: Citizens now see emergency services specific to their ward only
- **Citywide Services**: Citizens can also see citywide services marked as `is_citywide: true`
- **API Endpoint**: `/emergency` (requires authentication)
  - Automatically filters by user's ward_id based on user role
  - Returns: All services for citizen's ward + citywide services

### Features:
- View emergency services (Hospital, Police, Fire, Ambulance, Municipal)
- Filter by service type and category
- Direct action buttons:
  - Call phone number
  - Send email
  - Open Google Maps link (if provided)
- All data is ward-specific

---

## 2. Ward Admin View - Comprehensive Ward Management

### Ward Admin Dashboard
**Route**: `/admin/ward-dashboard`

**Features**:
- Ward-specific overview with statistics:
  - Total complaints in ward
  - Pending complaints
  - In-progress complaints
  - Resolved complaints resolution rate
  - Emergency services count
  - Field officers count
- Quick action cards for:
  - View ward complaints
  - Emergency services for ward
  - Manage emergency services
  - Field officers management
  - Notices & announcements
  - Reports and analytics

### Ward Complaints Management Screen
**Route**: `/admin/ward-complaints`

**Features**:
- View all complaints from their ward only
- Filter by status: All, Pending, In Progress, Resolved, Rejected
- Search functionality
- Complaint cards showing:
  - Ticket number
  - Title and category
  - Status and priority
  - Complainant details
  - Created date
- Real-time refresh via pull-to-refresh

### Manage Emergency Services Screen
**Route**: `/admin/manage-emergency-services`

**Features**:
- Ward identification card showing which ward is being managed
- Add new emergency services for their ward:
  - Service name (required)
  - Service type: Hospital, Police, Fire, Ambulance, Municipal (required)
  - Category: Government, Private, NGO (optional)
  - Phone number (required)
  - Alternate phone (optional)
  - Email address (optional)
  - Physical address (optional)
  - Google Maps link (optional)
- View existing services for the ward
- Edit existing services
- Delete services (soft delete)
- Real-time service list updates

### API Endpoints for Ward Admin:
- `GET /admin/emergency` - List ward's emergency services
- `POST /admin/emergency` - Create new service (auto-assigns to ward)
- `PUT /admin/emergency/{id}` - Update service
- `DELETE /admin/emergency/{id}` - Delete service
- `GET /complaints/` - List ward's complaints (auto-filtered)
- `GET /admin/dashboard` - Ward dashboard statistics

---

## 3. Super Admin View - Holistic System Overview

### Super Admin Dashboard
**Route**: `/admin/super-dashboard`

**Features**:
- System-wide statistics:
  - Total wards
  - Total complaints across all wards
  - Resolution percentage
  - Pending complaints (all wards)
- Quick action cards for:
  - All complaints (global view)
  - Manage wards
  - All services (global)
  - User management
  - Analytics
  - System settings

### Capabilities:
- View all complaints from all wards
- View all emergency services from all wards
- Manage ward admins and field officers
- View analytics across all wards
- System configuration and settings

### API Endpoints for Super Admin:
- `GET /admin/emergency` - All services (or filter by ward_id)
- `POST /admin/emergency` - Create service for any ward
- `GET /complaints/` - All complaints (unfiltered)
- `GET /admin/dashboard` - Global statistics
- Full management access to all resources

---

## 4. Role-Based Routing

The app automatically routes users to appropriate screens based on their role:

### Citizens
- Home screen with quick actions
- Emergency services filtered by ward
- File and track complaints
- View schemes, services, jobs, etc.

### Ward Admins
- Dashboard → `/admin/ward-dashboard`
- Manage ward complaints
- Manage emergency services for ward
- View ward-specific statistics

### Super Admins
- Dashboard → `/admin/super-dashboard`
- System-wide management
- Global analytics
- All user and service management

---

## 5. API Changes

### Updated Emergency Services Endpoint
```
GET /emergency
Query Parameters:
  - type: Optional[str] - Service type filter
  - category: Optional[str] - Category filter
  - ward_id: Optional[int] - For super admin filtering

Auto-filtering based on user role:
  - CITIZEN/FIELD_OFFICER: Ward + Citywide services only
  - WARD_ADMIN: Ward + Citywide services only
  - SUPER_ADMIN: All services (or filtered by ward_id param)
```

### New Admin Endpoints
- `GET /admin/emergency` - List services for admin
- `POST /admin/emergency` - Create service
- `PUT /admin/emergency/{id}` - Update service
- `DELETE /admin/emergency/{id}` - Delete service

### Complaint Endpoint Auto-filtering
```
GET /complaints/
Auto-filters based on role:
  - CITIZEN: Own complaints only
  - FIELD_OFFICER: Assigned complaints only
  - WARD_ADMIN: Ward complaints only
  - SUPER_ADMIN: All complaints
```

---

## 6. Database Schema Updates

### Emergency Services Table
Added fields:
- `email` (Optional) - Contact email
- `google_maps_link` (Optional) - Google Maps location link
- `category` (Optional) - Custom category field
- `created_by` (User ID) - Track who created the service
- `updated_at` (Timestamp) - Track updates

---

## 7. Flutter Implementation

### New Screens Created:
1. **SuperAdminDashboardScreen** - `/admin/super-dashboard`
2. **WardAdminDashboardScreen** - `/admin/ward-dashboard`
3. **WardComplaintsScreen** - `/admin/ward-complaints`
4. **ManageEmergencyServicesScreen** - `/admin/manage-emergency-services`
5. **EmergencyServicesViewScreen** - Public emergency services viewer

### Updated Screens:
1. **HomeScreen** - Role-based routing on initState
2. **EmergencyScreen** - Auto-loads ward-specific services
3. **MyComplaintsScreen** - Corrected method calls

### Routes Added:
```dart
static const String superAdminDashboard = '/admin/super-dashboard';
static const String wardAdminDashboard = '/admin/ward-dashboard';
static const String wardComplaints = '/admin/ward-complaints';
static const String manageEmergencyServices = '/admin/manage-emergency-services';
```

### API Service Methods Added:
- `getAdminEmergencyServices()` - Load services with admin filters
- `createEmergencyService()` - Create new emergency service
- `updateEmergencyService()` - Update existing service
- `deleteEmergencyService()` - Delete service

---

## 8. User Experience Flow

### For Citizens:
1. Login → Home screen
2. View emergency services (auto-filtered to their ward)
3. File complaint → Service uses citizen's ward automatically
4. Track complaints → Sees only their own complaints

### For Ward Admins:
1. Login → Redirected to Ward Admin Dashboard
2. View ward statistics
3. Manage complaints in their ward only
4. Add/edit emergency services for their ward
5. Cannot access other wards' data

### For Super Admins:
1. Login → Redirected to Super Admin Dashboard
2. System-wide statistics
3. Can access all wards' data
4. Can manage services across all wards
5. Full system control

---

## 9. Security Features

- **Role-based filtering** at API level ensures users only see authorized data
- **Ward admin authorization** prevents ward admins from accessing other wards
- **Auto-assignment** of ward_id when ward admins create services
- **Super admin override** allows global management when needed

---

## 10. Data Persistence

All ward-specific data is:
- Automatically filtered at API level
- Backend enforces role-based permissions
- User ward_id is automatically included in requests
- No client-side filtering prevents unauthorized access

---

## Testing Checklist

- [ ] Citizen sees only their ward's emergency services
- [ ] Citizen sees citywide services
- [ ] Ward admin sees only their ward's complaints
- [ ] Ward admin can add services only to their ward
- [ ] Super admin sees all complaints
- [ ] Super admin can manage all services
- [ ] Dashboard statistics are correct per role
- [ ] Google Maps links work
- [ ] Phone call integration works
- [ ] Email integration works
- [ ] Refresh loads updated data
- [ ] Role-based routing works on login
