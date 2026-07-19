import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _biometricPrefKey = 'biometric_login_enabled';

  Map<String, dynamic>? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _biometricEnabled = false;
  bool _isUnlocked = false;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;
  bool get biometricEnabled => _biometricEnabled;

  // True when a session exists but the biometric gate hasn't been passed yet this app run
  bool get needsBiometricUnlock => isAuthenticated && _biometricEnabled && !_isUnlocked;

  AuthProvider() {
    checkSession();
  }

  void unlock() {
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _biometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricPrefKey, value);
    if (value) {
      // Enabling from within an already-unlocked session shouldn't re-lock it
      _isUnlocked = true;
    }
    notifyListeners();
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
      _biometricEnabled = prefs.getBool(_biometricPrefKey) ?? false;
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
      _isUnlocked = true; // A fresh password login already proves identity this run
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
      _isUnlocked = false;
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
