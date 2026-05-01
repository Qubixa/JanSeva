import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/services/api_service.dart';
import 'core/services/home_content_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/complaint_provider.dart';
import 'core/providers/services_provider.dart';
import 'core/providers/matrimonial_provider.dart';
import 'core/providers/notification_provider.dart';  // ADD THIS
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/services/emergency_services_screen.dart';
import 'presentation/screens/services/schemes_screen.dart';
import 'presentation/screens/services/transport_screen.dart';
import 'presentation/screens/services/contacts_screen.dart';
import 'presentation/screens/complaints/file_complaint_screen.dart';
import 'presentation/screens/complaints/track_complaint_screen.dart';
import 'presentation/screens/matrimonial/matrimonial_home_screen.dart';
import 'presentation/screens/matrimonial/individual_registration_screen.dart';
import 'presentation/screens/matrimonial/agency_registration_screen.dart';
import 'presentation/screens/matrimonial/users_list_screen.dart';
import 'presentation/screens/matrimonial/agencies_list_screen.dart';
import 'presentation/screens/matrimonial/profile_detail_screen.dart';
import 'presentation/screens/matrimonial/my_matches_screen.dart';
// ADD NOTIFICATION IMPORTS
import 'presentation/notifications/all_notices_screen.dart';
import 'presentation/notifications/notification_detail_screen.dart';
import 'presentation/screens/complaints/complaint_detail_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = ApiService();
  await apiService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        Provider<HomeContentService>(create: (_) => HomeContentService(apiService)),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)..initialize()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ServicesProvider(apiService)),
        ChangeNotifierProvider(create: (_) => MatrimonialProvider(apiService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(apiService)), // ADD THIS
      ],
      child: const NagarsevApp(),
    ),
  );
}

class NagarsevApp extends StatelessWidget {
  const NagarsevApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nagarseva',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: AppTypography.getTextTheme(),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/emergency-services': (context) => const EmergencyServicesScreen(),
        '/schemes': (context) => const SchemesScreen(),
        '/transport': (context) => const TransportScreen(),
        '/contacts': (context) => const ContactsScreen(),
        '/file-complaint': (context) => const FileComplaintScreen(),
        '/track-complaint': (context) => const TrackComplaintScreen(),
        '/complaint-detail': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return ComplaintDetailScreen(complaintId: id);
        },
        // Matrimonial Routes
        '/matrimonial': (context) => const MatrimonialHomeScreen(),
        '/matrimonial/individual-register': (context) => const IndividualRegistrationScreen(),
        '/matrimonial/agency-register': (context) => const AgencyRegistrationScreen(),
        '/matrimonial/users-list': (context) => const MatrimonialUsersListScreen(),
        '/matrimonial/agencies-list': (context) => const MatrimonialAgenciesListScreen(),
        '/matrimonial/my-matches': (context) => const MyMatchesScreen(),
        
        // Notification Routes - REMOVE const since widgets are not constant
        '/notices': (context) => const AllNoticesScreen(), // const is fine here
      },
      onGenerateRoute: (settings) {
  // Handle matrimonial dynamic routes
  if (settings.name?.startsWith('/matrimonial/profile/') == true) {
    final id = int.parse(settings.name!.split('/').last);
    return MaterialPageRoute(
      builder: (context) => MatrimonialProfileDetailScreen(profileId: id),
    );
  }
  
  // Handle notification detail routes - Updated to work with the new constructor
  if (settings.name?.startsWith('/notice/') == true) {
    final id = int.parse(settings.name!.split('/').last);
    return MaterialPageRoute(
      builder: (context) => NotificationDetailScreen(noticeId: id),
    );
  }
  
  // Optional: Add a 404 page for unknown routes
  return MaterialPageRoute(
    builder: (context) => const Scaffold(
      body: Center(child: Text('Page not found')),
    ),
  );
},
    );
  }
}