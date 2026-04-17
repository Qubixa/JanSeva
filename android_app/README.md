# Nagarseva - NMMC Citizen Services App

A modern, responsive Flutter application for NMMC (Navi Mumbai Municipal Corporation) citizens to access municipal services including emergency services, complaint filing, tracking, and information about schemes, transport, and contacts.

## Features

### Core Features
- **Splash Screen**: Beautiful animated splash screen with app branding
- **Authentication**: Secure login and registration for citizens
- **User Profile**: Manage personal information and view account details

### Citizen Services
- **Emergency Services**: Access ward-specific emergency contacts with quick call functionality
- **File Complaint**: Submit issues with title, description, category, and location
- **Track Complaint**: Monitor complaint status and view resolution notes
- **Schemes & Benefits**: Browse government schemes with eligibility and application details
- **Public Transport**: View bus routes, schedules, and fares
- **Important Contacts**: Access department contacts with phone and email

## Architecture

The app follows a clean architecture pattern with proper separation of concerns:

```
lib/
├── core/
│   ├── constants/          # App colors, typography, and constants
│   ├── models/             # Data models (User, Complaint, Services)
│   ├── providers/          # Business logic (Auth, Complaint, Services)
│   └── services/           # API service for backend communication
├── presentation/
│   ├── screens/            # UI screens organized by feature
│   │   ├── auth/           # Login, Register
│   │   ├── home/           # Home and navigation
│   │   ├── profile/        # User profile
│   │   ├── services/       # Emergency, Schemes, Transport, Contacts
│   │   └── complaints/     # File and Track
│   └── widgets/            # Reusable UI components
└── main.dart              # App entry point
```

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **HTTP Client**: Dio
- **Local Storage**: Shared Preferences
- **UI Components**: Material Design 3
- **Typography**: Google Fonts (Poppins)
- **URL Launcher**: For making calls and opening links

## Setup & Installation

### Prerequisites
- Flutter 3.0 or higher
- Dart SDK
- Android SDK / iOS SDK
- A running Nagarseva backend server

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nagarseva_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API Configuration**
   - Open `lib/core/constants/app_constants.dart`
   - Update `API_BASE_URL` to your backend server URL:
   ```dart
   const String API_BASE_URL = 'http://your-backend-url:8000/api';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

5. **Build APK (for distribution)**
   ```bash
   flutter build apk --release
   ```

## API Integration

The app communicates with the FastAPI backend at the configured `API_BASE_URL`. Key endpoints:

### Authentication
- `POST /auth/login` - Login
- `POST /auth/register` - Register
- `GET /auth/profile` - Get user profile
- `POST /auth/logout` - Logout

### Complaints
- `GET /complaints/categories` - Get complaint categories
- `POST /complaints/create` - File complaint
- `GET /complaints/my` - Get user's complaints
- `GET /complaints/{id}` - Get complaint details

### Services
- `GET /services/emergency` - Get emergency services
- `GET /services/schemes` - Get schemes
- `GET /services/transport` - Get transport routes
- `GET /services/contacts` - Get important contacts

## Design System

The app uses a modern color scheme:
- **Primary**: #1A73E8 (Blue)
- **Secondary**: #34A853 (Green)
- **Accent**: #EA4335 (Red)
- **Typography**: Poppins font family

## Responsive Design

The app is fully responsive and works across all screen sizes:
- Mobile phones (320dp - 600dp)
- Tablets (600dp+)
- Landscape and portrait orientations

## Project Structure

### Models
- `user_model.dart` - User and authentication models
- `complaint_model.dart` - Complaint data model
- `service_models.dart` - Emergency Services, Schemes, Transport, Contact models

### Providers
- `auth_provider.dart` - Authentication and user management
- `complaint_provider.dart` - Complaint operations
- `services_provider.dart` - Services and information management

### Screens
- `splash_screen.dart` - App initialization and routing
- `login_screen.dart` - User authentication
- `register_screen.dart` - New user registration
- `home_screen.dart` - Main navigation and quick actions
- `profile_screen.dart` - User profile management
- `emergency_services_screen.dart` - Emergency contacts
- `file_complaint_screen.dart` - File new complaint
- `track_complaint_screen.dart` - Track complaints
- `schemes_screen.dart` - Government schemes
- `transport_screen.dart` - Public transport
- `contacts_screen.dart` - Important contacts

### Widgets
- `custom_button.dart` - Reusable button component
- `custom_text_field.dart` - Input field component
- `loading_dialog.dart` - Loading indicator dialog
- `action_card.dart` - Quick action card for home screen

## Key Features Implementation

### Authentication Flow
1. Splash screen checks if user is logged in
2. Routes to login if not authenticated
3. On login/register, token and user data are saved locally
4. Token is automatically included in all API requests
5. Logout clears all stored data

### Complaint Management
1. Categories are fetched dynamically from backend (no hardcoded values)
2. Users can file complaints with title, description, category, and location
3. Complaints are automatically assigned to user's ward
4. Users can track their complaints and view status updates
5. Real-time status tracking with resolution notes

### Services
1. Emergency services are ward-specific
2. Direct calling functionality integrated
3. Schemes include benefits, eligibility, and application process
4. Transport routes with schedules and fares
5. Important contacts with multiple communication options

## Security Features

- JWT token-based authentication
- Secure token storage in shared preferences
- Automatic token refresh on API calls
- Protected routes based on authentication status
- Form validation and sanitization
- HTTPS support ready

## Performance Optimizations

- Lazy loading of screens
- Efficient state management with Provider
- Image caching
- Responsive layouts
- Minimal widget rebuilds

## Future Enhancements

- Offline support with local database
- Push notifications for complaint updates
- Image upload for complaints
- Real-time location tracking
- Payment gateway integration
- Multi-language support
- Dark mode support
- Complaint filtering and search

## Troubleshooting

### API Connection Issues
- Ensure backend server is running
- Check `API_BASE_URL` is correct
- Verify network connectivity
- Check firewall/proxy settings

### Build Issues
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK is up to date
- Check Android SDK version compatibility

### Runtime Errors
- Check logs with `flutter logs`
- Verify permissions in AndroidManifest.xml
- Ensure backend is responding correctly

## Support

For issues or questions:
1. Check the logs using `flutter logs`
2. Verify backend server is running
3. Ensure API_BASE_URL is correctly configured
4. Check internet connectivity

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Version**: 1.0.0  
**Last Updated**: January 2026  
**Built with Flutter 3.0+**
