import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/colors.dart';
import 'ticket_detail_screen.dart';

// Admin-only view: per-agent workload, SLA compliance, and unassigned tickets.
class TeamReportScreen extends StatefulWidget {
  const TeamReportScreen({super.key});

  @override
  State<TeamReportScreen> createState() => _TeamReportScreenState();
}

class _TeamReportScreenState extends State<TeamReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProv = Provider.of<TicketProvider>(context, listen: false);
      ticketProv.fetchTickets();
      ticketProv.fetchMasterData();
    });
  }

  static bool _isActive(dynamic ticket) {
    final status = ticket['status'] ?? 'OPEN';
    return status == 'OPEN' || status == 'IN_PROGRESS' || status == 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    final ticketProv = Provider.of<TicketProvider>(context);
    final tickets = ticketProv.tickets;
    final agents = ticketProv.agents;

    final agentStats = agents.map((agent) {
      final agentId = agent['id'];
      final agentTickets = tickets.where((t) => t['assignedToId'] == agentId).toList();
      final active = agentTickets.where(_isActive).toList();
      final resolved = agentTickets.where((t) => t['status'] == 'RESOLVED').toList();
      final breached = resolved.where((t) => t['isSlaBreached'] == true).length;
      final double? compliance =
          resolved.isEmpty ? null : ((resolved.length - breached) / resolved.length) * 100;

      return {
        'agent': agent,
        'active': active,
        'resolvedCount': resolved.length,
        'compliance': compliance,
      };
    }).toList()
      ..sort((a, b) => (b['active'] as List).length.compareTo((a['active'] as List).length));

    final unassignedTickets = tickets.where((t) => t['assignedToId'] == null).toList();
    final totalActive = tickets.where(_isActive).length;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'LAPORAN TIM',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ticketProv.fetchTickets(),
        color: AppColors.green600,
        backgroundColor: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Agent',
                    agents.length.toString(),
                    AppColors.green600,
                    Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'Tiket Aktif',
                    totalActive.toString(),
                    const Color(0xFF2563EB),
                    Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryCard(
                    'Belum Ditugaskan',
                    unassignedTickets.length.toString(),
                    unassignedTickets.isEmpty ? AppColors.slate400 : Colors.red,
                    Icons.person_off_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (unassignedTickets.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${unassignedTickets.length} Tiket Belum Ditugaskan',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...unassignedTickets.map((t) => _buildMiniTicketRow(context, t)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'BEBAN KERJA PER AGENT',
              style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            if (agentStats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Belum ada data agent.', style: TextStyle(color: AppColors.slate400)),
                ),
              )
            else
              ...agentStats.map((stat) => _buildAgentCard(context, stat)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: AppColors.slate300.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate500, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, Map<String, dynamic> stat) {
    final agent = stat['agent'] as Map;
    final activeTickets = stat['active'] as List;
    final resolvedCount = stat['resolvedCount'] as int;
    final compliance = stat['compliance'] as double?;
    final String name = (agent['name'] ?? 'Agent').toString();
    final String department = (agent['department'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(color: AppColors.slate300.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.green100,
            child: Text(
              name.isEmpty ? 'A' : name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.green700, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(name, style: const TextStyle(color: AppColors.slate900, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(department, style: const TextStyle(color: AppColors.slate500, fontSize: 11.5)),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeTickets.isEmpty ? AppColors.slate100 : AppColors.green50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activeTickets.length} aktif',
                  style: TextStyle(
                    color: activeTickets.isEmpty ? AppColors.slate500 : AppColors.green700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                compliance == null ? 'SLA: -' : 'SLA: ${compliance.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: compliance == null ? AppColors.slate400 : (compliance >= 80 ? AppColors.green700 : Colors.orange),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: [
            if (activeTickets.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tidak ada tiket aktif.', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                ),
              )
            else
              ...activeTickets.map((t) => _buildMiniTicketRow(context, t)),
            const Divider(color: AppColors.slate200, height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Resolved: $resolvedCount tiket',
                style: const TextStyle(color: AppColors.slate500, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTicketRow(BuildContext context, dynamic ticket) {
    final status = ticket['status'] ?? 'OPEN';
    Color statusColor = Colors.blue;
    if (status == 'IN_PROGRESS') statusColor = Colors.amber.shade800;
    if (status == 'PENDING') statusColor = Colors.purple;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket['id'])),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ticket['title'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate800, fontSize: 12.5),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
