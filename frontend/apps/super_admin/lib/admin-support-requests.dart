import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'main.dart' as admin_main;

class SupportRequestsDashboard extends StatefulWidget {
  const SupportRequestsDashboard({super.key});

  @override
  State<SupportRequestsDashboard> createState() => _SupportRequestsDashboardState();
}

class _SupportRequestsDashboardState extends State<SupportRequestsDashboard> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.get(Endpoints.supportTickets);

      if (response.success) {
        List<dynamic> ticketsList = [];
        
        // Handle different response structures
        if (response.data is List) {
          ticketsList = response.data as List<dynamic>;
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap.containsKey('results')) {
            ticketsList = dataMap['results'] as List<dynamic>;
          } else if (dataMap.containsKey('data')) {
            ticketsList = dataMap['data'] as List<dynamic>;
          }
        }
        
        setState(() {
          _tickets = ticketsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to fetch tickets';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String ticketId, String newStatus) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '${Endpoints.supportTickets}$ticketId/update_status/',
        body: {'status': newStatus},
      );

      if (response.success) {
        _fetchTickets();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailsDialog(
          ticket: ticket,
          onUpdate: _fetchTickets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          const admin_main.Sidebar(initialActiveSection: 'support_requests'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support Request',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage and track all support tickets',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _fetchTickets,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007bff),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Stat Cards
                  Row(
                    children: [
                      _buildStatCard('Total Tickets', _tickets.length.toString(), Colors.blue),
                      const SizedBox(width: 20),
                      _buildStatCard('Open', _tickets.where((t) => t['status'] == 'new' || t['status'] == 'open').length.toString(), Colors.red),
                      const SizedBox(width: 20),
                      _buildStatCard('Pending', _tickets.where((t) => t['status'] == 'in_progress').length.toString(), Colors.orange),
                      const SizedBox(width: 20),
                      _buildStatCard('Resolved', _tickets.where((t) => t['status'] == 'resolved').length.toString(), Colors.green),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                      : _error != null
                          ? Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Error: $_error', style: const TextStyle(color: Colors.red))))
                          : _tickets.isEmpty
                              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No support tickets found.')))
                              : Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFe9ecef)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(
                                        const Color(0xFFF8F9FA),
                                      ),
                                      dataRowHeight: 80,
                                      horizontalMargin: 30,
                                      columnSpacing: 40,
                                      columns: const [
                                        DataColumn(label: Text('Ticket ID')),
                                        DataColumn(label: Text('School Name')),
                                        DataColumn(label: Text('User Role')),
                                        DataColumn(label: Text('Category')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('View Details')),
                                      ],
                                      rows: _tickets.map((ticket) {
                                        final status = ticket['status'] ?? 'new';
                                        
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '#${ticket['ticket_id'].toString().substring(0, 8)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007bff)),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(ticket['school_name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  Text('ID: ${ticket['school'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                                ],
                                              )
                                            ),
                                            DataCell(Text(ticket['user_role'] ?? 'Management')),
                                            DataCell(Text(ticket['category'] ?? 'N/A')),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: status == 'new'
                                                      ? Colors.blue.withOpacity(0.1)
                                                      : (status == 'resolved' || status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  (status == 'new' ? 'NEW' : (status == 'resolved' || status == 'completed' ? 'COMPLETED' : 'PENDING')),
                                                  style: TextStyle(
                                                    color: status == 'new' ? Colors.blue : (status == 'resolved' || status == 'completed' ? Colors.green : Colors.orange),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 110,
                                                child: ElevatedButton(
                                                  onPressed: () => _showTicketDetails(ticket),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF007bff),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                  ),
                                                  child: const Text('View'),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe9ecef)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onUpdate;

  const TicketDetailsDialog({
    super.key,
    required this.ticket,
    required this.onUpdate,
  });

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  final _replyController = TextEditingController();
  bool _isSubmitting = false;
  String _selectedStatus = 'new';
  String _selectedPriority = 'medium';
  late Map<String, dynamic> _ticketData;

  @override
  void initState() {
    super.initState();
    _ticketData = Map<String, dynamic>.from(widget.ticket);
    _selectedStatus = _ticketData['status'] ?? 'new';
    _selectedPriority = _ticketData['priority'] ?? 'medium';
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '${Endpoints.supportTickets}${_ticketData['ticket_id']}/reply/',
        body: {'reply': _replyController.text},
      );

      if (response.success) {
        _replyController.clear();
        
        final reFetchResponse = await apiService.get(
          '${Endpoints.supportTickets}${_ticketData['ticket_id']}/'
        );
        
        if (reFetchResponse.success && reFetchResponse.data != null) {
          setState(() {
            _ticketData = Map<String, dynamic>.from(reFetchResponse.data!);
          });
        }
        
        widget.onUpdate();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving reply: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _selectedStatus = newStatus);
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '${Endpoints.supportTickets}${_ticketData['ticket_id']}/update_status/',
        body: {'status': newStatus},
      );

      if (response.success) {
        widget.onUpdate();
        // Update local state if needed
        setState(() {
          _ticketData['status'] = newStatus;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _deleteTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: const Text('Are you sure you want to delete this ticket? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = ApiService();
        final response = await apiService.delete('${Endpoints.supportTickets}${_ticketData['ticket_id']}/');

        if (response.success) {
          widget.onUpdate();
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting ticket: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticketData;
    final ticketId = ticket['ticket_id']?.toString() ?? '';
    final shortTicketId = ticketId.length > 8 ? ticketId.substring(0, 8) : ticketId;
    final createdAtStr = ticket['created_at'];
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr).toLocal() : DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          const admin_main.Sidebar(initialActiveSection: 'support_requests'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Back Button Header instead of App Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF007bff)),
                          label: Text(
                            'Back to Support Request',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF007bff),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: Colors.blue.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Ticket Details: $shortTicketId',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Breadcrumb & Refresh
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Row(
                      children: [
                        Text(
                          'Support Requests / ',
                          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16),
                        ),
                        Text(
                          'Ticket ID: $shortTicketId',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
                    child: _buildStatusProgressBar(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTicketHeader(shortTicketId, ticket, createdAt),
                        const SizedBox(height: 24),
                        _buildTicketInfoCard(ticket),
                        const SizedBox(height: 24),
                        _buildActivitySection(ticket),
                        const SizedBox(height: 24),
                        _buildBottomActions(), // Actions section moved here
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgressBar() {
    final status = _ticketData['status'] ?? 'new';
    
    int activeStep = 0;
    if (status == 'in_progress') activeStep = 1;
    if (status == 'resolved' || status == 'completed') activeStep = 2;

    return Row(
      children: [
        _buildStatusStep('New', activeStep >= 0, activeStep == 0, 'new'),
        _buildStatusConnector(activeStep >= 1),
        _buildStatusStep('Pending', activeStep >= 1, activeStep == 1, 'in_progress'),
        _buildStatusConnector(activeStep >= 2),
        _buildStatusStep('Completed', activeStep >= 2, activeStep == 2, 'resolved'),
      ],
    );
  }

  Widget _buildStatusStep(String title, bool isCompleted, bool isActive, String statusCode) {
    return InkWell(
      onTap: () => _updateStatus(statusCode),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF007bff) : (isCompleted ? const Color(0xFF28a745) : Colors.white),
              border: Border.all(
                color: isActive || isCompleted ? Colors.transparent : const Color(0xFFdee2e6),
                width: 2,
              ),
              shape: BoxShape.circle,
              boxShadow: isActive ? [BoxShadow(color: const Color(0xFF007bff).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
            ),
            child: Center(
              child: isCompleted && !isActive
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : const Color(0xFFdee2e6),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF333333) : const Color(0xFFadb5bd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFF28a745) : const Color(0xFFdee2e6),
        margin: const EdgeInsets.only(bottom: 24),
      ),
    );
  }

  Widget _buildTicketHeader(String shortTicketId, Map<String, dynamic> ticket, DateTime createdAt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '#$shortTicketId',
              style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
            ),
            const SizedBox(width: 16),
            _buildPriorityBadge(_selectedPriority),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Text(
              'Created on ${DateFormat('MMMM dd, yyyy HH:mm').format(createdAt)}',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketInfoCard(Map<String, dynamic> ticket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ticket Information', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildInfoGrid(ticket),
          const SizedBox(height: 32),
          Text('Description', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            ticket['description'] ?? 'No description provided.',
            style: GoogleFonts.inter(color: Colors.grey[700], height: 1.6, fontSize: 15),
          ),
          const SizedBox(height: 32),
          _buildAttachedFiles(ticket),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Map<String, dynamic> ticket) {
    return Column(
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(width: 350, child: _buildGridItem('School Name:', ticket['school_name'] ?? 'N/A')),
            SizedBox(width: 350, child: _buildGridItem('School ID:', ticket['school'] ?? 'N/A')),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(width: 350, child: _buildGridItem('Principal Name:', ticket['principal_name'] ?? ticket['user_name'] ?? 'N/A')),
            SizedBox(width: 350, child: _buildGridItem('School Email:', ticket['school_email'] ?? ticket['user_email'] ?? 'N/A')),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(width: 350, child: _buildGridItem('User Role:', ticket['user_role'] ?? 'Management')),
            SizedBox(width: 350, child: _buildGridItem('Category:', ticket['category'] ?? 'N/A', isBadge: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, String value, {bool isBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 13),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(color: const Color(0xFF333333), fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  Widget _buildAttachedFiles(Map<String, dynamic> ticket) {
    final List<dynamic> attachments = ticket['attachments'] ?? [];
    final legacyAttachment = ticket['attachment'];
    
    if (attachments.isEmpty && legacyAttachment == null) return const SizedBox.shrink();

    List<String> allAttachments = attachments.map((a) => a['file'].toString()).toList();
    if (legacyAttachment != null && !allAttachments.contains(legacyAttachment.toString())) {
      allAttachments.insert(0, legacyAttachment.toString());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Attached Files',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allAttachments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final String url = allAttachments[index];
              final String fullUrl = url.startsWith('http') ? url : 'http://127.0.0.1:8000$url';
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SupportImageGallery(
                      images: allAttachments,
                      initialIndex: index,
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(Map<String, dynamic> ticket) {
    final List<dynamic> replies = ticket['replies'] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F3F5))),
            ),
            child: Row(
              children: [
                _buildTab('Ticket Actions', Icons.history, true),
                const SizedBox(width: 24),
                _buildTab('Replies', Icons.chat_bubble_outline, false),
                const Spacer(),
                Icon(Icons.ios_share, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
          // Reply Input
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      onSubmitted: (_) => _isSubmitting ? null : _submitReply(),
                      decoration: InputDecoration(
                        hintText: 'Reply to ${ticket['school_name'] ?? 'School'}... (Visible to school)',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSubmitting ? null : _submitReply,
                    icon: _isSubmitting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 18),
                    label: const Text('Send'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF007bff)),
                  ),
                ],
              ),
            ),
          ),
          // History
          _buildMessageItem(
            'Management',
            'Original Request',
            ticket['description'] ?? '',
            true,
          ),
          // Display dynamic replies
          ...replies.map((reply) {
             final senderRole = reply['sender_role'] ?? 'SuperAdmin';
             final createdAt = DateTime.parse(reply['created_at']).toLocal();
             final timeStr = DateFormat('MMM dd, hh:mm a').format(createdAt);
             
             return _buildMessageItem(
               senderRole == 'Management' ? 'Management' : 'Super Admin',
               timeStr,
               reply['message'] ?? '',
               senderRole == 'Management',
             );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, bool isActive) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isActive ? const Color(0xFF333333) : Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF333333) : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(String sender, String time, String message, bool isManagement) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isManagement ? Colors.blue[50] : Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isManagement ? Icons.school_outlined : Icons.admin_panel_settings_outlined,
              color: isManagement ? Colors.blue[600] : Colors.purple[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sender,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $time',
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.inter(color: Colors.grey[700], height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAttachment(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(name, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket Management Actions',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 32,
            runSpacing: 24,
            children: [
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSidebarLabel('Update Status:'),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: _sidebarInputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('New')),
                        DropdownMenuItem(value: 'in_progress', child: Text('Pending')),
                        DropdownMenuItem(value: 'resolved', child: Text('Completed')),
                      ],
                      onChanged: (value) => value != null ? _updateStatus(value) : null,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSidebarLabel('Set Priority:'),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: _sidebarInputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (value) => value != null ? setState(() => _selectedPriority = value) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus('resolved'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark Ticket as Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _deleteTicket,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w500),
      ),
    );
  }

  InputDecoration _sidebarInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildModernBadge(String text, Color bgColor, Color textColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: textColor), const SizedBox(width: 8)],
          Text(text, style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = Colors.orange;
    if (priority == 'high' || priority == 'urgent') color = Colors.red;
    return _buildModernBadge(priority.toUpperCase(), color.withOpacity(0.1), color, icon: Icons.flag);
  }
}

class SupportImageGallery extends StatefulWidget {
  final List<dynamic> images; // Can be List<XFile> or List<String> (URLs)
  final int initialIndex;
  final bool isXFile;

  const SupportImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.isXFile = false,
  });

  @override
  State<SupportImageGallery> createState() => _SupportImageGalleryState();
}

class _SupportImageGalleryState extends State<SupportImageGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                AppBar(
                  title: Text('Image ${_currentIndex + 1} of ${widget.images.length}'),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final image = widget.images[index];
                      if (widget.isXFile) {
                        return FutureBuilder<Uint8List>(
                          future: (image as XFile).readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return InteractiveViewer(
                                child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        );
                      } else {
                        final String url = image.toString();
                        final String fullUrl = url.startsWith('http') ? url : 'http://127.0.0.1:8000$url';
                        return InteractiveViewer(
                          child: Image.network(
                            fullUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: _currentIndex > 0 
                          ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                          : null,
                      ),
                      const SizedBox(width: 40),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onPressed: _currentIndex < widget.images.length - 1
                          ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                          : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

