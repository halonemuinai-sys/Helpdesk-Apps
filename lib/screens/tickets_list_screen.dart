import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/colors.dart';
import 'ticket_detail_screen.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  final _searchController = TextEditingController();

  String _sortBy = 'newest'; // 'newest' or 'sla_urgent'
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<TicketProvider>(context, listen: false);
      prov.fetchTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
        return Consumer<TicketProvider>(
          builder: (context, prov, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Tickets',
                        style: TextStyle(color: AppColors.slate900, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.slate700),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Status Filter
                  const Text('STATUS', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('', 'ALL', prov.selectedStatus, (val) => prov.setStatus(val)),
                      _buildFilterChip('OPEN', 'OPEN', prov.selectedStatus, (val) => prov.setStatus(val)),
                      _buildFilterChip('IN_PROGRESS', 'IN PROGRESS', prov.selectedStatus, (val) => prov.setStatus(val)),
                      _buildFilterChip('PENDING', 'PENDING', prov.selectedStatus, (val) => prov.setStatus(val)),
                      _buildFilterChip('RESOLVED', 'RESOLVED', prov.selectedStatus, (val) => prov.setStatus(val)),
                      _buildFilterChip('CLOSED', 'CLOSED', prov.selectedStatus, (val) => prov.setStatus(val)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Priority Filter
                  const Text('PRIORITY', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('', 'ALL', prov.selectedPriority, (val) => prov.setPriority(val)),
                      _buildFilterChip('LOW', 'LOW', prov.selectedPriority, (val) => prov.setPriority(val)),
                      _buildFilterChip('MEDIUM', 'MEDIUM', prov.selectedPriority, (val) => prov.setPriority(val)),
                      _buildFilterChip('HIGH', 'HIGH', prov.selectedPriority, (val) => prov.setPriority(val)),
                      _buildFilterChip('CRITICAL', 'CRITICAL', prov.selectedPriority, (val) => prov.setPriority(val)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Company Filter
                  const Text('COMPANY / BRANCH', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    initialValue: prov.selectedCompanyId.isEmpty ? null : prov.selectedCompanyId,
                    hint: const Text('All Companies', style: TextStyle(color: AppColors.slate500, fontSize: 14)),
                    style: const TextStyle(color: AppColors.slate900, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All Companies'),
                      ),
                      ...prov.companies.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text('${c['name']} (${c['location']})'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      prov.setCompanyId(val ?? '');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Sort
                  const Text('SORT BY', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip('Terbaru', 'newest', setModalState),
                      _buildSortChip('SLA Paling Mendesak', 'sla_urgent', setModalState),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date range
                  const Text('RENTANG TANGGAL', style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  _buildDateRangeSelector(setModalState),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            prov.clearFilters();
                            setModalState(() {
                              _sortBy = 'newest';
                              _dateRange = null;
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.green600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reset All', style: TextStyle(color: AppColors.green700, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, String activeValue, Function(String) onTap) {
    final bool isSelected = value == activeValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.slate600,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(value),
      selectedColor: AppColors.green600,
      backgroundColor: AppColors.slate100,
    );
  }

  Widget _buildSortChip(String label, String value, StateSetter setModalState) {
    final bool isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.slate600,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _sortBy = value);
        setModalState(() {});
      },
      selectedColor: AppColors.green600,
      backgroundColor: AppColors.slate100,
    );
  }

  Widget _buildDateRangeSelector(StateSetter setModalState) {
    final label = _dateRange == null
        ? 'Semua tanggal'
        : '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 2),
          lastDate: now,
          initialDateRange: _dateRange,
        );
        if (picked != null) {
          setState(() => _dateRange = picked);
          setModalState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_rounded, size: 18, color: AppColors.green600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppColors.slate800, fontSize: 13)),
            ),
            if (_dateRange != null)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => _dateRange = null);
                  setModalState(() {});
                },
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.slate400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Applies the selected date range filter and sort order over the raw ticket list
  List<dynamic> _applySortAndFilter(List<dynamic> tickets) {
    Iterable<dynamic> result = tickets;

    if (_dateRange != null) {
      final endExclusive = _dateRange!.end.add(const Duration(days: 1));
      result = result.where((t) {
        final created = DateTime.tryParse(t['createdAt']?.toString() ?? '');
        if (created == null) return false;
        return !created.isBefore(_dateRange!.start) && created.isBefore(endExclusive);
      });
    }

    final list = result.toList();

    if (_sortBy == 'sla_urgent') {
      list.sort((a, b) {
        final da = _slaDeadline(a);
        final db = _slaDeadline(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    } else {
      list.sort((a, b) {
        final ca = DateTime.tryParse(a['createdAt']?.toString() ?? '');
        final cb = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        if (ca == null || cb == null) return 0;
        return cb.compareTo(ca);
      });
    }

    return list;
  }

  // The active SLA deadline for a ticket (response limit if OPEN, resolution limit otherwise);
  // null when the ticket has no active SLA (already resolved/closed, or no limit set).
  DateTime? _slaDeadline(dynamic ticket) {
    final status = ticket['status'] ?? 'OPEN';
    if (status == 'RESOLVED' || status == 'CLOSED') return null;
    final limit = status == 'OPEN' ? ticket['slaResponseLimit'] : ticket['slaResolutionLimit'];
    final limitStr = limit?.toString() ?? '';
    if (limitStr.isEmpty) return null;
    return DateTime.tryParse(limitStr);
  }

  @override
  Widget build(BuildContext context) {
    final ticketProv = Provider.of<TicketProvider>(context);
    final displayTickets = _applySortAndFilter(ticketProv.tickets);

    return Scaffold(
      backgroundColor: AppColors.slate50, // Light neutral theme
      appBar: AppBar(
        title: const Text(
          'TICKETS FEED',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18, color: AppColors.slate900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: AppColors.slate700, size: 20),
              onPressed: _showFilterBottomSheet,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Elegant Search Box Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ticketProv.setSearchQuery(val);
              },
              onSubmitted: (val) {
                ticketProv.fetchTickets();
              },
              style: const TextStyle(color: AppColors.slate900, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by ID, title, or reporter...',
                hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.green600, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.slate500, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ticketProv.setSearchQuery('');
                          ticketProv.fetchTickets();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.slate50,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.green600, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // Horizontal Active Filters Bar (Premium UX)
          if (ticketProv.selectedStatus.isNotEmpty ||
              ticketProv.selectedPriority.isNotEmpty ||
              ticketProv.selectedCompanyId.isNotEmpty ||
              _dateRange != null ||
              _sortBy != 'newest')
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (ticketProv.selectedStatus.isNotEmpty)
                    _buildActiveFilterTag('Status: ${ticketProv.selectedStatus}', () => ticketProv.setStatus('')),
                  if (ticketProv.selectedPriority.isNotEmpty)
                    _buildActiveFilterTag('Priority: ${ticketProv.selectedPriority}', () => ticketProv.setPriority('')),
                  if (ticketProv.selectedCompanyId.isNotEmpty)
                    _buildActiveFilterTag('Company Filter Active', () => ticketProv.setCompanyId('')),
                  if (_sortBy == 'sla_urgent')
                    _buildActiveFilterTag('Sort: SLA Mendesak', () => setState(() => _sortBy = 'newest')),
                  if (_dateRange != null)
                    _buildActiveFilterTag(
                      '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                      () => setState(() => _dateRange = null),
                    ),
                ],
              ),
            ),
          
          // Tickets feed stream
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ticketProv.fetchTickets(),
              color: AppColors.green600,
              backgroundColor: Colors.white,
              child: ticketProv.isLoading && ticketProv.tickets.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.green600),
                    )
                  : displayTickets.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.20),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, size: 52, color: AppColors.slate500),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tickets found',
                                    style: TextStyle(color: AppColors.slate800, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 40.0),
                                    child: Text(
                                      'No tickets match your filters. Try adjusting your search query or reset your filters.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.slate500, fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          itemCount: displayTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = displayTickets[index];
                            final bool isNew = ticket['id'] == ticketProv.lastNewTicketId;
                            return _buildPremiumTicketCard(context, ticket, isNew);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterTag(String label, VoidCallback onClear) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.green200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.green700, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.green600),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTicketCard(BuildContext context, dynamic ticket, bool isNew) {
    final priority = ticket['priority'] ?? 'LOW';
    Color priorityColor = Colors.grey;
    if (priority == 'CRITICAL') priorityColor = const Color(0xFFEF4444);
    if (priority == 'HIGH') priorityColor = const Color(0xFFF97316);
    if (priority == 'MEDIUM') priorityColor = const Color(0xFF3B82F6);

    final status = ticket['status'] ?? 'OPEN';
    Color statusColor = Colors.grey;
    if (status == 'OPEN') statusColor = const Color(0xFF3B82F6);
    if (status == 'IN_PROGRESS') statusColor = const Color(0xFFD97706);
    if (status == 'PENDING') statusColor = const Color(0xFF7C3AED);
    if (status == 'RESOLVED') statusColor = const Color(0xFF059669);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNew 
              ? AppColors.green500
              : AppColors.slate200,
          width: isNew ? 2.5 : 1,
        ),
        boxShadow: isNew
            ? [
                BoxShadow(
                  color: AppColors.green300.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: AppColors.slate300.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticketId: ticket['id']),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18.0),
            // Accent left border highlighting the ticket status
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border(
                left: BorderSide(color: statusColor, width: 4.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Ticket ID, New badge, Priority badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          ticket['id'] ?? '',
                          style: const TextStyle(color: AppColors.green600, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.green600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: priorityColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Ticket Title
                Text(
                  ticket['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.slate900, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                
                // Company / Branch info
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${ticket['company']?['name'] ?? ''} (${ticket['company']?['location'] ?? ''})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.slate600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.slate200, height: 1),
                const SizedBox(height: 14),
                
                // Bottom Row: Requester name and Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.green100,
                          child: Text(
                            (ticket['requester']?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 9, color: AppColors.green700, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ticket['requester']?['name'] ?? '',
                          style: const TextStyle(color: AppColors.slate800, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
