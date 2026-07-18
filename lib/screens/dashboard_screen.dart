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

    // Compute SLA metrics
    final resolvedTickets = allTickets.where((t) => t['status'] == 'RESOLVED').toList();
    final breachedCount = resolvedTickets.where((t) => t['isSlaBreached'] == true).length;
    final metCount = resolvedTickets.length - breachedCount;
    final slaComplianceRate = resolvedTickets.isEmpty 
        ? 100.0 
        : (metCount / resolvedTickets.length) * 100;

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
              // Welcome Header Block with Neon Effect
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E293B).withOpacity(0.8),
                      const Color(0xFF0F172A).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Premium Avatar with Outer Glowing Ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)], // Indigo to Pink glow
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF0F172A),
                        child: Text(
                          (auth.user?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900, 
                            color: Colors.white, 
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.user?['name'] ?? 'IT Agent',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981), // Glowing active emerald green
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'IT Operations Agent',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Glassmorphic SLA KPI Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ],
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
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: slaComplianceRate / 100,
                        backgroundColor: Colors.black38,
                        color: slaComplianceRate >= 80 ? const Color(0xFF10B981) : Colors.orange,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SLA Met: $metCount Tiket',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'SLA Breached: $breachedCount Tiket',
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
              const SizedBox(height: 28),

              // Section Header: Overall Queues
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: Color(0xFF6366F1), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Overall Ticket Queue',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // 2x2 Grid of Status Cards with Premium Shadows and Accents
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildPremiumGridCard(
                    'OPEN', 
                    openCount.toString(), 
                    const Color(0xFF3B82F6), // Neon Blue
                    Icons.mark_email_unread_rounded,
                  ),
                  _buildPremiumGridCard(
                    'IN PROGRESS', 
                    progressCount.toString(), 
                    const Color(0xFFF59E0B), // Neon Orange
                    Icons.play_circle_filled_rounded,
                  ),
                  _buildPremiumGridCard(
                    'PENDING', 
                    pendingCount.toString(), 
                    const Color(0xFFA855F7), // Neon Purple
                    Icons.pause_circle_filled_rounded,
                  ),
                  _buildPremiumGridCard(
                    'RESOLVED', 
                    resolvedCount.toString(), 
                    const Color(0xFF10B981), // Emerald
                    Icons.check_circle_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Section Header: My Active Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_ind_rounded, color: Color(0xFFEC4899), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'My Active Tasks',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 16, 
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
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (myActiveTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 48, color: Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      const Text(
                        'You are all caught up!',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tidak ada tiket yang ditugaskan kepada Anda.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _buildPremiumGridCard(String label, String count, Color accentColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8), // Glassy backdrop
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1,
                ),
              ),
              Icon(
                icon, 
                color: accentColor, 
                size: 20,
              ),
            ],
          ),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 32, 
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: ID, Priority, Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket['id'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF818CF8), 
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: priorityColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Circle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  ticket['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
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
                const SizedBox(height: 12),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                
                // Bottom Row: Requester Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: const Color(0xFF312E81),
                      child: Text(
                        (ticket['requester']?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 9, color: Color(0xFFC7D2FE), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket['requester']?['name'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white38),
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
