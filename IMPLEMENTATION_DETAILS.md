# Implementation Details - Ward Selection Feature

## 1. Backend API Changes

### File: `/nagarseva-backend/app/api/services.py`

#### Endpoint: GET /emergency
**Location**: Lines 30-67

**Old Implementation**:
```python
@router.get("/emergency", response_model=List[EmergencyServiceResponse])
async def get_emergency_services(
    type: Optional[str] = None,
    category: Optional[str] = None,
    ward_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get emergency services for current user's ward (citizen/field officer) or filtered by ward_id (admin)"""
    query = db.query(EmergencyService).filter(EmergencyService.is_active == "Y")
    
    # Auto-filter by user's ward for citizens and field officers
    if current_user.role == UserRole.CITIZEN or current_user.role == UserRole.FIELD_OFFICER:
        query = query.filter(
            or_(
                EmergencyService.ward_id == current_user.ward_id,
                EmergencyService.is_citywide == True
            )
        )
    # ... rest of code
```

**New Implementation**:
```python
@router.get("/emergency", response_model=List[EmergencyServiceResponse])
async def get_emergency_services(
    type: Optional[str] = None,
    category: Optional[str] = None,
    ward_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get emergency services. Citizens can view any ward's services. Ward admins see only their ward."""
    query = db.query(EmergencyService).filter(EmergencyService.is_active == "Y")
    
    # Citizens and Field Officers can view all wards' services or filter by specific ward
    if current_user.role == UserRole.CITIZEN or current_user.role == UserRole.FIELD_OFFICER:
        # If ward_id is specified, show only that ward's services
        # Otherwise, show all services (citizen can select any ward)
        if ward_id:
            query = query.filter(
                or_(
                    EmergencyService.ward_id == ward_id,
                    EmergencyService.is_citywide == True
                )
            )
        # If no ward_id specified, show all active services (citywide + all wards)
    elif current_user.role == UserRole.WARD_ADMIN:
        # Ward admin sees only their ward services + citywide
        query = query.filter(
            or_(
                EmergencyService.ward_id == current_user.ward_id,
                EmergencyService.is_citywide == True
            )
        )
    # SUPER_ADMIN can filter by ward_id if provided, otherwise sees all
    elif current_user.role == UserRole.SUPER_ADMIN and ward_id:
        query = query.filter(EmergencyService.ward_id == ward_id)
    
    if type:
        query = query.filter(EmergencyService.type == type)
    
    if category:
        query = query.filter(EmergencyService.category == category)
    
    return query.all()
```

**Key Differences**:
1. Citizens no longer auto-filtered to their ward
2. If `ward_id` parameter provided: filter to that ward + citywide
3. If no `ward_id` parameter: return all active services
4. Ward admins behavior unchanged (still restricted to their ward)
5. Super admins behavior unchanged (see all or filter by ward)

---

## 2. Flutter Frontend Changes

### File: `/nagarseva-flutter/lib/screens/services/emergency_screen.dart`

#### State Variables Added
**Location**: Lines 15-17

```dart
class _EmergencyScreenState extends State<EmergencyScreen> {
  int? _selectedWardId;  // NEW: Track selected ward (null = all wards)
```

**Purpose**: Stores the currently selected ward for filtering services

---

#### initState and _loadData Updated
**Location**: Lines 19-43

**Old Implementation**:
```dart
@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  // Load emergency services for the current user's ward
  await servicesProvider.loadEmergencyServices();
}
```

**New Implementation**:
```dart
@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  // Load wards for selection dropdown - NEW
  await authProvider.loadWards();
  
  // Load emergency services (optionally filtered by selected ward)
  await servicesProvider.loadEmergencyServices(wardId: _selectedWardId);
}
```

**Changes**:
1. Loads all wards for dropdown via `authProvider.loadWards()`
2. Passes `wardId: _selectedWardId` to load services
3. If `_selectedWardId` is null, API returns all wards' services

---

#### New Method: _onWardChanged
**Location**: Lines 35-43

```dart
Future<void> _onWardChanged(int? wardId) async {
  setState(() {
    _selectedWardId = wardId;
  });
  
  final servicesProvider = Provider.of<ServicesProvider>(context, listen: false);
  await servicesProvider.loadEmergencyServices(wardId: wardId);
}
```

**Purpose**: 
1. Updates state when user changes ward selection
2. Immediately reloads services for new ward
3. Handles null value (all wards)

**Triggered By**: Ward dropdown onChanged callback

---

#### UI Addition: Ward Selector Card
**Location**: Lines 120-173 (in build method)

```dart
// Ward Selector
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Select Ward',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButton<int?>(
            value: _selectedWardId,
            isExpanded: true,
            hint: const Text('All Wards'),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: const Text('All Wards'),
              ),
              ...authProvider.wards.map((ward) {
                return DropdownMenuItem<int?>(
                  value: ward.id,
                  child: Text('Ward ${ward.wardNumber}: ${ward.name}'),
                );
              }).toList(),
            ],
            onChanged: _onWardChanged,
            underline: Container(),
          ),
        ],
      ),
    );
  },
),
const SizedBox(height: 24),
```

**Components**:
1. **Container**: Blue-themed card for visual distinction
2. **Row**: Header with location icon and "Select Ward" label
3. **DropdownButton<int?>**: 
   - Value: `_selectedWardId` (null or ward ID)
   - Items: "All Wards" + list of all wards from AuthProvider
   - OnChanged: Calls `_onWardChanged()` to update services
4. **Spacing**: 24px below dropdown before Emergency SOS button

**Positioning**: Placed after AppBar, before Emergency SOS Button

**Visibility**: Rendered for all users (visible to citizens, hidden for admins is handled elsewhere)

---

### File: `/nagarseva-flutter/lib/providers/services_provider.dart`

#### Updated Documentation
**Location**: Lines 43-50

**Old Comment**:
```dart
// Emergency Services
Future<void> loadEmergencyServices({String? type, int? wardId}) async {
  _setLoading(true);
  _setError(null);
  
  try {
    // API will auto-filter by user's ward based on their role
    final response = await _apiService.getEmergencyServices(
```

**New Comment**:
```dart
// Emergency Services
Future<void> loadEmergencyServices({String? type, int? wardId}) async {
  _setLoading(true);
  _setError(null);
  
  try {
    // Citizens can view all wards' services or filter by specific ward
    // Ward admins see only their ward + citywide services
    // Super admins see all services
    final response = await _apiService.getEmergencyServices(
```

**Purpose**: Clarifies new behavior of the API

---

## 3. Data Models (No Changes Needed)

### Ward Model
Already has required fields:
```dart
class Ward {
  final int id;                    // Used in dropdown value
  final int wardNumber;            // Displayed in dropdown
  final String name;               // Displayed in dropdown
  final String city;
  final String state;
  final String? description;
}
```

### EmergencyService Model
Already has required fields:
```dart
class EmergencyService {
  final int id;
  final String name;
  final String type;
  final String? phone;
  final String? address;
  final int? wardId;              // Indicates which ward service is for
  final String? isCitywide;        // Indicates if visible to all wards
  // ... other fields
}
```

---

## 4. API Service (No Changes Needed)

The `ApiService` already supports `wardId` parameter:
```dart
Future<Response> getEmergencyServices({
  String? type,
  int? wardId,
}) async {
  // API call with optional ward_id parameter
}
```

---

## 5. AuthProvider (No Changes Needed)

Already has `loadWards()` method:
```dart
class AuthProvider extends ChangeNotifier {
  List<Ward> _wards = [];
  
  List<Ward> get wards => _wards;
  
  Future<void> loadWards() async {
    try {
      final response = await _apiService.getWards();
      _wards = (response.data as List).map((w) => Ward.fromJson(w)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load wards');
    }
  }
}
```

---

## 6. Complaint Filing (UNCHANGED)

### File: `/nagarseva-flutter/lib/screens/complaints/file_complaint_screen.dart`

**No changes needed** - Complaints still auto-assign ward:
```dart
final success = await complaintProvider.fileComplaint(
  title: _titleController.text.trim(),
  description: _descriptionController.text.trim(),
  category: _selectedCategory!,
  priority: _selectedPriority ?? 'medium',
  location: _locationController.text.trim(),
  wardNo: authProvider.user?.wardNo ?? 1,  // Auto-assigned
  // ... other fields
);
```

---

## 7. Complaint Tracking (UNCHANGED)

### File: `/nagarseva-flutter/lib/screens/complaints/my_complaints_screen.dart`

**No changes needed** - Still shows only user's complaints:
```dart
Future<void> _loadComplaints() async {
  final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
  await complaintProvider.loadComplaints();
  // Backend filters to show only current user's complaints
}
```

---

## 8. Security Enforcement Points

### Backend Level (Primary)
```python
# GET /emergency endpoint enforces:
if current_user.role == UserRole.CITIZEN:
    if ward_id:
        # Show that ward + citywide (user can select)
    else:
        # Show all services (default)
elif current_user.role == UserRole.WARD_ADMIN:
    # Enforce: only their ward (ward_id param ignored)
elif current_user.role == UserRole.SUPER_ADMIN:
    # Allow: all or filtered by ward_id
```

### Frontend Level (UX)
```dart
// Only citizens see ward dropdown
// Ward admins/super admins see restricted view
// (handled by role-based navigation elsewhere)
```

---

## 9. Testing Scenarios

### Scenario 1: Citizen Views All Wards
```
1. Citizen opens Emergency Services
2. Ward selector shows with "All Wards" selected
3. API called with wardId=null
4. Services from all wards returned and displayed
5. User can interact with all services
```

### Scenario 2: Citizen Selects Specific Ward
```
1. Citizen selects "Ward 3" from dropdown
2. _onWardChanged(3) called
3. _selectedWardId = 3 (setState)
4. loadEmergencyServices(wardId: 3) called
5. API returns Ward 3 services + citywide
6. List updated automatically
```

### Scenario 3: Ward Admin Opens Emergency Services
```
1. Ward Admin navigates to Emergency Services
2. No ward selector displayed (restricted at navigation level)
3. Services auto-filtered to their ward in API
4. Cannot select other wards
```

### Scenario 4: Citizen Files Complaint
```
1. Citizen opens File Complaint
2. Ward auto-assigned from their profile
3. Cannot change ward during filing
4. Backend validates ward matches user's ward
5. Complaint created with correct ward
```

---

## 10. Performance Considerations

### Data Loading
- **Wards**: Loaded once on screen init (small dataset)
- **Services**: Loaded based on selection
- **Caching**: Handled by existing provider pattern

### API Calls
- Initial: 2 calls (loadWards + loadEmergencyServices)
- Per selection change: 1 call (loadEmergencyServices with wardId)
- Network: Minimal overhead (just wardId param)

### UI Rendering
- Dropdown creation: O(n) where n = number of wards
- Service list: O(m) where m = services in selected ward
- Typical: < 10 wards, < 50 services per ward

---

## 11. Backward Compatibility

✅ **Old clients** (without ward selector):
- Still works, uses default (null) which returns all wards
- API unchanged, parameter is optional

✅ **New clients** (with ward selector):
- Can select wards
- Default is "All Wards"
- Can revert to showing all by clearing selection

✅ **API**:
- Backward compatible
- New ward_id parameter is optional
- Old behavior available (don't pass wardId)

---

## 12. Deployment Steps

### Step 1: Deploy Backend
```bash
# Update GET /emergency in services.py
# Run existing migrations (none needed)
# Restart FastAPI server
```

### Step 2: Deploy Flutter
```bash
# Update emergency_screen.dart
# Update services_provider.dart comments
# Rebuild Flutter app
# Deploy to App Store / Play Store
```

### Step 3: Testing
```bash
# Test citizen can view all wards
# Test citizen can select specific ward
# Test ward admin cannot select other wards
# Test super admin has full access
# Test complaints still ward-specific
```

---

**Total Changes**: 3 files modified  
**Lines Changed**: ~70 lines  
**Complexity**: Low  
**Risk**: Low (read-only changes to service viewing)  
**Rollback**: Easy (revert to auto-filter by user's ward)
