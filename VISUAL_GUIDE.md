# Ward Selection Feature - Visual Guide

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CITIZEN USER                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Flutter App - Emergency Services Screen            │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  🔴 App Bar: "Emergency Services"                      │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ 📍 Select Ward        [NEW - This was added]           │    │
│  │ ┌──────────────────────────────────────────────────┐   │    │
│  │ │ ▼ All Wards              [Dropdown menu]        │   │    │
│  │ │                                                  │   │    │
│  │ │ All Wards                                        │   │    │
│  │ │ Ward 1: Downtown                                │   │    │
│  │ │ Ward 2: Suburbs                                 │   │    │
│  │ │ Ward 3: Industrial Area                         │   │    │
│  │ │ Ward 4: Residential                             │   │    │
│  │ └──────────────────────────────────────────────────┘   │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │          🚨 EMERGENCY SOS                              │    │
│  │              CALL 112                                  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Quick Dial                                             │    │
│  │ [Police] [Fire] [Ambulance] [Women] [Child] [Disaster]│    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Local Services                                         │    │
│  │ ├─ City Hospital (Phone: 9876543210) [CALL]          │    │
│  │ ├─ Fire Station 5 (Phone: 9876543211) [CALL]         │    │
│  │ ├─ Police Station (Phone: 9876543212) [CALL]         │    │
│  │ └─ Ambulance (Phone: 9876543213) [CALL]              │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (When ward selected)
                   User clicks "Ward 1: Downtown"
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Mobile App State Update                       │
│                                                                  │
│  _selectedWardId = 1  (changed from null)                       │
│  _onWardChanged(1) called                                       │
│  setState() triggered                                           │
│  API call: loadEmergencyServices(wardId: 1)                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  API Server (FastAPI Backend)                   │
│                                                                  │
│  GET /emergency?ward_id=1                                       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ Check User Role                                      │      │
│  │ If CITIZEN: Can request any ward ✓                  │      │
│  └──────────────────────────────────────────────────────┘      │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ Query Database                                       │      │
│  │ WHERE is_active = 'Y'                               │      │
│  │ AND (ward_id = 1 OR is_citywide = True)            │      │
│  └──────────────────────────────────────────────────────┘      │
│                              │                                  │
│                              ▼                                  │
│  Returns: [                                                     │
│    {id: 1, name: "City Hospital", ward_id: 1},                │
│    {id: 2, name: "Emergency Police", is_citywide: true},      │
│    {id: 3, name: "Ambulance Service", ward_id: 1}             │
│  ]                                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│           Flutter App - Services List Updated                   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ 📍 Select Ward                                         │    │
│  │ ▼ Ward 1: Downtown  [Selected ✓]                      │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Local Services (Ward 1)                                │    │
│  │ ├─ City Hospital                                       │    │
│  │ │   Phone: 9876543210                [CALL]          │    │
│  │ │   Address: Hospital Road, Downtown                  │    │
│  │ │                                                      │    │
│  │ ├─ Emergency Police (Citywide)                        │    │
│  │ │   Phone: 100                      [CALL]          │    │
│  │ │                                                      │    │
│  │ └─ Ambulance Service                                  │    │
│  │     Phone: 102                      [CALL]          │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
Citizen App
    │
    ├─ Emergency Services Screen
    │   │
    │   ├─ [Load] AuthProvider.loadWards()
    │   │   └─→ API: GET /wards
    │   │       └─→ Returns: [Ward1, Ward2, Ward3, ...]
    │   │
    │   ├─ UI: Show Ward Selector
    │   │   └─→ Default: null (All Wards)
    │   │
    │   └─ [Load] ServicesProvider.loadEmergencyServices(wardId: null)
    │       └─→ API: GET /emergency?ward_id=null
    │           └─→ Returns: [Service1, Service2, Service3, ...]
    │
    ├─ User Selects: "Ward 2: Suburbs"
    │   │
    │   └─→ _onWardChanged(2) triggered
    │       │
    │       ├─ setState() { _selectedWardId = 2 }
    │       │
    │       └─ ServicesProvider.loadEmergencyServices(wardId: 2)
    │           └─→ API: GET /emergency?ward_id=2
    │               └─→ Returns: [Service for Ward2, Citywide...]
    │
    └─ UI: Services List Updates
        └─→ Show services from Ward 2
```

---

## User Journey Flowchart

### Citizen's Journey

```
                    ┌─────────────────┐
                    │   Citizen App   │
                    │     Opened      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Home Screen    │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │ Emergency   │ │
                    │ │ Services    │ │
                    │ └────────┬────┘ │
                    │          │      │
                    │ [Others] │      │
                    └──────────┼──────┘
                               │
                               ▼
                    ┌─────────────────────────────┐
                    │ Emergency Services Screen   │
                    │                             │
                    │ ┌─────────────────────┐    │
                    │ │ Select Ward         │    │
                    │ │ ▼ [All Wards]      │    │
                    │ │  [Ward 1]           │    │
                    │ │  [Ward 2] ◄─ User   │    │
                    │ │  [Ward 3]   Selects │    │
                    │ └────────┬─────────┘    │
                    └──────────┼──────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │ Services Listed │
                    │ for Ward 2      │
                    │                 │
                    │ ┌───────────┐   │
                    │ │ Service 1 │   │
                    │ │ [CALL]    │   │
                    │ └───────────┘   │
                    │ ┌───────────┐   │
                    │ │ Service 2 │   │
                    │ │ [CALL]    │   │
                    │ └───────────┘   │
                    └─────────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
            ▼              ▼              ▼
        [CALL]         [EMAIL]        [MAPS]
```

### Complaint Filing Journey (UNCHANGED)

```
                    ┌──────────────────┐
                    │  Citizen App     │
                    │  Home Screen     │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ File Complaint   │
                    │  Screen          │
                    └────────┬─────────┘
                             │
              ┌──────────────────────────┐
              │  Info Card Shows:        │
              │  "Your complaint will   │
              │   be filed in Ward 1"   │
              │  (Auto-assigned)        │
              └──────────────────────────┘
              │
              ▼
        ┌──────────────┐
        │   Can NOT    │
        │   Change     │
        │   Ward       │
        │   Here ✗     │
        └──────────────┘
              │
              ▼
        [File Complaint]
              │
              ▼
        Complaint Created
        ward_id = User's Ward (enforced by backend)
```

---

## API Request/Response Diagrams

### Request 1: Load All Wards' Services

```
REQUEST:
┌──────────────────────────────────┐
│ GET /emergency                   │
│                                  │
│ Headers:                         │
│ Authorization: Bearer token      │
│                                  │
│ Query Parameters:                │
│ (none - defaults to all wards)   │
│                                  │
│ User Role: CITIZEN               │
└──────────────────────────────────┘
         │
         ▼
PROCESSING:
┌──────────────────────────────────┐
│ if current_user.role == CITIZEN: │
│    if ward_id:                   │
│        filter by ward_id         │
│    else:                         │
│        show all services ✓       │
└──────────────────────────────────┘
         │
         ▼
RESPONSE:
┌──────────────────────────────────┐
│ 200 OK                           │
│                                  │
│ {                                │
│   "services": [                  │
│     {                            │
│       "id": 1,                   │
│       "name": "Hospital",        │
│       "ward_id": 1,              │
│       "is_citywide": false       │
│     },                           │
│     {                            │
│       "id": 2,                   │
│       "name": "Police",          │
│       "ward_id": null,           │
│       "is_citywide": true        │
│     }                            │
│   ]                              │
│ }                                │
└──────────────────────────────────┘
```

### Request 2: Load Specific Ward's Services

```
REQUEST:
┌────────────────────────────────────┐
│ GET /emergency?ward_id=3            │
│                                     │
│ Headers:                            │
│ Authorization: Bearer token         │
│                                     │
│ Query Parameters:                   │
│ ward_id: 3                          │
│                                     │
│ User Role: CITIZEN                  │
└────────────────────────────────────┘
         │
         ▼
PROCESSING:
┌────────────────────────────────────┐
│ if current_user.role == CITIZEN:    │
│    if ward_id:                      │
│        filter by ward_id == 3 ✓    │
│        include citywide             │
│    else:                            │
│        show all services            │
└────────────────────────────────────┘
         │
         ▼
RESPONSE:
┌────────────────────────────────────┐
│ 200 OK                              │
│                                     │
│ {                                   │
│   "services": [                     │
│     {                               │
│       "id": 10,                     │
│       "name": "Fire Station 3",     │
│       "ward_id": 3,                 │
│       "type": "FIRE"                │
│     },                              │
│     {                               │
│       "id": 5,                      │
│       "name": "Central Police",     │
│       "is_citywide": true           │
│     }                               │
│   ]                                 │
│ }                                   │
└────────────────────────────────────┘
```

---

## Screen Mock-up

### Before (Old Design)

```
╔══════════════════════════════════╗
║  Emergency Services              ║
╠══════════════════════════════════╣
║                                  ║
║  ┌──────────────────────────────┐║
║  │ 🚨 EMERGENCY SOS            ││
║  │    CALL 112                  ││
║  └──────────────────────────────┘║
║                                  ║
║  Quick Dial                      ║
║  [Police] [Fire] [Ambulance]    ║
║  [Women]  [Child] [Disaster]    ║
║                                  ║
║  Local Services                  ║
║  Ward 1 only                     ║
║  ├─ Hospital (9876543210) [CALL]║
║  ├─ Police (100) [CALL]         ║
║  └─ Ambulance (102) [CALL]      ║
║                                  ║
╚══════════════════════════════════╝

❌ No ward selection
❌ Locked to Ward 1
```

### After (New Design)

```
╔══════════════════════════════════╗
║  Emergency Services              ║
╠══════════════════════════════════╣
║                                  ║
║ ┌──────────────────────────────┐║
║ │ 📍 Select Ward               ││
║ │ ▼ All Wards ─────────────┐   ││
║ │   All Wards              │   ││
║ │   Ward 1: Downtown       │   ││
║ │   Ward 2: Suburbs        │   ││
║ │   Ward 3: Industrial     │   ││
║ └──────────────────────────┼───┘║
║                            └────┘║
║                                  ║
║  ┌──────────────────────────────┐║
║  │ 🚨 EMERGENCY SOS            ││
║  │    CALL 112                  ││
║  └──────────────────────────────┘║
║                                  ║
║  Quick Dial                      ║
║  [Police] [Fire] [Ambulance]    ║
║  [Women]  [Child] [Disaster]    ║
║                                  ║
║  Local Services                  ║
║  All Wards                       ║
║  ├─ Hospital Downtown (W1) [CALL]║
║  ├─ Hospital Suburbs (W2) [CALL] ║
║  ├─ Police Dept (Citywide) [CALL]║
║  └─ Ambulance Service (W3) [CALL]║
║                                  ║
╚══════════════════════════════════╝

✅ Ward selector added
✅ Can select any ward
✅ Services update dynamically
```

---

## State Management Diagram

```
EmergencyScreen State
│
├─ _selectedWardId: int?
│  │
│  ├─ null      → "All Wards" selected
│  │
│  └─ 1,2,3,... → Specific ward selected
│
├─ _loadData() method
│  │
│  ├─ Loads wards via authProvider.loadWards()
│  │
│  └─ Loads services via servicesProvider.loadEmergencyServices(wardId: _selectedWardId)
│
└─ _onWardChanged(wardId) method
   │
   ├─ setState({ _selectedWardId = wardId })
   │
   └─ servicesProvider.loadEmergencyServices(wardId: wardId)
      │
      └─ API call with updated wardId parameter


ServicesProvider State
│
└─ _emergencyServices: List<EmergencyService>
   │
   ├─ Updated when loadEmergencyServices() called
   │
   └─ Notifies listeners (UI rebuilds)


AuthProvider State
│
└─ _wards: List<Ward>
   │
   ├─ Loaded once on screen init
   │
   └─ Used to populate dropdown
```

---

## Permission & Access Matrix

```
                    Emergency    File         Track
                    Services     Complaint    Complaint
                    ────────     ─────────    ──────────

CITIZEN:
  View own ward          ✓          -            ✓
  View other wards       ✓ (NEW)    ✗            ✗
  File complaint         -          ✓            -
  Own ward auto-assigned -          ✓            -
  See own complaints     -          -            ✓
  See others' complaints ✗          ✗            ✗
  Select ward            ✓ (NEW)    ✗            ✗

FIELD_OFFICER:
  View own ward          ✓          ✗            -
  View other wards       ✓ (NEW)    ✗            ✗
  File complaint         ✗          ✗            ✗
  See assigned cmplts    ✗          ✗            ✓
  Select ward            ✓ (NEW)    ✗            ✗

WARD_ADMIN:
  View own ward          ✓          ✗            -
  View other wards       ✗          ✗            ✗
  Manage services        ✓          ✗            -
  See ward complaints    ✗          ✗            ✓
  Select ward            ✗          ✗            ✗

SUPER_ADMIN:
  View all wards         ✓          ✗            -
  View all complaints    ✗          ✗            ✓
  Manage all services    ✓          ✗            -
  Select ward            ✓ (opt)    ✗            ✗

Legend: ✓ = Can do, ✗ = Cannot do, - = Not applicable
(NEW) = Changed with this update
```

---

**Visual Guide Complete** - Use these diagrams to understand the system flow, API interactions, and state management!
