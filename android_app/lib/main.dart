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
import 'presentation/screens/matrimonial/user_registration_screen.dart';

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
        '/matrimonial': (context) => const MatrimonialHomeScreen(),
        '/matrimonial/user-register': (context) => const UserRegistrationScreen(),
      },
    );
  }
}
