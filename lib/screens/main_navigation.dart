import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../services/biometric_service.dart';
import '../theme/colors.dart';
import 'dashboard_screen.dart';
import 'tickets_list_screen.dart';
import 'create_ticket_screen.dart';
import 'login_screen.dart';
import 'ticket_detail_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  StreamSubscription<Map<String, dynamic>>? _newTicketSubscription;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const TicketsListScreen(),
      const CreateTicketScreen(),
      const ProfileScreen(),
    ];

    // Trigger initial fetching of master data and initialize real-time SSE listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final tickets = Provider.of<TicketProvider>(context, listen: false);
      
      if (auth.token != null) {
        tickets.initRealtime(auth.token!);
      }
      tickets.fetchMasterData();

      // Listen to new ticket alerts globally
      _newTicketSubscription = tickets.onNewTicket.listen((ticket) {
        _showNewTicketOverlay(ticket);
      });
    });
  }

  @override
  void dispose() {
    _newTicketSubscription?.cancel();
    super.dispose();
  }

  void _showNewTicketOverlay(Map<String, dynamic> ticket) {
    if (!mounted) return;

    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(0, -60 * (1 - val)),
                child: Opacity(
                  opacity: val,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Light backdrop
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green500, width: 2), // Green border
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate400.withOpacity(0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      if (overlayEntry != null) {
                        overlayEntry!.remove();
                        overlayEntry = null;
                      }
                      // Navigate to ticket detail screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticketId: ticket['id']),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.green100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: AppColors.green600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'NEW TICKET RECEIVED',
                                  style: TextStyle(
                                    color: AppColors.green600, 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold, 
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket['title'] ?? 'No Title',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.slate900, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Reporter: ${ticket['requester']?['name'] ?? 'Unknown'}',
                                  style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.slate400, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry!);

    // Automatically remove overlay after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate400.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? AppColors.green700 : AppColors.slate400,
                  );
                }),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              height: 68,
              indicatorColor: AppColors.green100,
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined, color: AppColors.slate400),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.green700),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_num_outlined, color: AppColors.slate400),
                  selectedIcon: Icon(Icons.confirmation_num_rounded, color: AppColors.green700),
                  label: 'Tickets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.slate400),
                  selectedIcon: Icon(Icons.add_circle_rounded, color: AppColors.green700),
                  label: 'New Ticket',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded, color: AppColors.slate400),
                  selectedIcon: Icon(Icons.person_rounded, color: AppColors.green700),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Profile & Agent KPI Dashboard Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tickets = Provider.of<TicketProvider>(context);

    final currentAgentId = auth.user?['id'];

    // Compute basic statistics
    final myActiveCount = tickets.tickets
        .where((t) => t['assignedToId'] == currentAgentId && (t['status'] == 'OPEN' || t['status'] == 'IN_PROGRESS'))
        .length;
    final myPendingCount = tickets.tickets
        .where((t) => t['assignedToId'] == currentAgentId && t['status'] == 'PENDING')
        .length;
    final myResolvedCount = tickets.tickets
        .where((t) => t['assignedToId'] == currentAgentId && t['status'] == 'RESOLVED')
        .length;

    // Compute Personal KPI / SLA Performance details
    final myTickets = tickets.tickets.where((t) => t['assignedToId'] == currentAgentId).toList();
    final myResolvedTickets = myTickets.where((t) => t['status'] == 'RESOLVED').toList();
    final totalResolved = myResolvedTickets.length;
    final breachedCount = myResolvedTickets.where((t) => t['isSlaBreached'] == true).length;
    final metCount = totalResolved - breachedCount;
    final slaComplianceRate = totalResolved == 0
        ? 100.0
        : (metCount / totalResolved) * 100;
    final weeklyBuckets = _computeWeeklyBuckets(myTickets);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'AGENT PROFILE & KPI',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Agent Header Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slate300.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.green500, AppColors.green300],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        (auth.user?['name'] ?? 'A').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.green700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    auth.user?['name'] ?? 'Agent Name',
                    style: const TextStyle(color: AppColors.slate900, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.user?['email'] ?? 'agent@mragroup.co.id',
                    style: const TextStyle(color: AppColors.slate500, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.green50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.green200),
                    ),
                    child: Text(
                      (auth.user?['role'] ?? 'AGENT').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.green700, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Header
            const Text(
              'MY WORK STATISTICS',
              style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            
            // Statistics Grid Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Active', myActiveCount.toString(), const Color(0xFF3B82F6), Icons.play_circle_outline_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Pending', myPendingCount.toString(), const Color(0xFFA855F7), Icons.pause_circle_outline_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Resolved', myResolvedCount.toString(), const Color(0xFF10B981), Icons.check_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Personal SLA KPI Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.green200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slate300.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
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
                            'MY SLA PERFORMANCE',
                            style: TextStyle(
                              color: AppColors.green700, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Personal target compliance rate',
                            style: TextStyle(color: AppColors.slate500, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${slaComplianceRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: slaComplianceRate >= 80 ? AppColors.green700 : Colors.orange,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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
                      backgroundColor: AppColors.slate100,
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
            const SizedBox(height: 20),

            // Quick login preference
            _buildBiometricToggle(context, auth),
            const SizedBox(height: 20),

            // Weekly performance trends
            const Text(
              'PERFORMA MINGGUAN',
              style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            _buildWeeklyVolumeChart(weeklyBuckets),
            const SizedBox(height: 14),
            _buildWeeklyComplianceChart(weeklyBuckets),
            const SizedBox(height: 28),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Sign Out', style: TextStyle(color: AppColors.slate900, fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to sign out of the application?', style: TextStyle(color: AppColors.slate600)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.slate500)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  await auth.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricToggle(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate300.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: auth.biometricEnabled,
        activeThumbColor: AppColors.green600,
        onChanged: (value) async {
          if (value) {
            final supported = await BiometricService.isDeviceSupported();
            if (!supported) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perangkat ini tidak mendukung biometric/PIN.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              return;
            }
            final verified = await BiometricService.authenticate(
              reason: 'Verifikasi untuk mengaktifkan login cepat',
            );
            if (!verified) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verifikasi dibatalkan.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              return;
            }
          }
          await auth.setBiometricEnabled(value);
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.green50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fingerprint, color: AppColors.green600),
        ),
        title: const Text(
          'Login Cepat (Biometric/PIN)',
          style: TextStyle(color: AppColors.slate900, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: const Text(
          'Buka workspace tanpa mengetik ulang password',
          style: TextStyle(color: AppColors.slate500, fontSize: 11.5),
        ),
      ),
    );
  }

  // Buckets the agent's tickets into the last 6 weeks (by createdAt), computing
  // per-week volume and SLA compliance among tickets already resolved in that week.
  List<Map<String, dynamic>> _computeWeeklyBuckets(List<dynamic> myTickets) {
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return List.generate(6, (i) {
      final index = 5 - i;
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * index));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final ticketsInWeek = myTickets.where((t) {
        final created = DateTime.tryParse(t['createdAt']?.toString() ?? '');
        if (created == null) return false;
        return !created.isBefore(weekStart) && created.isBefore(weekEnd);
      }).toList();

      final resolvedInWeek = ticketsInWeek.where((t) => t['status'] == 'RESOLVED').toList();
      final breachedInWeek = resolvedInWeek.where((t) => t['isSlaBreached'] == true).length;
      final double? compliance = resolvedInWeek.isEmpty
          ? null
          : ((resolvedInWeek.length - breachedInWeek) / resolvedInWeek.length) * 100;

      return {
        'label': DateFormat('dd/MM').format(weekStart),
        'count': ticketsInWeek.length,
        'compliance': compliance,
      };
    });
  }

  Widget _buildWeeklyVolumeChart(List<Map<String, dynamic>> buckets) {
    final maxCount = buckets
        .map((b) => b['count'] as int)
        .fold(0, (prev, curr) => curr > prev ? curr : prev);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate300.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIKET DITANGANI PER MINGGU',
            style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets.map((b) {
              final count = b['count'] as int;
              final barHeight = (count / safeMax) * 64;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
                      ),
                      const SizedBox(height: 4),
                      Tooltip(
                        message: '${b['label']}: $count tiket',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: barHeight < 4 ? 4 : barHeight,
                          decoration: const BoxDecoration(
                            color: AppColors.green600,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b['label'] as String,
                        style: const TextStyle(fontSize: 9, color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyComplianceChart(List<Map<String, dynamic>> buckets) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate300.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEPATUHAN SLA PER MINGGU',
            style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Persentase tiket resolved yang tepat waktu (dikelompokkan per minggu dibuat)',
            style: TextStyle(color: AppColors.slate400, fontSize: 10.5),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets.map((b) {
              final compliance = b['compliance'] as double?;
              final barColor = compliance == null
                  ? AppColors.slate200
                  : (compliance >= 80 ? AppColors.green600 : Colors.orange);
              final barHeight = compliance == null ? 4.0 : ((compliance / 100) * 64).clamp(4.0, 64.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        compliance == null ? '-' : '${compliance.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
                      ),
                      const SizedBox(height: 4),
                      Tooltip(
                        message: compliance == null
                            ? '${b['label']}: belum ada tiket resolved'
                            : '${b['label']}: ${compliance.toStringAsFixed(1)}% SLA compliance',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b['label'] as String,
                        style: const TextStyle(fontSize: 9, color: AppColors.slate400),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate300.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
