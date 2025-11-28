import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? currentUser;
  bool isLoading = false;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      currentUser = user;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.loginUser(email: email, password: password);

      // 👇 Force set currentUser again (critical fix)
      currentUser = FirebaseAuth.instance.currentUser;

      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.registerUser(
        name: name,
        email: email,
        password: password,
      );

      // 👇 Force refresh after signup
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }
}
