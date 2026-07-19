import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'theme/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: MaterialApp(
        title: 'IT Helpdesk MRA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: AppColors.green600,
          scaffoldBackgroundColor: AppColors.green50,
          colorScheme: ColorScheme.light(
            primary: AppColors.green600,
            secondary: AppColors.green500,
            surface: Colors.white,
            error: Colors.redAccent,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.slate900,
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: AppColors.green600),
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          cardColor: Colors.white,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.slate900),
            bodyMedium: TextStyle(color: AppColors.slate700),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // While checking session on cold start, display a beautiful loading screen
    if (auth.isLoading && auth.token == null) {
      return const Scaffold(
        backgroundColor: AppColors.green50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.support_agent_rounded,
                size: 64,
                color: AppColors.green600,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.green600),
              SizedBox(height: 16),
              Text(
                'Memuat Sesi Workspace...',
                style: TextStyle(color: AppColors.slate500, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.needsBiometricUnlock) {
      return const BiometricLockScreen();
    }

    if (auth.isAuthenticated) {
      return const MainNavigation();
    } else {
      return const LoginScreen();
    }
  }
}
