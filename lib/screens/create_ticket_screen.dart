import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../services/ticket_service.dart';
import '../theme/colors.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requesterSearchController = TextEditingController();
  final _customSubCategoryController = TextEditingController();

  Map<String, dynamic>? _selectedRequester;
  String _selectedCategory = 'Hardware';
  String _selectedSubCategory = '';
  String _selectedPriority = 'LOW';
  String _selectedSource = 'Walk-in';
  
  bool _isSearchingRequester = false;
  List<dynamic> _requesterSearchResults = [];
  Timer? _debounceTimer;

  bool _submitting = false;

  final List<String> _categoriesList = ['Hardware', 'Software', 'Network', 'Access', 'ERP'];
  final List<String> _prioritiesList = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  final List<String> _sourcesList = [
    'Walk-in',
    'Email',
    'Phone Call',
    'Instant Messaging (WhatsApp/Telegram)',
    'Direct Instruction',
    'On-site Visit',
    'System Alert',
    'Self-Service Portal'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requesterSearchController.dispose();
    _customSubCategoryController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Debounced search for requesters
  void _onRequesterSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    if (query.trim().length < 2) {
      setState(() {
        _requesterSearchResults = [];
        _isSearchingRequester = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearchingRequester = true);
      try {
        final results = await TicketService.searchUsers(query);
        setState(() {
          _requesterSearchResults = results;
        });
      } catch (e) {
        // Handle error silently
      } finally {
        setState(() => _isSearchingRequester = false);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRequester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the reporter (requester)!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    String subCat = _selectedSubCategory;
    if (subCat == 'CUSTOM_ADD' || subCat.isEmpty) {
      subCat = _customSubCategoryController.text.trim();
      if (subCat.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sub-category is required!'), backgroundColor: Colors.redAccent),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    final Map<String, dynamic> ticketData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'subCategory': subCat,
      'priority': _selectedPriority,
      'source': _selectedSource,
      'companyId': _selectedRequester!['companyId'],
      'requesterId': _selectedRequester!['id'],
    };

    try {
      final ticketProv = Provider.of<TicketProvider>(context, listen: false);
      await ticketProv.createTicket(ticketData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully!'), backgroundColor: AppColors.emeraldDefault),
        );
        
        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        _requesterSearchController.clear();
        _customSubCategoryController.clear();
        
        setState(() {
          _selectedRequester = null;
          _selectedCategory = 'Hardware';
          _selectedSubCategory = '';
          _selectedPriority = 'LOW';
          _selectedSource = 'Walk-in';
          _requesterSearchResults = [];
        });
        
        ticketProv.fetchTickets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProv = Provider.of<TicketProvider>(context);

    // Get subcategories filtered by selectedCategory
    final filteredSubCategories = ticketProv.categories
        .where((c) => c['category'] == _selectedCategory)
        .map((c) => c['subCategory'] as String)
        .toSet()
        .toList();

    // Handle initial state of subcategory dropdown
    if (_selectedSubCategory.isEmpty && filteredSubCategories.isNotEmpty) {
      _selectedSubCategory = filteredSubCategories.first;
    } else if (_selectedSubCategory.isNotEmpty && 
               !filteredSubCategories.contains(_selectedSubCategory) && 
               _selectedSubCategory != 'CUSTOM_ADD') {
      _selectedSubCategory = filteredSubCategories.isNotEmpty ? filteredSubCategories.first : '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        title: const Text('Create New Ticket'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Requester Selection Search box
              const Text('REPORTER / REQUESTER', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_selectedRequester == null) ...[
                TextFormField(
                  controller: _requesterSearchController,
                  onChanged: _onRequesterSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type name, email, or employee ID...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: _isSearchingRequester 
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
                
                // Requester Search Results Dropdown overlay
                if (_requesterSearchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate800),
                    ),
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _requesterSearchResults.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final user = _requesterSearchResults[index];
                        return ListTile(
                          dense: true,
                          title: Text(user['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${user['jobPosition'] ?? ''} - ${user['company']?['name'] ?? ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedRequester = user;
                              _requesterSearchResults = [];
                              _requesterSearchController.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
              ] else ...[
                // Selected Reporter display card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.indigo.shade900,
                        child: Text(
                          (_selectedRequester!['name'] as String).substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRequester!['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${_selectedRequester!['department'] ?? ''} @ ${_selectedRequester!['company']?['name'] ?? ''} (${_selectedRequester!['company']?['location'] ?? ''})',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _selectedRequester = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),

              // Title input
              const Text('TICKET TITLE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Example: Outlook email syncing issue',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ticket title is required';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Selection Dropdown
              const Text('CATEGORY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF0F172A),
                value: _selectedCategory,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                ),
                items: _categoriesList.map((c) {
                  return DropdownMenuItem<String>(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val ?? 'Hardware';
                    _selectedSubCategory = ''; // Reset subcategory selection
                  });
                },
              ),
              const SizedBox(height: 24),

              // Sub-Category Selection Dropdown
              const Text('DETAILED ISSUE (SUB-CATEGORY)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF0F172A),
                value: _selectedSubCategory.isEmpty ? null : _selectedSubCategory,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                ),
                items: [
                  ...filteredSubCategories.map((s) {
                    return DropdownMenuItem<String>(value: s, child: Text(s));
                  }),
                  const DropdownMenuItem<String>(
                    value: 'CUSTOM_ADD',
                    child: Text('+ Add New Sub-Category...', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedSubCategory = val ?? '';
                  });
                },
              ),
              
              // Custom SubCategory text input if '+ Add custom detailing' is selected
              if (_selectedSubCategory == 'CUSTOM_ADD') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customSubCategoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type new sub-category name...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                  validator: (value) {
                    if (_selectedSubCategory == 'CUSTOM_ADD' && (value == null || value.trim().isEmpty)) {
                      return 'Custom sub-category name is required';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 24),

              // Priority Selection Dropdown
              const Text('PRIORITY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF0F172A),
                value: _selectedPriority,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                ),
                items: _prioritiesList.map((p) {
                  return DropdownMenuItem<String>(value: p, child: Text(p));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPriority = val ?? 'LOW';
                  });
                },
              ),
              const SizedBox(height: 24),

              // Source Selection Dropdown
              const Text('REPORT SOURCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF0F172A),
                value: _selectedSource,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                ),
                items: _sourcesList.map((s) {
                  return DropdownMenuItem<String>(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSource = val ?? 'Walk-in';
                  });
                },
              ),
              const SizedBox(height: 24),

              // Description input
              const Text('DESCRIPTION', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write a detailed description of the IT issue...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.slate900)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // Submit Button
              ElevatedButton(
                onPressed: _submitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SUBMIT TICKET',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
