import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import '../widgets/management_sidebar.dart';
import '../management_routes.dart';
import 'package:intl/intl.dart';
import '../widgets/school_profile_header.dart';
import '../dashboard.dart';

class SupportRequestPage extends StatefulWidget {
  const SupportRequestPage({super.key});

  @override
  State<SupportRequestPage> createState() => _SupportRequestPageState();
}

class _SupportRequestPageState extends State<SupportRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Technical Issue';
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Technical Issue',
    'Billing Issue',
    'Feature Request',
    'Bug Report',
    'Other',
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _viewImages({int initialIndex = 0}) {
    if (_selectedImages.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => SupportImageGallery(
        images: _selectedImages,
        initialIndex: initialIndex,
        isXFile: true,
      ),
    );
  }


  List<Map<String, dynamic>> _ticketHistory = [];
  int _totalTickets = 0;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchTicketHistory();
  }

  Future<void> _fetchTicketHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final apiService = ApiService();
      final response = await apiService.get(Endpoints.supportTickets);
      debugPrint('Ticket History Response: ${response.success}, ${response.data}');
      
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            // Handle both raw list and paginated response (Map with results key)
            if (response.data is List) {
              _ticketHistory = List<Map<String, dynamic>>.from(response.data);
              _totalTickets = _ticketHistory.length;
            } else if (response.data is Map && response.data['results'] is List) {
              _ticketHistory = List<Map<String, dynamic>>.from(response.data['results']);
              _totalTickets = response.data['count'] ?? _ticketHistory.length;
            } else {
              debugPrint('Unexpected response format: ${response.data.runtimeType}');
              _ticketHistory = [];
              _totalTickets = 0;
            }
          });
        } else {
          debugPrint('Failed to fetch ticket history: ${response.error}');
        }
      }
    } catch (e) {
      debugPrint('Error fetching ticket history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Ticket Details',
      pageBuilder: (context, animation, secondaryAnimation) => ManagementTicketDetailsDialog(
        ticket: ticket,
        onUpdate: _fetchTicketHistory,
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final apiService = ApiService();
      
      Map<String, String> fields = {
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'user_role': 'Management',
      };

      ApiResponse response;
      if (_selectedImages.isNotEmpty) {
        List<Uint8List> fileBytesList = [];
        List<String> fileNames = [];
        for (var image in _selectedImages) {
          fileBytesList.add(await image.readAsBytes());
          fileNames.add(image.name);
        }

        response = await apiService.uploadFiles(
          Endpoints.supportTickets,
          fileBytesList: fileBytesList,
          fileNames: fileNames,
          fieldName: 'attachments',
          additionalFields: fields,
        );
      } else {
        response = await apiService.post(
          Endpoints.supportTickets,
          body: fields,
        );
      }

      if (mounted) {
        if (response.success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.green[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                   Icon(Icons.check_circle, color: Colors.green, size: 28),
                   SizedBox(width: 12),
                   Text('Success', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Support ticket submitted successfully! Our team will get back to you soon.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Great!'),
                ),
              ],
            ),
          );
          _descriptionController.clear();
          setState(() {
            _selectedImages = [];
            _selectedCategory = 'Technical Issue';
          });
          _fetchTicketHistory(); // Update history after submission
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.error ?? 'Submission failed'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF667EEA);
    const gradient = LinearGradient(
      colors: [primaryColor, Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          const ManagementSidebar(
            gradient: gradient,
            activeRoute: '/support-request',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildSupportForm(primaryColor),
                  const SizedBox(height: 50),
                  _buildTicketHistorySection(primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHistorySection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📜', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 15),
            const Text(
              'Ticket History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _isLoadingHistory
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _ticketHistory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No support tickets found.',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                          columns: const [
                            DataColumn(label: Text('Ticket ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _ticketHistory.map((ticket) {
                            try {
                              final ticketId = ticket['ticket_id']?.toString() ?? 'N/A';
                              final shortId = ticketId.length > 8 ? ticketId.substring(0, 8) : ticketId;
                              final createdAtStr = ticket['created_at'];
                              String createdAt = 'N/A';
                              if (createdAtStr != null) {
                                try {
                                  createdAt = DateFormat('MMM dd, yyyy').format(DateTime.parse(createdAtStr).toLocal());
                                } catch (e) {
                                  createdAt = 'Invalid Date';
                                }
                              }
                              
                              return DataRow(cells: [
                                DataCell(Text('#$shortId')),
                                DataCell(Text(ticket['category'] ?? 'N/A')),
                                DataCell(_buildStatusBadge(ticket['status'] ?? 'new')),
                                DataCell(Text(createdAt)),
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () => _showTicketDetails(ticket),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('View'),
                                  ),
                                ),
                              ]);
                            } catch (e) {
                              debugPrint('Error building row for ticket: $e');
                              return const DataRow(cells: [
                                DataCell(Text('Error')),
                                DataCell(Text('Error')),
                                DataCell(Text('Error')),
                                DataCell(Text('Error')),
                                DataCell(Text('Error')),
                              ]);
                            }
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'new':
        color = Colors.red;
        label = 'New';
        break;
      case 'in_progress':
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'resolved':
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      default:
        color = Colors.blue;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🛠️', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 15),
                    const Text(
                      'Support Required',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    if (_totalTickets > 0) ...[
                      const SizedBox(width: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
                        ),
                        child: Text(
                          '$_totalTickets Tickets Raised',
                          style: const TextStyle(
                            color: Color(0xFF667EEA),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tell us how we can help you. Our support team typically responds within 24 hours.',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                ),
              ],
            ),
          ),
          _buildUserInfo(),
          const SizedBox(width: 20),
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return SchoolProfileHeader(apiService: ApiService());
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C757D), Color(0xFF495057)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF495057).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.arrow_back, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Back to Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportForm(Color primaryColor) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Issue Category'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration(),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 32),
              
              _buildFieldLabel('Issue Description'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: _inputDecoration(hint: 'Describe your issue in detail...'),
                validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 32),
              
              _buildFieldLabel('Attachments (Optional)'),
              const SizedBox(height: 12),
              _buildAttachmentPicker(primaryColor),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Submit Support Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A5568),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
      ),
    );
  }

  Widget _buildAttachmentPicker(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add Images'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            elevation: 0,
            side: BorderSide(color: primaryColor.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _selectedImages.asMap().entries.map((entry) {
              int index = entry.key;
              XFile image = entry.value;
              return Container(
                width: 150,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        image.name,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeImage(index),
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _viewImages(),
            icon: const Icon(Icons.visibility),
            label: const Text('Preview All'),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text('No images selected', style: TextStyle(color: Colors.grey[500])),
        ],
      ],
    );
  }
}

class ManagementTicketDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onUpdate;

  const ManagementTicketDetailsDialog({
    super.key,
    required this.ticket,
    required this.onUpdate,
  });

  @override
  State<ManagementTicketDetailsDialog> createState() => _ManagementTicketDetailsDialogState();
}

class _ManagementTicketDetailsDialogState extends State<ManagementTicketDetailsDialog> {
  final _replyController = TextEditingController();
  bool _isSubmitting = false;
  late Map<String, dynamic> _ticketData;

  @override
  void initState() {
    super.initState();
    _ticketData = Map<String, dynamic>.from(widget.ticket);
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
        
        // Re-fetch ticket to get latest replies
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

  @override
  Widget build(BuildContext context) {
    final ticketId = _ticketData['ticket_id']?.toString() ?? '';
    final shortId = ticketId.length > 8 ? ticketId.substring(0, 8) : ticketId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Ticket Details: #$shortId'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusProgressBar(),
            const SizedBox(height: 30),
            _buildTicketInfoCard(),
            const SizedBox(height: 30),
            _buildActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgressBar() {
    final status = _ticketData['status'] ?? 'new';
    int activeStep = 0;
    if (status == 'in_progress' || status == 'pending') activeStep = 1;
    if (status == 'resolved' || status == 'completed') activeStep = 2;

    return Row(
      children: [
        _buildStatusStep('New', activeStep >= 0, activeStep == 0),
        _buildStatusConnector(activeStep >= 1),
        _buildStatusStep('Pending', activeStep >= 1, activeStep == 1),
        _buildStatusConnector(activeStep >= 2),
        _buildStatusStep('Completed', activeStep >= 2, activeStep == 2),
      ],
    );
  }

  Widget _buildStatusStep(String title, bool isCompleted, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF667EEA) : (isCompleted ? Colors.green : Colors.white),
            border: Border.all(
              color: isActive || isCompleted ? Colors.transparent : const Color(0xFFdee2e6),
              width: 2,
            ),
            shape: BoxShape.circle,
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.green : const Color(0xFFdee2e6),
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }

  Widget _buildTicketInfoCard() {
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
          const Text('Ticket Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            _ticketData['description'] ?? 'No description.',
            style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF4A5568)),
          ),
          const SizedBox(height: 24),
          _buildAttachments(),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    final List<dynamic> attachments = _ticketData['attachments'] ?? [];
    final legacyAttachment = _ticketData['attachment'];
    
    if (attachments.isEmpty && legacyAttachment == null) return const SizedBox.shrink();

    List<String> allAttachments = attachments.map((a) => a['file'].toString()).toList();
    if (legacyAttachment != null && !allAttachments.contains(legacyAttachment.toString())) {
      allAttachments.insert(0, legacyAttachment.toString());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attachments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allAttachments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                      isXFile: false,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fullUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    final List<dynamic> replies = _ticketData['replies'] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F3F5))),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 20),
                SizedBox(width: 10),
                Text('Replies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    onSubmitted: (_) => _isSubmitting ? null : _submitReply(),
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitReply,
                  icon: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: Color(0xFF667EEA)),
                ),
              ],
            ),
          ),
          ...replies.map((reply) => _buildMessageItem(reply)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> reply) {
    final bool isManagement = reply['sender_role'] == 'Management';
    final String time = DateFormat('MMM dd, hh:mm a').format(DateTime.parse(reply['created_at']).toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isManagement ? Colors.blue[50] : Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isManagement ? 'Management' : 'Super Admin',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 4),
          Text(reply['message'] ?? ''),
        ],
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool drawRightBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 15,
    this.drawRightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = drawRightBorder
        ? BorderRadius.zero
        : BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: radius,
              border: Border(
                right: drawRightBorder
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                    : BorderSide.none,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(2, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
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

