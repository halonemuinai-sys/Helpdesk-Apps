import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
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

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Slate 800
      appBar: AppBar(
        title: const Text(
          'IT Helpdesk Workspace',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ticketProv.fetchTickets();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ticketProv.fetchTickets(),
        color: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF0F172A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF4F46E5),
                    child: Text(
                      (auth.user?['name'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(color: AppColors.slate400, fontSize: 13),
                        ),
                        Text(
                          auth.user?['name'] ?? 'IT Agent',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // KPI Section (SLA compliance bar)
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
                        const Text(
                          'SLA Compliance Rate',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          '${slaComplianceRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: slaComplianceRate >= 80 ? AppColors.emeraldAccent : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: slaComplianceRate / 100,
                        backgroundColor: Colors.black38,
                        color: slaComplianceRate >= 80 ? AppColors.emeraldDefault : Colors.orange,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Berdasarkan tiket RESOLVED yang tepat waktu.',
                      style: TextStyle(color: AppColors.slate400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tickets Status Grid
              const Text(
                'Overall Ticket Queue',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _buildGridCard('OPEN', openCount.toString(), Colors.blue, Colors.blue.shade900.withOpacity(0.3)),
                  _buildGridCard('IN PROGRESS', progressCount.toString(), Colors.amber, Colors.amber.shade900.withOpacity(0.3)),
                  _buildGridCard('PENDING', pendingCount.toString(), Colors.purpleAccent, Colors.purple.shade900.withOpacity(0.3)),
                  _buildGridCard('RESOLVED', resolvedCount.toString(), AppColors.emeraldDefault, AppColors.emeraldDefault.withOpacity(0.3)),
                ],
              ),
              const SizedBox(height: 28),

              // My Tickets Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Active Tasks',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${myActiveTickets.length} tiket',
                    style: const TextStyle(color: AppColors.slate400, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (myActiveTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.slate600),
                      const SizedBox(height: 10),
                      const Text(
                        'Tidak ada tugas aktif.',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua tiket Anda telah diselesaikan!',
                        style: TextStyle(color: AppColors.slate500, fontSize: 12),
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
                    return _buildMyTicketCard(context, ticket);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(String label, String count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Text(
            count,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketCard(BuildContext context, dynamic ticket) {
    final priority = ticket['priority'] ?? 'LOW';
    Color priorityColor = Colors.grey;
    if (priority == 'CRITICAL') priorityColor = Colors.red;
    if (priority == 'HIGH') priorityColor = Colors.orange;
    if (priority == 'MEDIUM') priorityColor = Colors.blue;

    final status = ticket['status'] ?? 'OPEN';
    Color statusColor = Colors.grey;
    if (status == 'OPEN') statusColor = Colors.blue;
    if (status == 'IN_PROGRESS') statusColor = Colors.amber;
    if (status == 'PENDING') statusColor = Colors.purple;

    return Card(
      color: const Color(0xFF0F172A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  Text(
                    ticket['id'] ?? '',
                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket['title'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.business_rounded, size: 14, color: AppColors.slate400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${ticket['company']?['name'] ?? ''} (${ticket['company']?['location'] ?? ''})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Text(
                        ticket['requester']?['name'] ?? '',
                        style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
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
    );
  }
}
