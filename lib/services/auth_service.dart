import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  // Login to Helpdesk Backend
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/auth/login');
    
    final response = await http.post(
      url,
      headers: await ApiClient.getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final String? token = responseData['token'];
      final Map<String, dynamic>? userData = responseData['user'];
      
      if (token == null || userData == null) {
        throw Exception('Invalid server response: Missing token or user data.');
      }

      final String role = userData['role'] ?? 'USER';
      
      // Enforce Role Limitation: only AGENT, ADMIN, or AUDITOR can enter mobile app
      if (role != 'AGENT' && role != 'ADMIN' && role != 'AUDITOR') {
        throw Exception('Akses ditolak. Karyawan biasa tidak diperbolehkan masuk ke dashboard IT.');
      }

      // Save token and user info locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(userData));
      
      return responseData;
    } else {
      final String errorMsg = responseData['error'] ?? 'Login gagal. Coba lagi.';
      throw Exception(errorMsg);
    }
  }

  // Get current user profile and verify token
  static Future<Map<String, dynamic>> fetchCurrentUserProfile() async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/auth/me');

    final response = await http.get(
      url,
      headers: await ApiClient.getHeaders(),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
      return userData;
    } else {
      throw Exception('Sesi telah kedaluwarsa. Silakan login kembali.');
    }
  }

  // Check if user is already logged in and session is active
  static Future<Map<String, dynamic>?> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userDataString = prefs.getString('user_data');

    if (token == null || token.isEmpty || userDataString == null) {
      return null;
    }

    try {
      // Validate token with server
      final freshProfile = await fetchCurrentUserProfile();
      return freshProfile;
    } catch (e) {
      // Token is invalid/expired, clear session
      await logout();
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
}
