import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swachhata_app/ui/admin/forum/forum_page.dart';

// Import all pages here
import '../../ui/auth/login_page.dart';
import '../../ui/auth/signup_page.dart';
import '../../ui/auth/forgot_password_page.dart';
import '../../ui/user/user_dashboard.dart';
import '../../ui/admin/admin_dashboard.dart';

class AppRouter {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String userDashboard = '/user-dashboard';
  static const String adminDashboard = '/admin-dashboard';

  static Future<String?> _getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return snap.data()?['role'];
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case userDashboard:
        return MaterialPageRoute(builder: (_) => const UserDashboard());
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
              if (snapshot.hasError || snapshot.data != 'admin') {
                return const Scaffold(
                  body: Center(child: Text("Access Denied 🚫")),
                );
              }
              return const AdminDashboard();
            },
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("404 - Page Not Found"))),
        );
    }
  }
}
