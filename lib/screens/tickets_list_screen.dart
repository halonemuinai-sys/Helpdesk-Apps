import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Status Filter
                  const Text('STATUS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
                  const Text('PRIORITY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
                  const Text('COMPANY / BRANCH', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF0F172A),
                    initialValue: prov.selectedCompanyId.isEmpty ? null : prov.selectedCompanyId,
                    hint: const Text('All Companies', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.slate900,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.slate850),
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
                  const SizedBox(height: 28),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            prov.clearFilters();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reset All', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
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
  }

  Widget _buildFilterChip(String value, String label, String activeValue, Function(String) onTap) {
    final bool isSelected = value == activeValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.slate400,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(value),
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: AppColors.slate900,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketProv = Provider.of<TicketProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium dark theme
      appBar: AppBar(
        title: const Text(
          'TICKETS FEED',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.slate800,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
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
            color: const Color(0xFF0F172A),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ticketProv.setSearchQuery(val);
              },
              onSubmitted: (val) {
                ticketProv.fetchTickets();
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by ID, title, or reporter...',
                hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ticketProv.setSearchQuery('');
                          ticketProv.fetchTickets();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B).withOpacity(0.6),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
            ),
          ),
          
          // Horizontal Active Filters Bar (Premium UX)
          if (ticketProv.selectedStatus.isNotEmpty || 
              ticketProv.selectedPriority.isNotEmpty || 
              ticketProv.selectedCompanyId.isNotEmpty)
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
                ],
              ),
            ),
          
          // Tickets feed stream
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ticketProv.fetchTickets(),
              color: const Color(0xFF6366F1),
              backgroundColor: const Color(0xFF1E293B),
              child: ticketProv.isLoading && ticketProv.tickets.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                    )
                  : ticketProv.tickets.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.20),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B).withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, size: 52, color: AppColors.slate600),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tickets found',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                          itemCount: ticketProv.tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = ticketProv.tickets[index];
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
        color: const Color(0xFF312E81).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF818CF8)),
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
    if (status == 'IN_PROGRESS') statusColor = const Color(0xFFF59E0B);
    if (status == 'PENDING') statusColor = const Color(0xFFA855F7);
    if (status == 'RESOLVED') statusColor = const Color(0xFF10B981);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.7), // Glassy backdrop
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNew 
              ? const Color(0xFF6366F1).withOpacity(0.8) 
              : Colors.white.withOpacity(0.04),
          width: isNew ? 2.5 : 1,
        ),
        boxShadow: isNew
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
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
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
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
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: priorityColor.withOpacity(0.25)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                
                // Company / Branch info
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${ticket['company']?['name'] ?? ''} (${ticket['company']?['location'] ?? ''})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 14),
                
                // Bottom Row: Requester name and Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xFF312E81),
                          child: Text(
                            (ticket['requester']?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 9, color: Color(0xFFC7D2FE), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ticket['requester']?['name'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
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
