import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../theme/colors.dart';
import 'dashboard_screen.dart';
import 'tickets_list_screen.dart';
import 'create_ticket_screen.dart';
import 'login_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  
  late List<Widget> _screens;

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

// Temporary Profile/KPI screen placeholder to prevent routing issues
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tickets = Provider.of<TicketProvider>(context);

    // Compute basic statistics
    final myResolvedCount = tickets.tickets
        .where((t) => t['assignedToId'] == auth.user?['id'] && t['status'] == 'RESOLVED')
        .length;
    final myPendingCount = tickets.tickets
        .where((t) => t['assignedToId'] == auth.user?['id'] && t['status'] == 'PENDING')
        .length;
    final myActiveCount = tickets.tickets
        .where((t) => t['assignedToId'] == auth.user?['id'] && t['status'] == 'IN_PROGRESS')
        .length;

    return Scaffold(
      backgroundColor: AppColors.green50,
      appBar: AppBar(
        title: const Text('Agent Profile & KPI'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Agent Card details
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.slate200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.green600,
                      child: Text(
                        (auth.user?['name'] ?? 'A').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.user?['name'] ?? 'Agent Name',
                      style: const TextStyle(color: AppColors.slate900, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.user?['email'] ?? 'agent@mragroup.co.id',
                      style: const TextStyle(color: AppColors.slate500, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: const Text(
                        'AGENT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: AppColors.green600,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'My Work Statistics',
              style: TextStyle(color: AppColors.slate900, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Active Tasks', myActiveCount.toString(), Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Pending Tasks', myPendingCount.toString(), Colors.purpleAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem('Resolved Tasks', myResolvedCount.toString(), AppColors.emeraldDefault),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Logout', style: TextStyle(color: AppColors.slate900)),
                    content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(color: AppColors.slate600)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        child: const Text('Keluar'),
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
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.slate600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
