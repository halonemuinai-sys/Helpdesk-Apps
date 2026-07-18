import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class TicketService {
  // Fetch tickets with filters
  static Future<List<dynamic>> fetchTickets({
    String? status,
    String? priority,
    String? companyId,
    String? search,
  }) async {
    final baseUrl = await ApiClient.getBaseUrl();
    
    // Build query params
    final Map<String, String> queryParams = {};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (priority != null && priority.isNotEmpty) queryParams['priority'] = priority;
    if (companyId != null && companyId.isNotEmpty) queryParams['companyId'] = companyId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/tickets').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: await ApiClient.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Gagal memuat tiket.');
    }
  }

  // Fetch ticket details by ID
  static Future<Map<String, dynamic>> fetchTicketById(String id) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/tickets/$id');

    final response = await http.get(
      url,
      headers: await ApiClient.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Detail tiket tidak ditemukan.');
    }
  }

  // Create new ticket
  static Future<Map<String, dynamic>> createTicket(Map<String, dynamic> ticketData) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/tickets');

    final response = await http.post(
      url,
      headers: await ApiClient.getHeaders(),
      body: jsonEncode(ticketData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Gagal membuat tiket baru.');
    }
  }

  // Update ticket status (e.g. IN_PROGRESS, PENDING, RESOLVED)
  static Future<Map<String, dynamic>> updateStatus(String ticketId, String status, {String? comment}) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/tickets/$ticketId/status');

    final response = await http.patch(
      url,
      headers: await ApiClient.getHeaders(),
      body: jsonEncode({
        'status': status,
        'comment': comment ?? '',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Gagal memperbarui status tiket.');
    }
  }

  // Assign ticket to agent
  static Future<Map<String, dynamic>> assignTicket(String ticketId, String agentId) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/tickets/$ticketId/assign');

    final response = await http.patch(
      url,
      headers: await ApiClient.getHeaders(),
      body: jsonEncode({
        'assignedToId': agentId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Gagal menugaskan tiket.');
    }
  }

  // Update ticket priority
  static Future<Map<String, dynamic>> updatePriority(String ticketId, String priority) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/tickets/$ticketId/priority');

    final response = await http.patch(
      url,
      headers: await ApiClient.getHeaders(),
      body: jsonEncode({
        'priority': priority,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Gagal mengubah prioritas tiket.');
    }
  }

  // Update ticket category metadata
  static Future<Map<String, dynamic>> updateMeta(String ticketId, {
    required String category,
    required String subCategory,
    required String source,
  }) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/tickets/$ticketId/meta');

    final response = await http.patch(
      url,
      headers: await ApiClient.getHeaders(),
      body: jsonEncode({
        'category': category,
        'subCategory': subCategory,
        'source': source,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Gagal memperbarui metadata tiket.');
    }
  }

  // Get ticket categories
  static Future<List<dynamic>> fetchCategories() async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/tickets/categories');

    final response = await http.get(
      url,
      headers: await ApiClient.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat kategori.');
    }
  }

  // Get branches / companies
  static Future<List<dynamic>> fetchCompanies() async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/companies');

    final response = await http.get(
      url,
      headers: await ApiClient.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat data perusahaan.');
    }
  }

  // Search users for requester autocomplete
  static Future<List<dynamic>> searchUsers(String query) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final url = Uri.parse('$baseUrl/users?search=${Uri.encodeComponent(query)}');

    final response = await http.get(
      url,
      headers: await ApiClient.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mencari karyawan.');
    }
  }

  // Fetch all agents (for assigning tickets)
  static Future<List<dynamic>> fetchAgents() async {
    final baseUrl = await ApiClient.getBaseUrl();
    
    // We fetch users with AGENT and ADMIN roles
    final agentUrl = Uri.parse('$baseUrl/users?role=AGENT');
    final adminUrl = Uri.parse('$baseUrl/users?role=ADMIN');

    final headers = await ApiClient.getHeaders();
    
    final responses = await Future.wait([
      http.get(agentUrl, headers: headers),
      http.get(adminUrl, headers: headers),
    ]);

    final List<dynamic> allAgents = [];
    final Set<String> ids = {};

    for (var response in responses) {
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        for (var u in users) {
          if (!ids.contains(u['id'])) {
            ids.add(u['id']);
            allAgents.add(u);
          }
        }
      }
    }

    return allAgents..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  // Server-Sent Events (SSE) Listener Connection Manager
  static Future<SseConnection> openEventsConnection(String token) async {
    final baseUrl = await ApiClient.getBaseUrl();
    final sseUrl = '$baseUrl/tickets/events';
    
    final conn = SseConnection(url: sseUrl, token: token);
    conn.connect();
    return conn;
  }
}

// Custom Client-Side SSE Subscriber class for Dart
class SseConnection {
  final String url;
  final String token;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  HttpClient? _client;
  HttpClientRequest? _request;
  HttpClientResponse? _response;
  bool _isClosed = false;

  SseConnection({required this.url, required this.token});

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect() async {
    while (!_isClosed) {
      try {
        _client = HttpClient();
        // Give 10 seconds connecting timeout, keep-alive stays open indefinitely
        _client!.connectionTimeout = const Duration(seconds: 10);
        
        final uri = Uri.parse(url);
        _request = await _client!.getUrl(uri);
        
        // SSE standard headers
        _request!.headers.set('Accept', 'text/event-stream');
        _request!.headers.set('Cache-Control', 'no-cache');
        _request!.headers.set('Authorization', 'Bearer $token');
        
        _response = await _request!.close();
        
        if (_response!.statusCode == 200) {
          // Listen to the response stream line by line
          final lineStream = _response!
              .transform(utf8.decoder)
              .transform(const LineSplitter());
              
          await for (final line in lineStream) {
            if (_isClosed) break;
            
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6).trim();
              if (jsonStr.isNotEmpty) {
                try {
                  final data = jsonDecode(jsonStr);
                  _controller.add(data);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error decoding SSE payload: $e');
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('SSE stream connection error: $e. Retrying in 5 seconds...');
        }
      } finally {
        _client?.close();
      }
      
      if (!_isClosed) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }

  void close() {
    _isClosed = true;
    try {
      _request?.abort();
    } catch (_) {}
    try {
      _client?.close(force: true);
    } catch (_) {}
    _controller.close();
  }
}
