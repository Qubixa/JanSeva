# Nagarseva Flutter App - Complete Setup Guide

## Quick Start

This is a complete, production-ready Flutter application for NMMC Nagarseva citizen services. Follow this guide to get up and running.

## Prerequisites

1. **Flutter SDK**: Download from [flutter.dev](https://flutter.dev)
   ```bash
   flutter --version  # Should be 3.0 or higher
   ```

2. **Dart SDK**: Included with Flutter

3. **Android Studio** or **VS Code** with Flutter extension

4. **Backend Server**: Your FastAPI Nagarseva backend running on a server

## Step 1: Project Setup

### Clone or Extract Project
```bash
cd nagarseva_app
```

### Install Dependencies
```bash
flutter pub get
```

## Step 2: Configure Backend URL

This is the most important step!

1. Open `lib/core/constants/app_constants.dart`

2. Find this line:
   ```dart
   const String API_BASE_URL = 'http://your-backend-url:8000/api';
   ```

3. Replace with your actual backend URL:

   **For Local Development (same machine as emulator):**
   ```dart
   const String API_BASE_URL = 'http://10.0.2.2:8000/api';
   ```

   **For Local Development (physical device on same network):**
   ```dart
   const String API_BASE_URL = 'http://192.168.1.100:8000/api';  // Replace with your IP
   ```

   **For Production:**
   ```dart
   const String API_BASE_URL = 'https://your-production-server.com/api';
   ```

4. Save the file

## Step 3: Run the App

### On Android Emulator
```bash
flutter emulators
flutter emulators launch Pixel_4_API_30  # or your emulator
flutter run
```

### On Physical Android Device
1. Enable Developer Mode on your device
2. Enable USB Debugging
3. Connect via USB
4. Run:
   ```bash
   flutter run
   ```

### On iOS (if using macOS)
```bash
flutter run -d iPhone
```

## Step 4: Test Features

### Login Flow
1. **First Time**: Click "Sign Up" to create an account
   - Enter: Name, Email, Phone (10 digits), Password
   - App automatically assigns you as a CITIZEN
   
2. **Existing User**: Use your credentials to login

### Test Data
- Email: `citizen@example.com`
- Password: `password123`
- Phone: `9876543210`

### Features to Test
- **Home Screen**: All quick action cards
- **Emergency Services**: View ward-specific emergency contacts
- **File Complaint**: Submit a new complaint
- **Track Complaint**: View complaint status
- **Schemes**: Browse available schemes
- **Transport**: Check public transport routes
- **Contacts**: View important contacts

## Project Structure Overview

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # API URLs and constants
│   │   ├── app_colors.dart          # Color scheme
│   │   └── app_typography.dart      # Font styles
│   ├── models/
│   │   ├── user_model.dart          # User & Auth models
│   │   ├── complaint_model.dart     # Complaint data
│   │   └── service_models.dart      # Services data
│   ├── providers/
│   │   ├── auth_provider.dart       # Auth state management
│   │   ├── complaint_provider.dart  # Complaint operations
│   │   └── services_provider.dart   # Services operations
│   └── services/
│       └── api_service.dart         # HTTP client setup
└── presentation/
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   └── register_screen.dart
    │   ├── home/
    │   │   └── home_screen.dart
    │   ├── profile/
    │   │   └── profile_screen.dart
    │   ├── services/
    │   │   ├── emergency_services_screen.dart
    │   │   ├── schemes_screen.dart
    │   │   ├── transport_screen.dart
    │   │   └── contacts_screen.dart
    │   ├── complaints/
    │   │   ├── file_complaint_screen.dart
    │   │   └── track_complaint_screen.dart
    │   └── splash_screen.dart
    └── widgets/
        ├── custom_button.dart
        ├── custom_text_field.dart
        └── loading_dialog.dart
```

## How It Works

### Authentication Flow
1. **Splash Screen** (3 seconds)
   - Checks if user is already logged in
   - Redirects to Home (if logged in) or Login (if not)

2. **Login/Register**
   - Uses JWT token-based authentication
   - Token stored locally in SharedPreferences
   - Automatically included in all API requests

3. **Home Screen**
   - Shows user greeting with ward information
   - Quick action tiles for all features
   - Logout button in app bar

### Data Flow
- **API Service**: Handles all HTTP requests with automatic token injection
- **Providers**: Manage business logic and state
- **Screens**: Display UI and trigger provider actions
- **Local Storage**: Caches token and user data

### Key Features

#### Emergency Services
- Fetches ward-specific services
- One-tap calling functionality
- Displays address, phone, category

#### Complaints
- **Categories**: Dynamically fetched from backend (no hardcoding)
- **Filing**: Title, description, category, location
- **Tracking**: View status, resolution notes
- **Status**: Open → In Progress → Resolved → Closed

#### Services
- **Schemes**: Benefits, eligibility, application process
- **Transport**: Routes, schedules, fares
- **Contacts**: Department info, phone, email, address

## Building for Production

### Create Release APK
```bash
flutter build apk --release
```

### Create App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```

Output location: `build/app/outputs/`

### Configure App Signing
1. Create a keystore file
2. Configure in `android/key.properties`
3. Update `android/app/build.gradle`

## Important Backend Requirements

Your FastAPI backend must implement these endpoints:

### Authentication
- `POST /api/auth/login`
- `POST /api/auth/register`
- `GET /api/auth/profile`
- `POST /api/auth/logout`

### Complaints
- `GET /api/complaints/categories`
- `POST /api/complaints/create`
- `GET /api/complaints/my`
- `GET /api/complaints/{id}`

### Services
- `GET /api/services/emergency`
- `GET /api/services/schemes`
- `GET /api/services/transport`
- `GET /api/services/contacts`

All endpoints should accept `Authorization: Bearer {token}` header.

## Troubleshooting

### "Connection Refused" Error
- **Cause**: Backend server not running or wrong URL
- **Solution**: Check API_BASE_URL and ensure backend is running
  ```bash
  # Test backend connection
  curl http://your-backend-url:8000/api/health
  ```

### "Invalid Token" Error
- **Cause**: Outdated or corrupted token
- **Solution**: Logout and login again

### "CORS Error"
- **Cause**: Backend CORS not configured
- **Solution**: Add CORS headers to your FastAPI backend:
  ```python
  from fastapi.middleware.cors import CORSMiddleware
  app.add_middleware(CORSMiddleware, allow_origins=["*"])
  ```

### App Crashing on Startup
- Run: `flutter clean && flutter pub get && flutter run`
- Check logs: `flutter logs`

### Emulator Network Issues
- Restart emulator
- Check emulator internet settings
- Try with `10.0.2.2` instead of `localhost`

## Performance Tips

1. **Disable Debug Mode**: Use `--release` flag when building
2. **Optimize Images**: Use appropriate image sizes
3. **Lazy Loading**: Screens are lazily loaded on navigation
4. **Caching**: Tokens and user data are cached locally

## Security Checklist

- ✅ Use HTTPS in production
- ✅ Implement rate limiting on backend
- ✅ Validate all user inputs
- ✅ Use secure token storage
- ✅ Implement token refresh logic
- ✅ Add CORS protection
- ✅ Never hardcode API keys
- ✅ Use HTTPS for all API calls

## Customization Guide

### Change App Colors
Edit `lib/core/constants/app_colors.dart`

### Change Fonts
Edit `pubspec.yaml` and `lib/core/constants/app_typography.dart`

### Add New Screens
1. Create screen in `lib/presentation/screens/`
2. Add route in `lib/main.dart`
3. Add navigation in home screen

### Add New API Endpoints
1. Add method in `lib/core/services/api_service.dart`
2. Create provider in `lib/core/providers/`
3. Use in screens

## Testing Checklist

- [ ] Splash screen displays and transitions correctly
- [ ] Login/Register forms validate inputs
- [ ] Authentication tokens are stored and used
- [ ] Home screen loads with user data
- [ ] Emergency services load and call works
- [ ] Can file complaint with all fields
- [ ] Can track complaints
- [ ] Schemes, transport, contacts display correctly
- [ ] Logout clears all data
- [ ] App handles network errors gracefully
- [ ] Responsive on different screen sizes
- [ ] Landscape orientation works

## Version History

- **v1.0.0** (January 2026): Initial release
  - Complete authentication system
  - All core features implemented
  - Responsive design
  - Production-ready

## Support & Debugging

### Enable Debug Logging
Add to `lib/core/services/api_service.dart`:
```dart
_dio.interceptors.add(LoggingInterceptor());  // Add logging
```

### Check Network
```bash
flutter run -v  # Verbose logging
```

### View Logs
```bash
flutter logs
```

## Next Steps

1. ✅ Configure API URL
2. ✅ Test on emulator/device
3. ✅ Test all features with backend
4. ✅ Build APK for distribution
5. ✅ Submit to Google Play Store (if applicable)

## Need Help?

1. Check README.md for feature documentation
2. Review code comments in main files
3. Check Flutter/Dart documentation: [flutter.dev](https://flutter.dev)
4. Review your backend API logs for errors
5. Use `flutter doctor -v` to check environment

---

**Happy coding! Your Nagarseva app is ready to serve citizens!** 🚀
