import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/colors.dart';
import 'ticket_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProv = Provider.of<TicketProvider>(context, listen: false);
      ticketProv.fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ticketProv = Provider.of<TicketProvider>(context);

    // Compute metrics from local tickets state
    final allTickets = ticketProv.tickets;
    
    final openCount = allTickets.where((t) => t['status'] == 'OPEN').length;
    final progressCount = allTickets.where((t) => t['status'] == 'IN_PROGRESS').length;
    final pendingCount = allTickets.where((t) => t['status'] == 'PENDING').length;
    final resolvedCount = allTickets.where((t) => t['status'] == 'RESOLVED').length;

    // Filter tickets assigned to current logged-in agent that are not closed/resolved
    final currentAgentId = auth.user?['id'];
    final myActiveTickets = allTickets.where((t) {
      final isAssigned = t['assignedToId'] == currentAgentId;
      final isUnresolved = t['status'] == 'OPEN' || t['status'] == 'IN_PROGRESS' || t['status'] == 'PENDING';
      return isAssigned && isUnresolved;
    }).toList();

    // SLA compliance metrics (overall)
    final resolvedTickets = allTickets.where((t) => t['status'] == 'RESOLVED').toList();
    final breachedCount = resolvedTickets.where((t) => t['isSlaBreached'] == true).length;
    final metCount = resolvedTickets.length - breachedCount;
    final slaComplianceRate = resolvedTickets.isEmpty 
        ? 100.0 
        : (metCount / resolvedTickets.length) * 100;

    // Top Resolved Categories calculation
    final Map<String, int> categoryCounts = {};
    for (var ticket in allTickets) {
      if (ticket['status'] == 'RESOLVED') {
        final category = ticket['category'] ?? 'Other';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final String formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.slate50, // Light Slate Background
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_mra.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'MRA HELPDESK',
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.0,
                fontSize: 16,
                color: AppColors.slate900,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.sync_rounded, color: AppColors.slate800, size: 20),
              onPressed: () {
                ticketProv.fetchTickets();
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ticketProv.fetchTickets(),
        color: AppColors.green600,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header Block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate300.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.green600, AppColors.green300],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          (auth.user?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900, 
                            color: AppColors.green700, 
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.user?['name'] ?? 'IT Agent',
                            style: const TextStyle(
                              color: AppColors.slate900, 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // COMPACT QUEUE SUMMARY ROW
              const Text(
                'TICKET QUEUE',
                style: TextStyle(
                  color: AppColors.slate500, 
                  fontSize: 11, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildCompactStatusCard('OPEN', openCount.toString(), const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _buildCompactStatusCard('PROGRESS', progressCount.toString(), const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildCompactStatusCard('PENDING', pendingCount.toString(), const Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  _buildCompactStatusCard('RESOLVED', resolvedCount.toString(), const Color(0xFF059669)),
                ],
              ),
              const SizedBox(height: 18),

              // SLA COMPLIANCE CARD (Retained based on user feedback)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate300.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.green200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SLA COMPLIANCE',
                              style: TextStyle(
                                color: AppColors.green700, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Response & Resolution Target',
                              style: TextStyle(color: AppColors.slate600, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${slaComplianceRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: slaComplianceRate >= 80 ? AppColors.green700 : Colors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: slaComplianceRate / 100,
                        backgroundColor: AppColors.slate200,
                        color: slaComplianceRate >= 80 ? AppColors.green600 : Colors.orange,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SLA Met: $metCount Tickets',
                          style: const TextStyle(color: AppColors.slate700, fontSize: 11),
                        ),
                        Text(
                          'SLA Breached: $breachedCount Tickets',
                          style: TextStyle(
                            color: breachedCount > 0 ? Colors.red : AppColors.slate700, 
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // TOP RESOLVED CATEGORIES (Bar chart visualization)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate300.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pie_chart_outline_rounded, color: AppColors.green600, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'TOP RESOLVED CATEGORIES',
                          style: TextStyle(
                            color: AppColors.slate900, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sortedCategories.isEmpty)
                      const Text(
                        'No resolved category data available.',
                        style: TextStyle(color: AppColors.slate400, fontSize: 12),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: min(3, sortedCategories.length),
                        itemBuilder: (context, index) {
                          final category = sortedCategories[index];
                          final count = category.value;
                          final totalResolved = resolvedCount == 0 ? 1 : resolvedCount;
                          final percentage = count / totalResolved;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category.key,
                                      style: const TextStyle(color: AppColors.slate800, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '$count resolved',
                                      style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: AppColors.slate100,
                                    color: _getCategoryColor(index),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section Header: My Active Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_ind_rounded, color: AppColors.green600, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'My Active Tasks',
                        style: TextStyle(
                          color: AppColors.slate900, 
                          fontSize: 14, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.slate200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${myActiveTickets.length} tasks',
                      style: const TextStyle(color: AppColors.slate800, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (myActiveTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.slate300.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 40, color: AppColors.emeraldDefault),
                      SizedBox(height: 8),
                      Text(
                        'You are all caught up!',
                        style: TextStyle(color: AppColors.slate900, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No active tickets are currently assigned to you.',
                        style: TextStyle(color: AppColors.slate500, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myActiveTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = myActiveTickets[index];
                    return _buildMyTicketPremiumCard(context, ticket);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate300.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.slate600, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    switch (index) {
      case 0:
        return AppColors.green500;
      case 1:
        return const Color(0xFF3B82F6);
      case 2:
        return const Color(0xFFF59E0B);
      default:
        return Colors.blue;
    }
  }

  Widget _buildMyTicketPremiumCard(BuildContext context, dynamic ticket) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate300.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticketId: ticket['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket['id'] ?? '',
                      style: const TextStyle(
                        color: AppColors.green600, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: priorityColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(color: priorityColor, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ticket['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate900, 
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 12, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${ticket['company']?['name'] ?? ''} (${ticket['company']?['location'] ?? ''})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.slate600, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.slate200, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: AppColors.green100,
                      child: Text(
                        (ticket['requester']?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 8, color: AppColors.green700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ticket['requester']?['name'] ?? '',
                        style: const TextStyle(color: AppColors.slate800, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.slate400),
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
