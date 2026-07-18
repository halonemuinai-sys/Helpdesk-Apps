import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _urlKey = 'helpdesk_api_url';
  
  // =========================================================================
  // CHANGE THIS TO YOUR PUBLIC VPS IP OR DOMAIN FOR ONLINE TESTING / APK:
  // Examples: 
  // - 'https://api.helpdesk-mra.com/api'
  // - 'http://103.111.22.33:5000/api' (If using raw VPS IP with port)
  // =========================================================================
  static const String _productionBaseUrl = 'https://api.yourdomain.com/api'; 
  
  // Default URL based on environment and build mode
  static String get defaultBaseUrl {
    // If running on Web, check the actual browser host address.
    // If it's served on localhost/127.0.0.1, route to the local development backend on port 5000.
    if (kIsWeb) {
      final String host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:5000/api';
      }
      return _productionBaseUrl;
    }
    
    // For mobile apps:
    // If compiled for production (Release APK), use the online production VPS URL.
    if (kReleaseMode) {
      return _productionBaseUrl;
    }
    
    // Debug mode local testing fallback for Android Emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api'; 
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
  }

  static Future<Map<String, String>> getHeaders([String? token]) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      if (storedToken != null && storedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $storedToken';
      }
    }
    return headers;
  }
}
