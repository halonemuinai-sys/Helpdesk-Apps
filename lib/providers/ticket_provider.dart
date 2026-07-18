import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  List<dynamic> _tickets = [];
  List<dynamic> _categories = [];
  List<dynamic> _companies = [];
  List<dynamic> _agents = [];
  
  bool _isLoading = false;
  String? _error;
  
  // Filters
  String _selectedStatus = '';
  String _selectedPriority = '';
  String _selectedCompanyId = '';
  String _searchQuery = '';

  // Real-time Event Tracking
  SseConnection? _sseConnection;
  String? _lastNewTicketId; // For flashing new tickets
  
  // Getters
  List<dynamic> get tickets => _tickets;
  List<dynamic> get categories => _categories;
  List<dynamic> get companies => _companies;
  List<dynamic> get agents => _agents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  String get selectedStatus => _selectedStatus;
  String get selectedPriority => _selectedPriority;
  String get selectedCompanyId => _selectedCompanyId;
  String get searchQuery => _searchQuery;
  String? get lastNewTicketId => _lastNewTicketId;

  // Filter setters
  void setStatus(String status) {
    _selectedStatus = status;
    fetchTickets();
  }

  void setPriority(String priority) {
    _selectedPriority = priority;
    fetchTickets();
  }

  void setCompanyId(String companyId) {
    _selectedCompanyId = companyId;
    fetchTickets();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  // Clear filters
  void clearFilters() {
    _selectedStatus = '';
    _selectedPriority = '';
    _selectedCompanyId = '';
    _searchQuery = '';
    fetchTickets();
  }

  // Fetch tickets from API
  Future<void> fetchTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await TicketService.fetchTickets(
        status: _selectedStatus,
        priority: _selectedPriority,
        companyId: _selectedCompanyId,
        search: _searchQuery,
      );
      _tickets = fetched;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Master Data (categories, companies, agents)
  Future<void> fetchMasterData() async {
    try {
      final data = await Future.wait([
        TicketService.fetchCategories(),
        TicketService.fetchCompanies(),
        TicketService.fetchAgents(),
      ]);
      _categories = data[0];
      _companies = data[1];
      _agents = data[2];
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching master data: $e");
      }
    }
  }

  // Initialize Real-time SSE listener
  void initRealtime(String token) async {
    // Close existing connection if any
    _sseConnection?.close();
    
    _sseConnection = await TicketService.openEventsConnection(token);
    
    _sseConnection!.stream.listen((event) {
      final String action = event['action'] ?? '';
      final dynamic payload = event['ticket'];

      if (payload == null) return;

      switch (action) {
        case 'TICKET_CREATED':
          _handleTicketCreated(payload);
          break;
        case 'TICKET_STATUS_CHANGED':
        case 'TICKET_ASSIGNED':
        case 'TICKET_PRIORITY_CHANGED':
        case 'TICKET_UPDATED':
          _handleTicketUpdated(payload);
          break;
        case 'TICKET_DELETED':
          _handleTicketDeleted(payload['id']);
          break;
      }
    });
  }

  // Real-time Event Handlers
  void _handleTicketCreated(dynamic ticket) {
    // Check if new ticket satisfies current filters before inserting
    bool matchStatus = _selectedStatus.isEmpty || ticket['status'] == _selectedStatus;
    bool matchPriority = _selectedPriority.isEmpty || ticket['priority'] == _selectedPriority;
    bool matchCompany = _selectedCompanyId.isEmpty || ticket['companyId'].toString() == _selectedCompanyId;
    
    bool matchSearch = _searchQuery.isEmpty ||
        (ticket['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (ticket['description'] as String).toLowerCase().contains(_searchQuery.toLowerCase());

    if (matchStatus && matchPriority && matchCompany && matchSearch) {
      // Insert at top of list
      _tickets.insert(0, ticket);
      
      // Set highlighting
      _lastNewTicketId = ticket['id'];
      notifyListeners();

      // Clear highlight after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (_lastNewTicketId == ticket['id']) {
          _lastNewTicketId = null;
          notifyListeners();
        }
      });
    }
  }

  void _handleTicketUpdated(dynamic updatedTicket) {
    final String id = updatedTicket['id'];
    
    // Find index of the ticket
    final index = _tickets.indexWhere((t) => t['id'] == id);

    // Verify if it still matches filters
    bool matchStatus = _selectedStatus.isEmpty || updatedTicket['status'] == _selectedStatus;
    bool matchPriority = _selectedPriority.isEmpty || updatedTicket['priority'] == _selectedPriority;
    bool matchCompany = _selectedCompanyId.isEmpty || updatedTicket['companyId'].toString() == _selectedCompanyId;
    bool matchSearch = _searchQuery.isEmpty ||
        (updatedTicket['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (updatedTicket['description'] as String).toLowerCase().contains(_searchQuery.toLowerCase());

    final bool shouldInclude = matchStatus && matchPriority && matchCompany && matchSearch;

    if (index != -1) {
      if (shouldInclude) {
        // Update in-place
        _tickets[index] = updatedTicket;
      } else {
        // Remove since it no longer matches filters
        _tickets.removeAt(index);
      }
    } else if (shouldInclude) {
      // It was not in the list, but now matches the filters (e.g. status changed to match selected filter)
      // Insert in chronological order or at top for visibility
      _tickets.insert(0, updatedTicket);
    }
    
    notifyListeners();
  }

  void _handleTicketDeleted(String deletedId) {
    _tickets.removeWhere((t) => t['id'] == deletedId);
    notifyListeners();
  }

  // Create ticket wrapper
  Future<void> createTicket(Map<String, dynamic> data) async {
    await TicketService.createTicket(data);
    // Real-time listener will automatically insert the ticket, but we can fetch as fallback
  }

  // Update status wrapper
  Future<void> updateTicketStatus(String ticketId, String status, {String? comment}) async {
    await TicketService.updateStatus(ticketId, status, comment: comment);
  }

  // Assign ticket wrapper
  Future<void> assignTicket(String ticketId, String agentId) async {
    await TicketService.assignTicket(ticketId, agentId);
  }

  // Update priority wrapper
  Future<void> updateTicketPriority(String ticketId, String priority) async {
    await TicketService.updatePriority(ticketId, priority);
  }

  // Update metadata wrapper
  Future<void> updateTicketMeta(String ticketId, {
    required String category,
    required String subCategory,
    required String source,
  }) async {
    await TicketService.updateMeta(ticketId, category: category, subCategory: subCategory, source: source);
  }

  @override
  void dispose() {
    _sseConnection?.close();
    super.dispose();
  }
}
