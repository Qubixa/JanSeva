# Quick Setup Instructions

## Backend Setup

### 1. Update Python Models
Already done - models updated in:
- `app/models/user.py` - OTP removed
- `app/models/emergency.py` - Enhanced with email, maps_link, category, created_by

### 2. Run Database Migration
```bash
# Using Python/alembic (if configured):
alembic upgrade head

# Or run SQL directly:
psql -U postgres -d nagarseva -f nagarseva-backend/scripts/003_update_auth_and_emergency.sql
```

### 3. Verify Backend is Running
```bash
cd nagarseva-backend
python -m uvicorn app.main:app --reload
# Should be accessible at http://localhost:8000
```

## Frontend Setup (Flutter)

### 1. Update Dependencies
No new dependencies needed - uses existing packages

### 2. Clean Build
```bash
cd nagarseva-flutter
flutter clean
flutter pub get
```

### 3. Run App
```bash
flutter run
```

## Testing the Changes

### Test 1: Registration Without OTP
1. Open app → Register
2. Fill all fields with:
   - Name: Test User
   - Mobile: 9876543210
   - Password: test@123
   - Confirm Password: test@123
   - Ward: Any ward
   - Address: Test Address
3. Click "Register" (no OTP step)
4. Should redirect to home after successful registration

### Test 2: Emergency Services Management (Admin)
1. Login as Ward Admin/Super Admin
2. Navigate to "Manage Emergency Services"
3. Click "Add New Service"
4. Fill form:
   - Name: Test Hospital
   - Type: Hospital
   - Phone: 9876543210
   - Google Maps Link: https://maps.google.com/maps?...
   - Email: hospital@test.com
5. Click "Add Service"
6. Should see success message

### Test 3: View Emergency Services (Public)
1. Navigate to Emergency Services
2. See list of services
3. Test filters (by type)
4. Click Call → Should open phone dial
5. Click Maps → Should open Google Maps
6. Click Email → Should open email client

## API Endpoints Reference

### Authentication
```
POST /api/v1/auth/register
- No OTP needed
- Body: name, mobile, password, confirm_password, ward_id, address, email (optional)

POST /api/v1/auth/login
- Body: mobile, password
```

### Emergency Services (Public)
```
GET /api/v1/emergency
- Params: type, category, ward_id
- Returns: List of active emergency services
```

### Emergency Services (Admin)
```
POST /api/v1/admin/emergency
- Create new service (Ward Admin/Super Admin)

GET /api/v1/admin/emergency
- List services for management

PUT /api/v1/admin/emergency/{id}
- Update service

DELETE /api/v1/admin/emergency/{id}
- Soft delete service
```

### Other Services
```
GET /api/v1/schemes - List schemes
POST /api/v1/admin/schemes - Create scheme
PUT /api/v1/admin/schemes/{id} - Update scheme

GET /api/v1/jobs - List jobs
POST /api/v1/admin/jobs - Create job
PUT /api/v1/admin/jobs/{id} - Update job

GET /api/v1/rti - List RTI info
POST /api/v1/admin/rti - Create RTI
PUT /api/v1/admin/rti/{id} - Update RTI

GET /api/v1/notices - List notices
POST /api/v1/admin/notices - Create notice
PUT /api/v1/admin/notices/{id} - Update notice

GET /api/v1/transport - List transport
POST /api/v1/admin/transport - Create transport
PUT /api/v1/admin/transport/{id} - Update transport
```

## Common Issues & Solutions

### Issue: "OTP table does not exist"
**Solution:** Run the migration script to remove OTP table
```bash
psql -U postgres -d nagarseva -f nagarseva-backend/scripts/003_update_auth_and_emergency.sql
```

### Issue: "confirm_password field not recognized"
**Solution:** Make sure you're using the updated register endpoint
- Clear Flutter cache: `flutter clean`
- Rebuild: `flutter pub get && flutter run`

### Issue: "Ward not found" error during registration
**Solution:** Verify ward_id exists in database
```sql
SELECT * FROM wards;
```

### Issue: Emergency service creation fails
**Solution:** Check that:
- Phone number is valid (10+ digits)
- Ward ID exists and belongs to admin's ward (for Ward Admin)
- Google Maps link format is correct (full URL)

## Database Verification

### Check if migration was applied:
```sql
-- Check if otps table exists (should not)
SELECT tablename FROM pg_tables WHERE tablename = 'otps';
-- Result: Should be empty

-- Check emergency_services columns
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'emergency_services';
-- Should include: email, google_maps_link, category, created_by
```

## Troubleshooting Checklist

- [ ] Database migration ran successfully
- [ ] OTP table removed from database
- [ ] Flask server restarted
- [ ] Flutter app cleaned and rebuilt
- [ ] Updated API endpoints are working
- [ ] Authentication without OTP works
- [ ] Ward Admin can create emergency services
- [ ] Public can view emergency services

## Environment Variables (if needed)

For Flutter API integration:
```dart
const String apiBaseUrl = 'http://localhost:8000/api/v1';
// Or use your production URL
const String apiBaseUrl = 'https://api.nagarseva.app/api/v1';
```

## Next: API Integration in Flutter

The screens are ready but need API calls. Update these methods:

**In `manage_emergency_services_screen.dart`:**
```dart
Future<void> _addService() async {
  // Call: await apiService.createEmergencyService(...)
  // Parse response and update UI
}
```

**In `emergency_services_view_screen.dart`:**
```dart
@override
void initState() {
  super.initState();
  // Call: _loadServices();
}

Future<void> _loadServices() async {
  // Call: await apiService.getEmergencyServices(...)
  // Update mockServices with real data
}
```

## Deployment Checklist

- [ ] Run database migration on production
- [ ] Update backend code
- [ ] Update Flutter code
- [ ] Test registration flow end-to-end
- [ ] Test emergency services creation
- [ ] Test public emergency services view
- [ ] Monitor logs for errors
- [ ] Get user feedback

## Support

For issues or questions, check:
1. Backend logs: `tail -f nagarseva-backend/logs/*.log`
2. Flutter logs: `flutter logs`
3. Database: Direct SQL query
4. API: Test with cURL or Postman
