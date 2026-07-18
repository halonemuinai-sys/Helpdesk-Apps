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

    // Agent Performance calculations
    final myTickets = allTickets.where((t) => t['assignedToId'] == currentAgentId).toList();
    final myResolvedTickets = myTickets.where((t) => t['status'] == 'RESOLVED').toList();
    final myResolvedCount = myResolvedTickets.length;
    final myBreachedCount = myResolvedTickets.where((t) => t['isSlaBreached'] == true).length;
    final myMetCount = myResolvedCount - myBreachedCount;
    final mySlaRate = myResolvedCount == 0 ? 100.0 : (myMetCount / myResolvedCount) * 100;

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
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate 900
      appBar: AppBar(
        title: const Text(
          'MRA HELPDESK',
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.slate800,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
              onPressed: () {
                ticketProv.fetchTickets();
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ticketProv.fetchTickets(),
        color: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF1E293B),
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
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E293B).withOpacity(0.8),
                      const Color(0xFF0F172A).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF0F172A),
                        child: Text(
                          (auth.user?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900, 
                            color: Colors.white, 
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
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.user?['name'] ?? 'IT Agent',
                            style: const TextStyle(
                              color: Colors.white, 
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
                  color: Colors.white70, 
                  fontSize: 11, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildCompactStatusCard('OPEN', openCount.toString(), const Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  _buildCompactStatusCard('PROGRESS', progressCount.toString(), const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildCompactStatusCard('PENDING', pendingCount.toString(), const Color(0xFFA855F7)),
                  const SizedBox(width: 8),
                  _buildCompactStatusCard('RESOLVED', resolvedCount.toString(), const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 18),

              // SLA COMPLIANCE CARD (Retained based on user feedback)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.shade800.withOpacity(0.6)),
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
                                color: Color(0xFFC7D2FE), 
                                fontWeight: FontWeight.bold, 
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Response & Resolution Target',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${slaComplianceRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: slaComplianceRate >= 80 ? const Color(0xFF34D399) : Colors.orangeAccent,
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
                        backgroundColor: Colors.black38,
                        color: slaComplianceRate >= 80 ? const Color(0xFF10B981) : Colors.orange,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SLA Met: $metCount Tickets',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'SLA Breached: $breachedCount Tickets',
                          style: TextStyle(
                            color: breachedCount > 0 ? Colors.redAccent.shade100 : Colors.white70, 
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // AGENT PERFORMANCE SUMMARY
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights_rounded, color: Color(0xFF6366F1), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'AGENT PERFORMANCE',
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPerformanceStatItem('Active Tasks', myActiveTickets.length.toString()),
                        _buildPerformanceStatItem('My Resolved', myResolvedCount.toString()),
                        _buildPerformanceStatItem('My SLA Rate', '${mySlaRate.toStringAsFixed(0)}%'),
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            value: mySlaRate / 100,
                            strokeWidth: 4,
                            backgroundColor: Colors.white12,
                            color: mySlaRate >= 80 ? const Color(0xFF10B981) : Colors.orange,
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
                  color: const Color(0xFF1E293B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pie_chart_outline_rounded, color: Color(0xFFEC4899), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'TOP RESOLVED CATEGORIES',
                          style: TextStyle(
                            color: Colors.white, 
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
                        style: TextStyle(color: Colors.white38, fontSize: 12),
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
                                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '$count resolved',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.white12,
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
                      Icon(Icons.assignment_ind_rounded, color: Color(0xFFEC4899), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'My Active Tasks',
                        style: TextStyle(
                          color: Colors.white, 
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
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${myActiveTickets.length} tasks',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (myActiveTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 40, color: Color(0xFF10B981)),
                      SizedBox(height: 8),
                      Text(
                        'You are all caught up!',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No active tickets are currently assigned to you.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
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
              style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Color _getCategoryColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF6366F1); // Indigo
      case 1:
        return const Color(0xFF10B981); // Emerald
      case 2:
        return const Color(0xFFF59E0B); // Amber
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
    if (status == 'OPEN') statusColor = const Color(0xFF60A5FA);
    if (status == 'IN_PROGRESS') statusColor = const Color(0xFFFBBF24);
    if (status == 'PENDING') statusColor = const Color(0xFFC084FC);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                        color: Color(0xFF818CF8), 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: priorityColor.withOpacity(0.3)),
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
                            color: statusColor.withOpacity(0.12),
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
                    color: Colors.white, 
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${ticket['company']?['name'] ?? ''} (${ticket['company']?['location'] ?? ''})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: const Color(0xFF312E81),
                      child: Text(
                        (ticket['requester']?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 8, color: Color(0xFFC7D2FE), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ticket['requester']?['name'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white38),
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
