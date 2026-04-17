# NagarSeva - Quick Reference Guide

## What's New?

### Citizens
- ✓ Emergency services automatically filtered to your ward
- ✓ See citywide services too
- ✓ Direct call/email/maps buttons for services
- ✓ Ward automatically assigned to complaints

### Ward Admins
- ✓ Dedicated dashboard with ward statistics
- ✓ Manage all complaints in your ward
- ✓ Add/edit/delete emergency services for your ward
- ✓ Add Google Maps links, optional email/phone

### Super Admins
- ✓ Global dashboard with system-wide stats
- ✓ See all complaints from all wards
- ✓ Manage services in any ward
- ✓ Full system control

---

## User Journey by Role

### CITIZEN
```
Login → Home Screen → Choose Action:
  ├─ Emergency Services (ward-specific)
  ├─ File Complaint (ward auto-assigned)
  ├─ Track Complaint (view own)
  └─ Other Services (schemes, jobs, etc)
```

### WARD ADMIN
```
Login → Ward Admin Dashboard → Choose Action:
  ├─ View Complaints (ward-specific)
  ├─ Manage Emergency Services
  │   ├─ Add new service
  │   ├─ Edit service
  │   └─ Delete service
  ├─ Field Officers
  ├─ Notices & Announcements
  └─ Reports
```

### SUPER ADMIN
```
Login → Super Admin Dashboard → Choose Action:
  ├─ All Complaints (global)
  ├─ Manage All Services
  ├─ User Management
  ├─ Ward Management
  ├─ Analytics
  └─ Settings
```

---

## Key Routes

| Route | Screen | For Role |
|-------|--------|----------|
| `/home` | Home Screen | CITIZEN |
| `/admin/super-dashboard` | Super Admin Dashboard | SUPER_ADMIN |
| `/admin/ward-dashboard` | Ward Admin Dashboard | WARD_ADMIN |
| `/admin/ward-complaints` | Ward Complaints | WARD_ADMIN |
| `/admin/manage-emergency-services` | Manage Services | WARD_ADMIN |
| `/emergency` | Emergency Services | CITIZEN/ADMIN |
| `/my-complaints` | My Complaints | CITIZEN |

---

## Auto-Redirects

The app automatically redirects users on login:
- **CITIZEN** → Home screen (normal flow)
- **WARD_ADMIN** → Ward Admin Dashboard
- **SUPER_ADMIN** → Super Admin Dashboard
- **FIELD_OFFICER** → Home screen

---

## Emergency Services Management

### For Citizens
- View services for their ward
- See citywide services (if marked)
- Call, email, or navigate via maps

### For Ward Admins
```
Manage Emergency Services Screen:
├─ Ward info card (shows which ward)
├─ Add Service button
│   ├─ Name (required)
│   ├─ Type: Hospital/Police/Fire/Ambulance/Municipal
│   ├─ Category: Government/Private/NGO
│   ├─ Phone (required)
│   ├─ Alternate Phone
│   ├─ Email
│   ├─ Address
│   └─ Google Maps Link
├─ View services list
└─ Edit/Delete buttons
```

**Note**: Ward ID is automatically set to admin's ward. Cannot create for other wards.

---

## Complaint Management

### For Citizens
- File complaint → Ward auto-assigned
- Track complaint → See own only
- View status and history

### For Ward Admins
```
Ward Complaints Screen:
├─ Search by title, number, description
├─ Filter by status: All/Pending/In Progress/Resolved/Rejected
├─ View complaint cards
└─ Click for details
```

### For Super Admins
- View complaints from all wards
- No filtering by ward (can filter by any parameter)
- See all complaint details

---

## Dashboard Statistics

### Ward Admin Dashboard
- Total Complaints (in ward)
- Pending Complaints
- In Progress Complaints
- Resolved (with %)
- Emergency Services count
- Field Officers count

### Super Admin Dashboard
- Total Wards
- Total Complaints (global)
- Resolution Rate (%)
- Pending Complaints (global)
- Plus quick action tiles

---

## API Quick Reference

### Emergency Services
```
GET /emergency
→ Auto-filters by user's ward (citizens/ward admins)
→ All services for super admins

POST /admin/emergency
→ Create service for your ward (ward admin)
→ Ward ID auto-assigned

PUT /admin/emergency/{id}
→ Update service (ward admin)

DELETE /admin/emergency/{id}
→ Delete service (soft delete, ward admin)
```

### Complaints
```
GET /complaints/
→ Auto-filters by role (citizen/admin)

POST /complaints/
→ File complaint (ward auto-assigned)
```

### Dashboards
```
GET /admin/dashboard
→ Ward stats (ward admin) or global stats (super admin)
```

---

## Features at a Glance

| Feature | Citizen | Ward Admin | Super Admin |
|---------|---------|-----------|------------|
| View own ward services | ✓ | ✓ | ✓ |
| Add emergency services | ✗ | ✓ (own ward) | ✓ (any ward) |
| View own complaints | ✓ | ✗ | ✗ |
| View ward complaints | ✗ | ✓ | ✗ |
| View all complaints | ✗ | ✗ | ✓ |
| Ward dashboard | ✗ | ✓ | ✗ |
| Global dashboard | ✗ | ✗ | ✓ |
| Access admin features | ✗ | ✓ | ✓ |

---

## Important Notes

1. **Ward Assignment**: Automatic based on user profile
2. **Google Maps**: Use full URL (https://maps.google.com/...)
3. **Phone Fields**: Format with country code (e.g., +91 9876543210)
4. **Soft Delete**: Services marked as inactive, not deleted
5. **Role Change**: Requires re-login to take effect
6. **Pagination**: Handled server-side, see more on scroll

---

## Troubleshooting

### Not seeing services?
- Check your ward assignment
- Verify internet connection
- Pull-to-refresh the screen

### Can't add service as ward admin?
- Verify you have WARD_ADMIN role
- Check that you're in your ward
- Try refreshing the page

### Seeing other wards' data?
- This shouldn't happen (role-based filtering)
- Contact admin if issue persists

### Can't navigate to maps?
- Ensure Google Maps app/browser support
- Check if URL is valid
- Try opening in browser directly

---

## Contact & Support

For issues or questions:
1. Check documentation files (WARD_ADMIN_FEATURES.md, API_ENDPOINTS_GUIDE.md)
2. Review error messages in app
3. Check server logs if API issues
4. Contact system admin for user role changes

---

**Last Updated**: January 2024
**Version**: 1.0 - Complete Implementation
