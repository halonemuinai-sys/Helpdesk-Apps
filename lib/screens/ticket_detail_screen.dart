import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../services/ticket_service.dart';
import '../theme/colors.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Map<String, dynamic>? _ticket;
  bool _loading = true;
  String? _error;
  Timer? _slaTimer;
  String _slaText = '';
  bool _isSlaBreached = false;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
    // Start ticking SLA countdown timer every second
    _slaTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateSlaCountdown());
  }

  @override
  void dispose() {
    _slaTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await TicketService.fetchTicketById(widget.ticketId);
      setState(() {
        _ticket = details;
        _loading = false;
      });
      _updateSlaCountdown();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _updateSlaCountdown() {
    if (_ticket == null) return;

    final String status = _ticket!['status'] ?? 'OPEN';
    
    // If ticket is already RESOLVED or CLOSED, we stop counting down and display the final state
    if (status == 'RESOLVED' || status == 'CLOSED') {
      final bool breached = _ticket!['isSlaBreached'] ?? false;
      setState(() {
        _isSlaBreached = breached;
        _slaText = breached ? 'Breached (Terlambat)' : 'Met (Tepat Waktu)';
      });
      return;
    }

    // Determine target limit
    final String limitStr = (status == 'OPEN') 
        ? _ticket!['slaResponseLimit'] 
        : _ticket!['slaResolutionLimit'];
    
    if (limitStr.isEmpty) return;

    final targetTime = DateTime.parse(limitStr);
    final now = DateTime.now();

    // Adjust for paused time if currently PENDING
    if (status == 'PENDING') {
      setState(() {
        _isSlaBreached = _ticket!['isSlaBreached'] ?? false;
        _slaText = 'SLA Paused (Tertunda)';
      });
      return;
    }

    final difference = targetTime.difference(now);

    if (difference.isNegative) {
      setState(() {
        _isSlaBreached = true;
        _slaText = 'Breached (Terlampaui)';
      });
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);
      
      setState(() {
        _isSlaBreached = false;
        _slaText = '${hours}j ${minutes}m ${seconds}d';
      });
    }
  }

  Future<void> _handleTakeOver() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;
    
    setState(() => _loading = true);
    try {
      await TicketService.assignTicket(widget.ticketId, auth.user!['id']);
      // Refresh local list state
      if (mounted) {
        Provider.of<TicketProvider>(context, listen: false).fetchTickets();
        await _loadTicketDetails();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleAssignAgent() async {
    final ticketsProv = Provider.of<TicketProvider>(context, listen: false);
    final selectedAgent = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Assign Agent', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ticketsProv.agents.length,
              itemBuilder: (context, index) {
                final agent = ticketsProv.agents[index];
                return ListTile(
                  title: Text(agent['name'] ?? '', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(agent['department'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context, agent['id']);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedAgent != null && mounted) {
      setState(() => _loading = true);
      try {
        await TicketService.assignTicket(widget.ticketId, selectedAgent);
        if (mounted) {
          Provider.of<TicketProvider>(context, listen: false).fetchTickets();
          await _loadTicketDetails();
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _handleUpdateStatus(String newStatus) async {
    // If pending or resolved, require comments
    String? comment;
    if (newStatus == 'PENDING' || newStatus == 'RESOLVED') {
      final commentController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: Text(newStatus == 'PENDING' ? 'Pause SLA (Pending)' : 'Selesaikan Tiket (Resolved)', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  newStatus == 'PENDING' 
                      ? 'Tulis alasan penundaan tiket:' 
                      : 'Tulis solusi penyelesaian masalah:',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.slate900,
                    hintText: 'Tulis di sini...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              TextButton(
                onPressed: () {
                  if (commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catatan wajib diisi!'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Kirim'),
              ),
            ],
          );
        },
      );
      
      if (confirm != true) return;
      comment = commentController.text.trim();
    }

    if (mounted) {
      setState(() => _loading = true);
      try {
        await TicketService.updateStatus(widget.ticketId, newStatus, comment: comment);
        if (mounted) {
          Provider.of<TicketProvider>(context, listen: false).fetchTickets();
          await _loadTicketDetails();
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _handleUpdatePriority() async {
    final List<String> priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    final selectedPriority = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Ubah Prioritas', style: TextStyle(color: Colors.white)),
          children: priorities.map((p) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedPriority != null && mounted) {
      setState(() => _loading = true);
      try {
        await TicketService.updatePriority(widget.ticketId, selectedPriority);
        if (mounted) {
          Provider.of<TicketProvider>(context, listen: false).fetchTickets();
          await _loadTicketDetails();
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  void _showErrorSnackBar(String err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err.replaceAll('Exception: ', '')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    if (_loading && _ticket == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        appBar: AppBar(title: const Text('Detail Tiket'), backgroundColor: const Color(0xFF0F172A)),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        appBar: AppBar(title: const Text('Detail Tiket'), backgroundColor: const Color(0xFF0F172A)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _loadTicketDetails, child: const Text('Coba Lagi')),
              ],
            ),
          ),
        ),
      );
    }

    final ticket = _ticket!;
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
    if (status == 'RESOLVED') statusColor = AppColors.emeraldDefault;
    if (status == 'CLOSED') statusColor = Colors.grey;

    final createdTime = DateTime.parse(ticket['createdAt']);
    final formattedCreated = DateFormat('dd MMM yyyy, HH:mm').format(createdTime);

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        title: Text(ticket['id'] ?? 'Detail Tiket'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Area with Title & Status Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: priorityColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  ticket['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Created on: $formattedCreated via ${ticket['source'] ?? 'Walk-in'}',
                  style: const TextStyle(color: AppColors.slate400, fontSize: 12),
                ),
                const SizedBox(height: 20),

                // SLA Countdown Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSlaBreached 
                          ? Colors.redAccent.withOpacity(0.4) 
                          : Colors.indigo.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSlaBreached ? Icons.warning_amber_rounded : Icons.alarm,
                        color: _isSlaBreached ? Colors.redAccent : const Color(0xFF818CF8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == 'OPEN' ? 'Response SLA Target' : 'Resolution SLA Target',
                              style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _slaText,
                              style: TextStyle(
                                color: _isSlaBreached ? Colors.redAccent : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                const Text('DESCRIPTION', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket['description'] ?? '-',
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),

                // Kategori & Sub-Kategori
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaField('CATEGORY', ticket['category'] ?? '-'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetaField('SUB-CATEGORY', ticket['subCategory'] ?? '-'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Employee / Requester Card
                const Text('REPORTER INFO', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildContactRow(Icons.person, ticket['requester']?['name'] ?? '-'),
                      const Divider(color: Colors.white10, height: 16),
                      _buildContactRow(Icons.business_rounded, '${ticket['company']?['name'] ?? '-'} (${ticket['company']?['location'] ?? ''})'),
                      const Divider(color: Colors.white10, height: 16),
                      _buildContactRow(Icons.work_outline, '${ticket['requester']?['jobPosition'] ?? '-'} (${ticket['requester']?['department'] ?? ''})'),
                      const Divider(color: Colors.white10, height: 16),
                      _buildContactRow(Icons.email_outlined, ticket['requester']?['email'] ?? '-'),
                      if (ticket['requester']?['phone'] != null && (ticket['requester']?['phone'] as String).isNotEmpty) ...[
                        const Divider(color: Colors.white10, height: 16),
                        _buildContactRow(Icons.phone_iphone_outlined, ticket['requester']?['phone']),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Assignment details
                const Text('ASSIGNMENT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_ind_outlined, color: Colors.indigo.shade300),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ticket['assignedTo'] != null 
                              ? 'Assigned to: ${ticket['assignedTo']['name']}' 
                              : 'Unassigned (Belum ditugaskan)',
                          style: TextStyle(
                            color: ticket['assignedTo'] != null ? Colors.white : Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Audit Trail Timeline
                const Text('ACTIVITY LOG', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildAuditTimeline(ticket['auditLogs'] ?? []),
              ],
            ),
          ),

          // Bottom Action Panel
          if (!_loading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: const Color(0xFF0F172A),
                child: Row(
                  children: _buildActionButtons(auth),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.slate400),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTimeline(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Text('Belum ada aktivitas.', style: TextStyle(color: Colors.white54, fontSize: 13));
    }
    
    // Sort logs descending to show latest first
    final sortedLogs = List.from(logs)..sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedLogs.length,
      itemBuilder: (context, index) {
        final log = sortedLogs[index];
        final time = DateTime.parse(log['createdAt']);
        final formattedTime = DateFormat('dd/MM, HH:mm').format(time);
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                ),
                if (index < sortedLogs.length - 1)
                  Container(
                    width: 2,
                    height: 50,
                    color: AppColors.slate700,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log['action']?.replaceAll('_', ' ') ?? 'UPDATED',
                        style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formattedTime,
                        style: const TextStyle(color: AppColors.slate400, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['details'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Oleh: ${log['performedBy']}',
                    style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildActionButtons(AuthProvider auth) {
    final String status = _ticket!['status'] ?? 'OPEN';
    final String? assignedToId = _ticket!['assignedToId'];
    final String currentUserId = auth.user?['id'] ?? '';
    
    final List<Widget> buttons = [];

    // Case 1: Unassigned Ticket
    if (assignedToId == null) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleTakeOver,
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Ambil Alih (Takeover)', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      );
      
      // Admin/Auditor can also assign to other agents directly
      if (auth.user?['role'] == 'ADMIN') {
        buttons.add(const SizedBox(width: 12));
        buttons.add(
          ElevatedButton(
            onPressed: _handleAssignAgent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.slate800,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
          ),
        );
      }
    } else {
      // Case 2: Ticket assigned, but not resolved/closed
      if (status != 'RESOLVED' && status != 'CLOSED') {
        // If assigned to current user, they can update status
        if (assignedToId == currentUserId || auth.user?['role'] == 'ADMIN') {
          if (status == 'OPEN') {
            buttons.add(
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleUpdateStatus('IN_PROGRESS'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Proses (Start)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            );
          } else if (status == 'IN_PROGRESS') {
            buttons.add(
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleUpdateStatus('PENDING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Pause (Pending)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            );
            buttons.add(const SizedBox(width: 12));
            buttons.add(
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleUpdateStatus('RESOLVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldDefault,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Selesaikan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            );
          } else if (status == 'PENDING') {
            buttons.add(
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleUpdateStatus('IN_PROGRESS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Lanjutkan (Resume)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            );
          }
        }
        
        // Reassignment and Priority changes are always allowed for agents/admins
        buttons.add(const SizedBox(width: 12));
        buttons.add(
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: AppColors.slate850, padding: const EdgeInsets.all(12)),
            onPressed: _handleAssignAgent,
            tooltip: 'Reassign Agent',
          ),
        );
        
        buttons.add(const SizedBox(width: 8));
        buttons.add(
          IconButton(
            icon: const Icon(Icons.outlined_flag, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: AppColors.slate850, padding: const EdgeInsets.all(12)),
            onPressed: _handleUpdatePriority,
            tooltip: 'Change Priority',
          ),
        );
      } else {
        // Ticket is RESOLVED or CLOSED
        buttons.add(
          const Expanded(
            child: Center(
              child: Text(
                'Tiket ini telah selesai / ditutup.',
                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
          ),
        );
      }
    }

    return buttons;
  }
}
