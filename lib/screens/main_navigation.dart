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
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.slate900, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0F172A), // Dark slate
          selectedItemColor: const Color(0xFF6366F1), // Neon indigo
          unselectedItemColor: AppColors.slate400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_num_outlined),
              activeIcon: Icon(Icons.confirmation_num_rounded),
              label: 'Tickets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded),
              label: 'New Ticket',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
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
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        title: const Text('Agent Profile & KPI'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Agent Card details
            Card(
              color: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.indigo.shade900,
                      child: Text(
                        (auth.user?['name'] ?? 'A').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.user?['name'] ?? 'Agent Name',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.user?['email'] ?? 'agent@mragroup.co.id',
                      style: const TextStyle(color: AppColors.slate400, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: const Text(
                        'AGENT',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: Colors.indigo.shade600,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'My Work Statistics',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                    backgroundColor: const Color(0xFF0F172A),
                    title: const Text('Logout', style: TextStyle(color: Colors.white)),
                    content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(color: Colors.white70)),
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
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
