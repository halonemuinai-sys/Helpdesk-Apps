import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiClient {
  static const String _urlKey = 'helpdesk_api_url';
  
  // Default URL based on environment
  static String get defaultBaseUrl {
    return AppConfig.apiUrl;
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_urlKey);
    
    // Automatically clear outdated or placeholder URLs to ensure fallback to the current default
    if (savedUrl != null && (
        savedUrl.contains('yourdomain.com') ||
        savedUrl.contains('vercel.app') ||
        (kReleaseMode && savedUrl.contains('localhost'))
    )) {
      await prefs.remove(_urlKey);
      return defaultBaseUrl;
    }
    
    return savedUrl ?? defaultBaseUrl;
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
