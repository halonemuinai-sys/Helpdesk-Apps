import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    checkSession();
  }

  // Set Loading State
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set Error State
  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Check if session is already stored
  Future<void> checkSession() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        _user = jsonDecode(userDataStr);
      }

      if (_token != null) {
        // Validate with server
        final freshProfile = await AuthService.fetchCurrentUserProfile();
        _user = freshProfile;
        notifyListeners();
      }
    } catch (e) {
      _token = null;
      _user = null;
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Handle User Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await AuthService.login(email, password);
      _token = response['token'];
      _user = response['user'];
      notifyListeners();
      return true;
    } catch (e) {
      String cleanErr = e.toString().replaceAll('Exception: ', '');
      _setError(cleanErr);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Handle User Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await AuthService.logout();
      _token = null;
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Clear current error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
