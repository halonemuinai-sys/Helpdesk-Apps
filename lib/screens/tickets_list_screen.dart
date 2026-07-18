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
  final _scrollController = ScrollController();

  static const int _pageSize = 20;
  int _displayLimit = _pageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<TicketProvider>(context, listen: false);
      prov.fetchTickets();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final total = Provider.of<TicketProvider>(context, listen: false).tickets.length;
      if (_displayLimit < total) {
        setState(() => _displayLimit = (_displayLimit + _pageSize).clamp(0, total));
      }
    }
  }

  void _resetPaging() {
    _displayLimit = _pageSize;
  }

  void _applyFilter(VoidCallback action) {
    setState(_resetPaging);
    action();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        style: TextStyle(color: AppColors.slate900, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.slate600),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Filter
                  const Text('STATUS', style: TextStyle(color: AppColors.slate600, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('', 'ALL', prov.selectedStatus, (val) => _applyFilter(() => prov.setStatus(val))),
                      _buildFilterChip('OPEN', 'OPEN', prov.selectedStatus, (val) => _applyFilter(() => prov.setStatus(val))),
                      _buildFilterChip('IN_PROGRESS', 'IN PROGRESS', prov.selectedStatus, (val) => _applyFilter(() => prov.setStatus(val))),
                      _buildFilterChip('PENDING', 'PENDING', prov.selectedStatus, (val) => _applyFilter(() => prov.setStatus(val))),
                      _buildFilterChip('RESOLVED', 'RESOLVED', prov.selectedStatus, (val) => _applyFilter(() => prov.setStatus(val))),
                      _buildFilterChip('CLOSED', 'CLOSED', prov.selectedStatus, (val) => _applyFilter(() => prov.setStatus(val))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Priority Filter
                  const Text('PRIORITY', style: TextStyle(color: AppColors.slate600, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('', 'ALL', prov.selectedPriority, (val) => _applyFilter(() => prov.setPriority(val))),
                      _buildFilterChip('LOW', 'LOW', prov.selectedPriority, (val) => _applyFilter(() => prov.setPriority(val))),
                      _buildFilterChip('MEDIUM', 'MEDIUM', prov.selectedPriority, (val) => _applyFilter(() => prov.setPriority(val))),
                      _buildFilterChip('HIGH', 'HIGH', prov.selectedPriority, (val) => _applyFilter(() => prov.setPriority(val))),
                      _buildFilterChip('CRITICAL', 'CRITICAL', prov.selectedPriority, (val) => _applyFilter(() => prov.setPriority(val))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Company Filter
                  const Text('COMPANY / BRANCH', style: TextStyle(color: AppColors.slate600, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    initialValue: prov.selectedCompanyId.isEmpty ? null : prov.selectedCompanyId,
                    hint: const Text('All Companies', style: TextStyle(color: AppColors.slate400, fontSize: 14)),
                    style: const TextStyle(color: AppColors.slate900, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.green50,
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
                      _applyFilter(() => prov.setCompanyId(val ?? ''));
                    },
                  ),
                  const SizedBox(height: 28),

                  // Clear filters button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _applyFilter(prov.clearFilters);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.green600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Reset All', style: TextStyle(color: AppColors.green600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    final ticketProv = Provider.of<TicketProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.green50,
      appBar: AppBar(
        title: const Text('Tickets Feed'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.green600),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ticketProv.setSearchQuery(val);
              },
              onSubmitted: (val) {
                _applyFilter(ticketProv.fetchTickets);
              },
              style: const TextStyle(color: AppColors.slate900),
              decoration: InputDecoration(
                hintText: 'Search ticket ID, title or reporter...',
                hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.slate500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.slate400, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ticketProv.setSearchQuery('');
                          _applyFilter(ticketProv.fetchTickets);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.green50,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.green500),
                ),
              ),
            ),
          ),

          // Tickets feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                setState(_resetPaging);
                return ticketProv.fetchTickets();
              },
              color: AppColors.green600,
              backgroundColor: Colors.white,
              child: ticketProv.isLoading && ticketProv.tickets.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.green600),
                    )
                  : ticketProv.tickets.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: AppColors.slate300),
                                  SizedBox(height: 12),
                                  Text(
                                    'Daftar tiket kosong',
                                    style: TextStyle(color: AppColors.slate700, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tidak ada tiket yang cocok dengan kriteria filter.',
                                    style: TextStyle(color: AppColors.slate500, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Builder(builder: (context) {
                          final total = ticketProv.tickets.length;
                          final shown = _displayLimit.clamp(0, total);
                          final bool hasMore = shown < total;
                          return ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: shown + (hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= shown) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.green600),
                                    ),
                                  ),
                                );
                              }
                              final ticket = ticketProv.tickets[index];
                              final bool isNew = ticket['id'] == ticketProv.lastNewTicketId;
                              return _buildTicketFeedCard(context, ticket, isNew);
                            },
                          );
                        }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketFeedCard(BuildContext context, dynamic ticket, bool isNew) {
    final priority = ticket['priority'] ?? 'LOW';
    Color priorityColor = Colors.grey;
    if (priority == 'CRITICAL') priorityColor = Colors.red;
    if (priority == 'HIGH') priorityColor = Colors.orange;
    if (priority == 'MEDIUM') priorityColor = Colors.blue;

    final status = ticket['status'] ?? 'OPEN';
    Color statusColor = Colors.grey;
    if (status == 'OPEN') statusColor = Colors.blue;
    if (status == 'IN_PROGRESS') statusColor = Colors.amber.shade800;
    if (status == 'PENDING') statusColor = Colors.purple;
    if (status == 'RESOLVED') statusColor = AppColors.green600;
    if (status == 'CLOSED') statusColor = Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNew
              ? AppColors.green600.withOpacity(0.8)
              : AppColors.slate200,
          width: isNew ? 2.5 : 1,
        ),
        boxShadow: isNew
            ? [
                BoxShadow(
                  color: AppColors.green500.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: AppColors.slate400.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticketId: ticket['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BARU',
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
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: priorityColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ticket['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.slate900, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 14, color: AppColors.slate500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${ticket['company']?['name'] ?? ''} (${ticket['company']?['location'] ?? ''})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.slate500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.slate200, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: AppColors.green600,
                          child: Text(
                            (ticket['requester']?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ticket['requester']?['name'] ?? '',
                          style: const TextStyle(color: AppColors.slate600, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
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
