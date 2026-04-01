import 'package:flutter/material.dart';
import 'presentation/auth/views/login_screen.dart';
import 'presentation/desks/views/desk_map_screen.dart';
import 'presentation/admin/views/admin_dashboard.dart';
import 'presentation/admin/views/add_edit_user.dart';
import 'core/constants/app_colors.dart';
import 'data/services/api_service.dart';
import 'domain/entities/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  final apiService = ApiService();
  await apiService.loadToken();
  await apiService.loadUser();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workspace Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.offWhite,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.charcoal,
          titleTextStyle: TextStyle(color: AppColors.charcoal, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.offWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.lightGray, width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryBlue,
          secondary: AppColors.teal,
          error: AppColors.error,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/desk-map': (context) => const DeskMapScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/add-user': (context) => const AddEditUserScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit-user') {
          final user = settings.arguments as User?;
          return MaterialPageRoute(builder: (context) => AddEditUserScreen(user: user));
        }
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      },
      home: const LoginScreen(),
    );
  }
}