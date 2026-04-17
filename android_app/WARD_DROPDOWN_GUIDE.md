# Ward Dropdown Feature Guide

## Overview
Added a ward dropdown selector on the home screen that allows citizens to select from any available ward and view emergency services specific to that ward. Emergency services are no longer restricted to the user's assigned ward.

## What Changed

### 1. New Ward Model
**File:** `/lib/core/models/ward_model.dart`
- Created `Ward` class with id, name, description, and isActive properties
- Includes JSON serialization for API integration

### 2. Updated Constants
**File:** `/lib/core/constants/app_constants.dart`
- Added `WARDS_ENDPOINT = '/wards'`
- This endpoint should return a list of all available wards

### 3. Enhanced Services Provider
**File:** `/lib/core/providers/services_provider.dart`
- Added `_wards` list to store available wards
- Added `_selectedWard` to track currently selected ward
- Added `fetchWards()` method to fetch all wards from the backend
- Added `setSelectedWard(Ward?)` method to update selected ward
- Modified `fetchEmergencyServices()` to use the selected ward instead of user's assigned ward

### 4. Updated Home Screen
**File:** `/lib/presentation/screens/home/home_screen.dart`
- Imported `ServicesProvider`
- Added `_loadWards()` in initState to fetch available wards on home screen load
- Added beautiful ward dropdown in the header section with:
  - Light background overlay
  - White text styling consistent with header
  - Loading state indicator
  - Selected ward display with checkmark icon
  - Dropdown menu showing all available wards

### 5. Updated Emergency Services Screen
**File:** `/lib/presentation/screens/services/emergency_services_screen.dart`
- Modified `_fetchServices()` to use selected ward from dropdown
- Fallback to user's assigned ward if none selected
- Updated app bar to show selected ward name below the title
- Shows clear indication of which ward's services are being displayed

## How It Works

### User Flow
1. User opens the app and navigates to Home Screen
2. Wards are automatically fetched from the backend
3. Ward dropdown appears in the header section
4. User selects a ward from the dropdown
5. Selected ward is highlighted with a checkmark
6. When user taps "Emergency Services", services for the selected ward are displayed
7. User can change the ward at any time and services will update

### Backend Integration
The feature requires these endpoints:

```
GET /api/wards
Response: [
  {
    "id": 1,
    "name": "Ward 1",
    "description": "Downtown Area",
    "is_active": true
  },
  {
    "id": 2,
    "name": "Ward 2",
    "description": "Residential Area",
    "is_active": true
  }
]

GET /api/services/emergency?ward_id=1
Response: [
  {
    "id": 1,
    "name": "Fire Department",
    "description": "24/7 Fire Safety Services",
    "phone": "101",
    "ward_id": 1,
    "ward_name": "Ward 1",
    ...
  }
]
```

## Key Features

✅ **Dynamic Ward Selection** - Citizens can view services for any ward
✅ **No Hardcoded Data** - All wards fetched from backend
✅ **Smart Fallback** - Uses user's assigned ward if none selected
✅ **Visual Feedback** - Shows selected ward with checkmark and in header
✅ **Responsive Design** - Works perfectly on all screen sizes
✅ **Automatic Loading** - Wards load automatically on home screen open

## UI/UX Details

### Ward Dropdown Styling
- **Location:** Top section of home screen header
- **Background:** Translucent white (0.2 opacity) for readability
- **Border Radius:** 8px for modern look
- **Text Color:** White for contrast against blue header
- **Icon Color:** White dropown arrow

### Emergency Services Header Update
- **Title:** "Emergency Services"
- **Subtitle:** Selected ward name (or "Select Ward" if none chosen)
- **Visual:** Clear indication of which ward's data is shown

## Error Handling

- If ward fetch fails, dropdown shows a loading message
- If no emergency services exist for selected ward, displays "No emergency services available"
- If user selects a ward with no services, graceful empty state shown

## Testing Checklist

- [ ] Ward dropdown appears on home screen
- [ ] Wards load from backend successfully
- [ ] Can select different wards from dropdown
- [ ] Selected ward shows with checkmark and in header
- [ ] Emergency services filter by selected ward
- [ ] Ward name appears in emergency services app bar
- [ ] Works on phone, tablet, and landscape orientations
- [ ] Handles no wards returned from backend gracefully
- [ ] Handles no services for selected ward gracefully

## Future Enhancements

Possible improvements:
- Ward search/filter if list is very long
- Ward history (recently selected wards)
- Location-based ward auto-selection
- Ward favorites
- Map view of wards
