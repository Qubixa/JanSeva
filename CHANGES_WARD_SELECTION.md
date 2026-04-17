# Ward-Based Feature Update

## Overview
Updated the NagarSeva application to allow citizens to select and view emergency services from any ward, while keeping complaint filing and tracking ward-specific.

## Changes Made

### 1. Backend Changes (FastAPI)

#### File: `/nagarseva-backend/app/api/services.py`

**Updated Endpoint: `GET /emergency`**
- **Citizens/Field Officers**: Can now view all active emergency services across all wards
  - If `ward_id` parameter is provided: filters to that specific ward + citywide services
  - If no `ward_id` parameter: shows all services (citywide + all wards)
- **Ward Admins**: Still restricted to their own ward + citywide services
- **Super Admins**: Full access to all services

**Key Change:**
```python
# Before: Citizens auto-filtered to their ward only
if current_user.role == UserRole.CITIZEN:
    query = query.filter(
        or_(
            EmergencyService.ward_id == current_user.ward_id,
            EmergencyService.is_citywide == True
        )
    )

# After: Citizens can view all wards or filter by specific ward
if current_user.role == UserRole.CITIZEN or current_user.role == UserRole.FIELD_OFFICER:
    if ward_id:
        query = query.filter(
            or_(
                EmergencyService.ward_id == ward_id,
                EmergencyService.is_citywide == True
            )
        )
    # If no ward_id specified, show all active services
```

### 2. Flutter Frontend Changes

#### File: `/nagarseva-flutter/lib/screens/services/emergency_screen.dart`

**Added Features:**
1. **Ward Selection Dropdown**
   - Placed at the top of the emergency services screen
   - Shows "All Wards" as default option
   - Lists all available wards with ward number and name
   - Users can switch between wards seamlessly

2. **Dynamic Service Loading**
   - Services update automatically when ward selection changes
   - Loads all wards into memory on screen init via `authProvider.loadWards()`
   - Passes selected `wardId` to service loader

3. **State Management**
   - Added `_selectedWardId` state variable to track selection
   - Added `_onWardChanged()` method to handle ward changes
   - Updated `_loadData()` to load wards on init

**UI Elements Added:**
- Ward selector card with blue theme matching the rest of the app
- Location icon for visual clarity
- Dropdown with all available wards
- Shows current selection with ability to change instantly

#### File: `/nagarseva-flutter/lib/providers/services_provider.dart`

**Updated Comments:**
- Clarified that citizens can now view all wards or filter by specific ward
- Updated documentation to reflect new behavior

---

## Features That Remain Ward-Specific

### Complaint Filing (File Complaint Screen)
- **Auto-assigned**: Ward is automatically assigned from user's registered profile
- **No selection**: Citizens cannot choose a different ward
- **Enforcement**: Backend validates that complaints are filed only in user's ward

### Complaint Tracking (My Complaints Screen)
- **Own complaints only**: Citizens see only their own complaints
- **Ward-specific**: Each complaint is tied to the citizen's registered ward
- **Enforcement**: Backend filters to show only complaints filed by current user

---

## API Behavior by User Role

### Citizens & Field Officers
| Action | Behavior |
|--------|----------|
| View Emergency Services | Can view any ward's services or all wards |
| File Complaint | Must file in their registered ward |
| Track Complaint | See only their own complaints |
| Select Ward | Can select different ward for viewing services |

### Ward Admins
| Action | Behavior |
|--------|----------|
| View Emergency Services | Their ward + citywide services only |
| File Complaint | Not applicable (not a citizen) |
| Track Complaint | See all complaints in their ward |
| Select Ward | Cannot select other wards |

### Super Admins
| Action | Behavior |
|--------|----------|
| View Emergency Services | All services (can filter by ward) |
| File Complaint | Not applicable (not a citizen) |
| Track Complaint | See all complaints globally |
| Select Ward | Can filter by any ward |

---

## How to Use

### For Citizens:
1. Navigate to "Emergency Services"
2. A ward selector dropdown appears at the top
3. Select "All Wards" to see services from everywhere
4. Or select a specific ward to see only that ward's services
5. Click on a service to call, email, or navigate via maps

### For Ward Admins:
1. Emergency services view shows only their ward services
2. Cannot change ward selection (app-specific restriction)
3. All other features remain unchanged

### For Super Admins:
1. Can view all services globally
2. Can filter by ward if needed
3. Full access to all wards

---

## Backend API Changes

### GET /emergency Endpoint
```
Parameters:
- type: Optional[str] - Filter by service type (POLICE, FIRE, AMBULANCE, etc.)
- category: Optional[str] - Filter by category
- ward_id: Optional[int] - Filter by specific ward (citizens can use this)

Behavior:
- CITIZEN/FIELD_OFFICER: 
  - If ward_id provided: Returns that ward's services + citywide
  - If no ward_id: Returns ALL services (all wards + citywide)
- WARD_ADMIN: Returns only their ward + citywide (ward_id param ignored)
- SUPER_ADMIN: Returns all services or filtered by ward_id if provided
```

---

## Security Considerations

✓ **Backend Enforcement**: All filtering happens at API level
✓ **Role-Based Access**: Ward admins cannot see other wards
✓ **Complaint Integrity**: Complaints still auto-assigned to user's ward
✓ **Ward Admins Protected**: Cannot select other wards for complaints
✓ **No Data Leakage**: Each role sees only permitted data

---

## Testing Recommendations

### For Citizens:
- [ ] View emergency services from all wards
- [ ] Filter to specific ward using dropdown
- [ ] File complaint in default ward (auto-assigned)
- [ ] Cannot change complaint ward during filing
- [ ] View own complaints only

### For Ward Admins:
- [ ] Cannot access ward selection dropdown
- [ ] See only their ward's services
- [ ] View only their ward's complaints
- [ ] Cannot file complaints

### For Super Admins:
- [ ] Can view all services globally
- [ ] Can filter by specific ward
- [ ] Can view all complaints across wards
- [ ] Have full system access

---

## Files Modified

1. `/nagarseva-backend/app/api/services.py` - Updated GET /emergency endpoint
2. `/nagarseva-flutter/lib/screens/services/emergency_screen.dart` - Added ward selector
3. `/nagarseva-flutter/lib/providers/services_provider.dart` - Updated comments

---

## Rollback Plan

If needed to revert:
1. Remove ward selector from `emergency_screen.dart`
2. Reset `services.py` GET /emergency to auto-filter by user's ward
3. Remove `_selectedWardId` and `_onWardChanged()` from emergency screen

---

**Implementation Date**: January 2024  
**Status**: COMPLETE ✓  
**Ready for Testing**: YES ✓
