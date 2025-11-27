import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import all pages
import '../../ui/auth/login_page.dart';
import '../../ui/auth/signup_page.dart';
import '../../ui/auth/forgot_password_page.dart';
import '../../ui/user/user_dashboard.dart';
import '../../ui/admin/admin_dashboard.dart';
import '../../ui/driver/driver_dashboard.dart';
import '../ui/driver/start_service.dart';

class AppRouter {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String userDashboard = '/user-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String driverDashboard = '/driver-dashboard';
  static const String driverWorkTracking = '/driver-work-tracking';

  /// Fetch CURRENT Firebase user role
  static Future<String?> _getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // 1️⃣ Check in USERS collection (admin/user)
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userSnap.exists) {
      return userSnap.data()?['role']; // admin / user
    }

    // 2️⃣ Check in DRIVERS collection
    final driverSnap = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(user.uid)
        .get();

    if (driverSnap.exists) {
      return 'driver';
    }

    // Not found anywhere
    return null;
  }

  /// ROUTE GENERATOR
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ------------------------------
      // LOGIN / SIGNUP PAGES
      // ------------------------------
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      // ------------------------------
      // USER DASHBOARD
      // ------------------------------
      case userDashboard:
        return MaterialPageRoute(builder: (_) => const UserDashboard());

      // ------------------------------
      // ADMIN DASHBOARD WITH ROLE CHECK
      // ------------------------------
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => FutureBuilder<String?>(
            future: _getCurrentUserRole(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data != 'admin') {
                return const Scaffold(
                  body: Center(child: Text("Access Denied 🚫")),
                );
              }
              return const AdminDashboard();
            },
          ),
        );

      // ------------------------------
      // DRIVER DASHBOARD (⚡ SPECIAL HANDLING)
      // ------------------------------
      case driverDashboard:
        return MaterialPageRoute(
          builder: (_) => FutureBuilder<String?>(
            future: _getCurrentUserRole(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data != 'driver') {
                return const Scaffold(
                  body: Center(child: Text("Access Denied 🚫")),
                );
              }
              return const DriverDashboard();
            },
          ),
        );

      // ------------------------------
      // UNKNOWN ROUTE
      // ------------------------------
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("404 - Page Not Found"))),
        );
    }
  }
}
