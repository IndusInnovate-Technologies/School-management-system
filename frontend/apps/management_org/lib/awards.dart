import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'awards_download_stub.dart' if (dart.library.html) 'awards_download_web.dart' as download_helper;
import 'main.dart' as app;
import 'dashboard.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'widgets/school_profile_header.dart';
import 'package:url_launcher/url_launcher.dart';


// --- Data Model ---

// --- Data Model ---
class Award {
  final int id;
  final String title;
  final String category;
  final String recipient;
  final String? studentId; // Mapping student_ids from backend
  final DateTime date;
  final String description;
  final String level;
  final String presentedBy;

  final String? documentUrl;
  final List<String> certificateUrls;

  final List<Map<String, String>> studentDetails;
  
  Award({
    required this.id,
    required this.title,
    required this.category,
    required this.recipient,
    this.studentId,
    required this.date,
    required this.description,
    required this.level,
    required this.presentedBy,
    this.documentUrl,
    required this.certificateUrls,
    required this.studentDetails,
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    return Award(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      recipient: json['recipient']?.toString() ?? '',
      studentId: json['student_ids']?.toString(),
      date: json['date'] != null ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now()) : DateTime.now(),
      description: json['description']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      presentedBy: json['presented_by']?.toString() ?? '',
      documentUrl: json['document_url']?.toString(),
      certificateUrls: (json['certificates'] as List? ?? [])
          .map((c) => c is Map ? (c['document_url']?.toString()) : null)
          .where((url) => url != null)
          .map((url) => url!)
          .toList(),
      studentDetails: (json['student_details'] is List)
          ? (json['student_details'] as List).map<Map<String, String>>((d) {
              if (d is! Map) return {'student_id': '', 'student_name': ''};
              return {
                'student_id': (d['student_id'] ?? '').toString(),
                'student_name': (d['student_name'] ?? '').toString(),
              };
            }).toList()
          : [],
    );
  }
}

// --- Main Screen ---
class AwardsManagementPage extends StatefulWidget {
  const AwardsManagementPage({super.key});

  @override
  State<AwardsManagementPage> createState() => _AwardsManagementPageState();
}

class _AwardsManagementPageState extends State<AwardsManagementPage> {
  List<Award> _awards = [];
  List<Award> _filteredAwards = [];
  bool _isLoading = false;
  bool _isSearchingStudent = false;
  String _errorMessage = '';

  // -- Form Controllers --
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController(); // Added student ID controller
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _presentedByController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedCategory;
  String? _selectedLevel;
  bool _studentIdHasError = false; // Track student ID validation state

  // Document Upload
  Uint8List? _documentBytes;
  String? _documentName;
  List<String> _verifiedStudentNames = []; // List of verified names
  
  // Award Type Mode
  String _awardType = 'single'; // 'single' or 'team'

  // -- Filter Controllers --
  final TextEditingController _searchController = TextEditingController();
  String _filterCategory = "All Categories";
  String _filterLevel = "All Levels";
  // -- Helper Widgets --

  Widget _buildUserInfo() {
    return SchoolProfileHeader(apiService: ApiService());
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
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
            SizedBox(width: 8),
            Text(
              'Back to Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    _loadAwards();
  }

  // -- Logic --

  Future<void> _loadAwards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.get(Endpoints.awards);

      if (response.success) {
        List<dynamic> awardsJson = [];
        if (response.data is List) {
          awardsJson = response.data;
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap.containsKey('results')) {
            awardsJson = dataMap['results'];
          } else if (dataMap.containsKey('data')) {
            awardsJson = dataMap['data'];
          }
        }
        
        setState(() {
          _awards = awardsJson.map((json) => Award.fromJson(json)).toList();
          // Ensure latest awards are ALWAYS at the top (sorting by Date then ID descending as fallback)
          _awards.sort((a, b) {
            final dateCompare = b.date.compareTo(a.date);
            if (dateCompare != 0) return dateCompare;
            return b.id.compareTo(a.id);
          });
          _filterData();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load awards';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStudentNames(String studentIds) async {
    if (studentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Student ID"), backgroundColor: Colors.amber),
      );
      return;
    }
    
    setState(() => _isSearchingStudent = true);
    try {
      final ids = studentIds.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
      if (ids.isEmpty) {
        setState(() => _isSearchingStudent = false);
        return;
      }

      final apiService = ApiService();
      await apiService.initialize();
      
      List<String> names = [];
      List<String> notFoundIds = [];

      for (final id in ids) {
        // Look up each student by ID using query parameter filtering
        final response = await apiService.get('${Endpoints.students}?student_id=$id');
        if (response.success && response.data != null) {
          var data = response.data;
          List<dynamic> results = [];
          
          if (data is Map && data.containsKey('results')) {
            results = data['results'];
          } else if (data is List) {
            results = data;
          }
          
          if (results.isNotEmpty) {
            final studentData = results[0] as Map<String, dynamic>;
            final name = studentData['student_name'] ?? studentData['name'] ?? '';
            if (name.isNotEmpty) {
              names.add(name);
            } else {
              notFoundIds.add(id);
            }
          } else {
            notFoundIds.add(id);
          }
        } else {
          notFoundIds.add(id);
        }
      }

      if (mounted) {
        setState(() {
          _verifiedStudentNames = names;
          if (_awardType == 'single' && names.length == 1) {
            _recipientController.text = names.first;
          }
          _isSearchingStudent = false;
        });

        if (notFoundIds.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Student ID(s) not found: ${notFoundIds.join(', ')}"),
              backgroundColor: Colors.red,
            ),
          );
        } else if (names.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student ID(s) verified!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearchingStudent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error verifying student: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }


  Timer? _debounceTimer;

  void _filterData() {
    setState(() {
      final query = _searchController.text.toLowerCase().trim();
      _filteredAwards = _awards.where((award) {
        final matchesSearch = award.title.toLowerCase().contains(query) ||
            award.recipient.toLowerCase().contains(query) ||
            award.description.toLowerCase().contains(query) ||
            (award.studentId != null && award.studentId!.toLowerCase().contains(query));
        
        final matchesCategory = _filterCategory == "All Categories" || award.category == _filterCategory;
        final matchesLevel = _filterLevel == "All Levels" || award.level == _filterLevel;

        return matchesSearch && matchesCategory && matchesLevel;
      }).toList();
    });
  }

  Future<void> _addNewAward() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedCategory != null && _selectedLevel != null) {
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        await apiService.initialize();
        
        final awardData = {
          'title': _titleController.text,
          'category': _selectedCategory!,
          'recipient': _recipientController.text,
          'student_ids': _studentIdController.text,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'description': _descController.text,
          'level': _selectedLevel!,
          'presented_by': _presentedByController.text,
        };

        dynamic response;
        if (_documentBytes != null) {
             // Convert map to Map<String, String>
             final Map<String, String> stringData = awardData.map((key, value) => MapEntry(key, value.toString()));
             
             response = await apiService.uploadFile(
               Endpoints.awards,
               fileBytes: _documentBytes!,
               fileName: _documentName ?? 'award_doc.jpg',
               fieldName: 'document',
               additionalFields: stringData,
             );
        } else {
             response = await apiService.post(Endpoints.awards, body: awardData);
        }

        if (response.success) {
          // Reset Form
          _titleController.clear();
          _recipientController.clear();
          _studentIdController.clear(); // Clear student ID
          _descController.clear();
          _presentedByController.clear();
          _selectedDate = null;
          _selectedCategory = null;
          _selectedLevel = null;
          if (mounted) {
            setState(() {
                _documentBytes = null;
                _documentName = null;
                _verifiedStudentNames = [];
                // Reset filters to show the new data
                _searchController.clear();
                _filterCategory = "All Categories";
                _filterLevel = "All Levels";
            });
          }
          
          await _loadAwards(); // Reload from server
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Award added successfully!'), backgroundColor: Color(0xFF667eea)),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.error ?? 'Failed to add award'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedDate == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date'), backgroundColor: Colors.red));
    }
  }

  void _onStudentIdChanged(String value) {
    // Validate student ID format only
    setState(() {
      final validPattern = RegExp(r'^[A-Za-z0-9\-, \s]*$');
      _studentIdHasError = value.isNotEmpty && !validPattern.hasMatch(value);
    });
  }

  void _resetAddAwardForm() {
    setState(() {
      _titleController.clear();
      _recipientController.clear();
      _studentIdController.clear();
      _descController.clear();
      _presentedByController.clear();
      _selectedDate = null;
      _selectedCategory = null;
      _selectedLevel = null;
      _studentIdHasError = false;
      _documentBytes = null;
      _documentName = null;
      _verifiedStudentNames = [];
      _formKey.currentState?.reset();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _recipientController.dispose();
    _studentIdController.dispose();
    _descController.dispose();
    _presentedByController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteAward(Award award) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the award "${award.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        await apiService.initialize();
        final response = await apiService.delete('${Endpoints.awards}${award.id}/');

        if (response.success) {
          await _loadAwards();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Award deleted successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.error ?? 'Failed to delete award'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showCertificateDialog({int? initialIndex, String? url, Uint8List? bytes, required String title}) {
    // If initialIndex is provided, we use the paginated browser
    if (initialIndex != null) {
      final award = _filteredAwards[initialIndex];
      List<String> urls = award.certificateUrls;
      if (urls.isEmpty && award.documentUrl != null) {
        urls = [award.documentUrl!];
      }
      
      if (urls.isNotEmpty) {
        _showPaginatedCertificateBrowser(urls, award.title, award.recipient);
        return;
      }
    }

    // Fallback for single view if needed
    _showSingleCertificateView(url: url, bytes: bytes, title: title);
  }

  void _showPaginatedCertificateBrowser(List<String> urls, String title, String recipient) {
    if (urls.isEmpty) return;
    int currentIndex = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          String fullUrl = urls[currentIndex];
          if (!fullUrl.startsWith('http')) {
            String path = fullUrl;
            if (!path.startsWith('/media/') && !path.startsWith('media/')) {
              path = '/media/${path.startsWith('/') ? path.substring(1) : path}';
            }
            // Use window.location.origin in production, but here we can assume a base URL if needed
            // Or just use the relative path if the browser handles it.
            // For now, keeping the logic but more generic
            if (!fullUrl.startsWith('/')) fullUrl = '/$fullUrl';
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              width: 900,
              height: 700,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Recipient: $recipient",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Certificate ${currentIndex + 1} of ${urls.length}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Content (Main Image View)
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFF8F9FA),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              key: ValueKey(fullUrl), // Force rebuild on change
                              child: Image.network(
                                fullUrl.startsWith('http') ? fullUrl : Endpoints.buildUrl(fullUrl),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                      const SizedBox(height: 10),
                                      const Text("Could not load certificate image",
                                          style: TextStyle(color: Colors.red)),
                                      TextButton(
                                        onPressed: () async {
                                          final uri = Uri.parse(fullUrl!);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        child: const Text("Open in Browser"),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // Navigation Buttons Overlaid
                        if (currentIndex > 0)
                          Positioned(
                            left: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, size: 36, color: Color(0xFF667EEA)),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.all(12),
                                ),
                                onPressed: () {
                                  setDialogState(() => currentIndex--);
                                },
                              ),
                            ),
                          ),
                        if (currentIndex < urls.length - 1)
                          Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 36, color: Color(0xFF667EEA)),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.all(12),
                                ),
                                onPressed: () {
                                  setDialogState(() => currentIndex++);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                             ElevatedButton.icon(
                              onPressed: currentIndex > 0 ? () => setDialogState(() => currentIndex--) : null,
                              icon: const Icon(Icons.chevron_left, size: 18),
                              label: const Text("Previous"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE9ECEF),
                                foregroundColor: const Color(0xFF495057),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: currentIndex < urls.length - 1 ? () => setDialogState(() => currentIndex++) : null,
                              icon: const Icon(Icons.chevron_right, size: 18),
                              label: const Text("Next"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE9ECEF),
                                foregroundColor: const Color(0xFF495057),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                            if (fullUrl != null) ...[
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(fullUrl!);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text("Open in Browser"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667EEA),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showSingleCertificateView({String? url, Uint8List? bytes, required String title}) {
    // Ensure full URL if it's a string
    String? fullUrl;
    if (url != null) {
      fullUrl = url;
      if (!fullUrl.startsWith('http')) {
        String path = fullUrl;
        if (!path.startsWith('/media/') && !path.startsWith('media/')) {
          path = '/media/${path.startsWith('/') ? path.substring(1) : path}';
        }
        fullUrl = 'http://localhost:8000${path.startsWith('/') ? '' : '/'}$path';
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Certificate: $title",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  color: const Color(0xFFF8F9FA),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: bytes != null 
                        ? Image.memory(bytes)
                        : (fullUrl != null ? Image.network(
                            fullUrl,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  const SizedBox(height: 10),
                                  const Text("Could not load certificate image",
                                      style: TextStyle(color: Colors.red)),
                                  TextButton(
                                    onPressed: () async {
                                      final uri = Uri.parse(fullUrl!);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: const Text("Open in Browser"),
                                  ),
                                ],
                              );
                            },
                          ) : const Text("No image available")),
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                    if (fullUrl != null) ...[
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(fullUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Open in Browser"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _documentBytes = bytes;
        _documentName = picked.name;
      });
    }
  }

  // -- UI Structure --

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            _buildSidebar(),

          // Main Content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 30),

                    // Stats
                    _buildStatsOverview(),
                    const SizedBox(height: 30),

                    // Content Grid (Form + Search)
                    Column(
                      children: [
                        _buildAddAwardSection(),
                        const SizedBox(height: 30),
                        _buildFilterSection(),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Awards Grid
                    _buildSectionTitle("🏆", "All Awards"),
                    const SizedBox(height: 20),
                    _buildAwardsGrid(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Safe navigation helper for sidebar
    void navigateToRoute(String route) {
      final navigator = app.SchoolManagementApp.navigatorKey.currentState;
      if (navigator != null) {
        if (navigator.canPop() || route != '/dashboard') {
          navigator.pushReplacementNamed(route);
        } else {
          navigator.pushNamed(route);
        }
      }
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'packages/management_org/assets/Vidyarambh.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 56,
                        color: Color(0xFF667EEA),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _NavItem(
                    icon: '📊',
                    title: 'Overview',
                    isActive: false,
                    onTap: () => navigateToRoute('/dashboard'),
                  ),
                  _NavItem(
                    icon: '👨‍🏫',
                    title: 'Teachers',
                    onTap: () => navigateToRoute('/teachers'),
                  ),
                  _NavItem(
                    icon: '👥',
                    title: 'Students',
                    onTap: () => navigateToRoute('/students'),
                  ),
                  _NavItem(
                    icon: '🚌',
                    title: 'Buses',
                    onTap: () => navigateToRoute('/buses'),
                  ),
                  _NavItem(
                    icon: '🎯',
                    title: 'Activities',
                    onTap: () => navigateToRoute('/activities'),
                  ),
                  _NavItem(
                    icon: '📅',
                    title: 'Events',
                    onTap: () => navigateToRoute('/events'),
                  ),
                  _NavItem(
                    icon: '📆',
                    title: 'Calendar',
                    onTap: () => navigateToRoute('/calendar'),
                  ),
                  _NavItem(
                    icon: '🔔',
                    title: 'Notifications',
                    onTap: () => navigateToRoute('/notifications'),
                  ),
                  _NavItem(
                    icon: '🛣️',
                    title: 'Bus Routes',
                    onTap: () => navigateToRoute('/bus-routes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Widget Components --

  Widget _buildNavItem(String title, bool isActive) {
    return _NavItemWithHover(
      title: title,
      isActive: isActive,
      onTap: () {
        // Extract title without emoji (remove emoji and leading space)
        final titleWithoutEmoji = title.replaceAll(RegExp(r'^[^\s]+\s+'), '').trim();
        final routeMap = {
          'Dashboard': '/dashboard',
          'Students': '/students',
          'Teachers': '/teachers',
          'Buses': '/buses',
          'Events': '/events',
          'Notifications': '/notifications',
          'Activities': '/activities',
          'Awards': '/awards',
          'Photo Gallery': '/gallery',
          'Admissions': '/admissions',
          'Calendar': '/calendar',
          'RTI Act': null, // No route for RTI Act
        };
        final route = routeMap[titleWithoutEmoji];
        if (route != null && !isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
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
                Text(
                  'Awards Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage school awards, achievements, and recognitions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
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

  Widget _buildStatsOverview() {
    // Use _awards for total count (already filtered by school_id from backend)
    final total = _awards.length;
    final thisYear = _awards.where((a) => a.date.year == DateTime.now().year).length;
    final academic = _awards.where((a) => a.category == "Academic").length;
    final sports = _awards.where((a) => a.category == "Sports").length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Total Awards",
              total.toString(),
              "🏆",
              const Color(0xFF667EEA),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildStatCard(
              "This Year",
              thisYear.toString(),
              "📅",
              Colors.orange,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildStatCard(
              "Academic",
              academic.toString(),
              "🎓",
              Colors.blue,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildStatCard(
              "Sports",
              sports.toString(),
              "⚽",
              Colors.green,
            ),
          ),
          if (_documentBytes != null) ...[
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                "Selected File",
                _documentName ?? "Document",
                "🖼️",
                const Color(0xFF764BA2),
                onView: () => _showCertificateDialog(bytes: _documentBytes, title: _titleController.text.isEmpty ? "Preview" : _titleController.text),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String icon, Color color, {VoidCallback? onView}) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(icon, style: TextStyle(fontSize: 40, color: color)),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: value.length > 20 ? 14 : 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onView != null)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF667EEA)),
                onPressed: onView,
                tooltip: "View Certificate",
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
      ],
    );
  }

  Widget _buildAddAwardSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("➕", "Add New Award"),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Award Type Selection
                  Row(
                    children: [
                      const Text("Award Type: ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Radio<String>(
                        value: 'single',
                        groupValue: _awardType,
                        onChanged: (val) {
                          if (_awardType != val) {
                            _resetAddAwardForm();
                            setState(() {
                              _awardType = val!;
                            });
                          }
                        },
                      ),
                      const Text("Single Student"),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: 'team',
                        groupValue: _awardType,
                        onChanged: (val) {
                          if (_awardType != val) {
                            _resetAddAwardForm();
                            setState(() {
                              _awardType = val!;
                            });
                          }
                        },
                      ),
                      const Text("Team"),
                    ],
                  ),
                  const SizedBox(height: 15),

                  if (_awardType == 'team') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _downloadExcelTemplate,
                            icon: const Icon(Icons.download, size: 18, color: Color(0xFF667EEA)),
                            label: const Text("Download Template", style: TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF667EEA), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _importExcelWithImages,
                            icon: const Icon(Icons.upload_file, size: 18, color: Color(0xFF764BA2)),
                            label: const Text("Import Excel", style: TextStyle(color: Color(0xFF764BA2), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF764BA2), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                  ],

                  _buildFormRow([
                    _buildTextField("Award Title", _titleController),
                    _buildDropdownField("Category", ["Academic", "Sports", "Arts", "Leadership", "Innovation", "Community", "Science Fair", "NSS", "NCC", "Other"], _selectedCategory, (val) => setState(() => _selectedCategory = val)),
                  ]),
                  const SizedBox(height: 15),
                  
                  if (_awardType == 'single')
                    _buildFormRow([
                       _buildStudentIdField(label: "Student ID", hint: "Enter Student ID (e.g. STUD-001)"),
                       _buildTextField("Student Name", _recipientController, hint: "Auto-fetched from ID", isReadOnly: true),
                    ])
                  else 
                    Column(
                      children: [
                        _buildFormRow([
                          _buildTextField("Team Name", _recipientController, hint: "Enter Team Name"),
                        ]),
                        const SizedBox(height: 15),
                        _buildStudentIdField(label: "Team Members (Student IDs)", hint: "Enter IDs comma separated (e.g. STUD-001, STUD-002)"),
                      ],
                    ),
                  const SizedBox(height: 15),
                  _buildFormRow([
                    _buildDateField("Award Date"),
                    _buildDropdownField("Level", ["School", "District", "State", "National", "International"], _selectedLevel, (val) => setState(() => _selectedLevel = val)),
                  ]),
                  const SizedBox(height: 15),
                  _buildTextField("Description", _descController, maxLines: 3, hint: "Describe the achievement and criteria..."),
                  const SizedBox(height: 15),
                  _buildFormRow([
                    _buildTextField("Presented By", _presentedByController, isRequired: false, hint: "Organization/Person"),
                  ]),
                  const SizedBox(height: 15),
                  // Document Upload Section
                  Row(
                    children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text("Award Document", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                 Expanded(
                                   child: InkWell(
                                     onTap: _pickDocument,
                                     child: Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                       decoration: BoxDecoration(
                                         border: Border.all(color: const Color(0xFFE0E0E0)),
                                         borderRadius: BorderRadius.circular(8),
                                         color: Colors.white,
                                       ),
                                       child: Row(
                                         children: [
                                           Icon(_documentBytes != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
                                                color: _documentBytes != null ? Colors.green : Colors.grey),
                                           const SizedBox(width: 10),
                                           Expanded(
                                             child: Text(_documentName ?? "Upload Certificate/Image", 
                                                  style: TextStyle(color: _documentBytes != null ? Colors.black87 : Colors.grey),
                                                  overflow: TextOverflow.ellipsis),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                 ),
                                 if (_documentBytes != null) ...[
                                   const SizedBox(width: 10),
                                   SizedBox(
                                     height: 45,
                                     child: OutlinedButton.icon(
                                       onPressed: () => _showCertificateDialog(bytes: _documentBytes, title: _titleController.text.isEmpty ? "Preview" : _titleController.text),
                                       icon: const Icon(Icons.visibility),
                                       label: const Text("View"),
                                       style: OutlinedButton.styleFrom(
                                         foregroundColor: const Color(0xFF667EEA),
                                         side: const BorderSide(color: Color(0xFF667EEA)),
                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                       ),
                                     ),
                                   ),
                                 ],
                               ],
                             ),
                           ],
                         ),
                       ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _addNewAward,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            "Add Award",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
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

  String _formatRecipient(String recipient) {
    if (recipient.isEmpty) return recipient;
    
    // Check if it already has " " and X others"
    if (recipient.contains(" and ") && recipient.contains(" others")) {
      // It likely already has the format from backend. 
      // If we see 3 names (comma list before " and "), we'll force it to 2.
      final parts = recipient.split(" and ");
      if (parts.length < 2) return recipient;
      
      final namesPart = parts[0]; // e.g., "A, B, C"
      final othersPart = parts[1]; // e.g., "3 others"
      
      final names = namesPart.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (names.length > 2) {
        final totalOthers = int.tryParse(othersPart.split(' ')[0]) ?? 0;
        final newOthers = totalOthers + (names.length - 2);
        return "${names.take(2).join(", ")} and $newOthers others";
      }
      return recipient;
    }

    // Otherwise, handle raw comma separated names
    final names = recipient.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (names.length > 2) {
      return "${names.take(2).join(", ")} and ${names.length - 2} others";
    }
    return recipient;
  }

  void _showAllStudentIds(Award award) {
    if (!mounted) return;
    
    final details = award.studentDetails;
    final rawIdString = award.studentId ?? '';
    final fallbackIds = rawIdString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final displayCount = details.isNotEmpty ? details.length : fallbackIds.length;

    if (displayCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No student IDs associated with this award.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Full Student List"),
        content: SizedBox(
          width: 350,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: displayCount,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                String id = "";
                String name = "";
                
                try {
                  if (index < details.length) {
                    id = details[index]['student_id'] ?? '';
                    name = details[index]['student_name'] ?? '';
                  } else if (index < fallbackIds.length) {
                    id = fallbackIds[index];
                  }
                } catch (e) {
                  id = "Error";
                }

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF667EEA),
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  title: Text(id.isEmpty ? "Unknown ID" : id, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: name.isNotEmpty ? Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
                  dense: true,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showAllNames(String recipient) {
    final names = recipient.split(',').expand((e) => e.split(' and ')).map((e) => e.trim()).where((e) => e.isNotEmpty && !e.contains('others')).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Full Recipient List"),
        content: SizedBox(
          width: 300,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: names.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF764BA2),
                child: Icon(Icons.person_outline, color: Colors.white, size: 20),
              ),
              title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.w600)),
              dense: true,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("🔍", "Search & Filter"),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (val) => _filterData(),
                  decoration: InputDecoration(
                    hintText: "Search awards by title, recipient, or student ID...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _filterData,
                icon: const Icon(Icons.search_sharp),
                label: const Text("Search"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filterCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                  ),
                  items: ["All Categories", "Academic", "Sports", "Arts", "Leadership", "Innovation", "Community", "Science Fair", "NSS", "NCC", "Other"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    setState(() => _filterCategory = val!);
                    _filterData();
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filterLevel,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
                  ),
                  items: ["All Levels", "School", "District", "State", "National", "International"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    setState(() => _filterLevel = val!);
                    _filterData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(fontSize: 16, color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAwards,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredAwards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Text("No awards found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text("Add some awards to get started!", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int crossAxisCount = width > 1100 ? 3 : width > 700 ? 2 : 1;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.8, // Increased height to fit button - higher ratio = shorter cards
          ),
          itemCount: _filteredAwards.length,
          itemBuilder: (context, index) {
            return _buildAwardCard(_filteredAwards[index], index);
          },
        );
      },
    );
  }

  Widget _buildAwardCard(Award award, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  award.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      award.category,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (ApiService().userRole != 'financial')
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _deleteAward(award),
                      tooltip: "Delete Award",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            award.description,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 14, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (award.studentId != null && award.studentId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🎓 Student IDs", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      final ids = (award.studentId ?? '').split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
                      final displayIds = ids.take(2).toList();
                      final othersCount = ids.length - displayIds.length;
                      
                      return Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...displayIds.map((id) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              id,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF667EEA), fontWeight: FontWeight.bold),
                            ),
                          )),
                          if (othersCount > 0)
                            InkWell(
                              onTap: () => _showAllStudentIds(award),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  "and $othersCount others",
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF667EEA), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showAllStudentIds(award),
                  child: Text(
                    "👤 ${_formatRecipient(award.recipient)}",
                    style: const TextStyle(fontSize: 13, color: Color(0xFF888888), fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                "📅 ${DateFormat('MMM dd, yyyy').format(award.date)}",
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🏆 ${award.level} Level", style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              Expanded(
                child: Text(
                  "🎖️ ${award.presentedBy}",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (award.documentUrl != null || award.certificateUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCertificateDialog(initialIndex: index, title: award.title),
                icon: const Icon(Icons.card_membership, size: 16),
                label: Text(
                  award.certificateUrls.length > 1 
                    ? "View ${award.certificateUrls.length} Certificates" 
                    : "View Certificate", 
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF667EEA),
                  side: const BorderSide(color: Color(0xFF667EEA)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -- Form Building Helpers --

  Widget _buildFormRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((entry) {
        int idx = entry.key;
        Widget w = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: idx == 0 ? 0 : 15),
            child: w,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool isRequired = true, String? hint, bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly,
          validator: isRequired ? (val) => val!.isEmpty ? "Required" : null : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
            contentPadding: const EdgeInsets.all(12),
            fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text("Select $label"),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? "Required" : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2)),
            contentPadding: const EdgeInsets.all(12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        const SizedBox(height: 5),
        InkWell(
          onTap: () => _pickDate(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                  style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black),
                ),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Specialized Student ID field with validation
  Widget _buildStudentIdField({String label = "Student ID(s)", String hint = "e.g., STUD-001, STUD-002"}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333))),
        const SizedBox(height: 5),
        TextFormField(
          controller: _studentIdController,
          onChanged: _onStudentIdChanged,
          decoration: InputDecoration(
            hintText: hint,
            helperText: _awardType == 'team' ? "Add multiple IDs (comma-separated)" : "Enter unique Student ID",
            helperStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
            suffixIcon: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _isSearchingStudent 
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                    onPressed: () => _fetchStudentNames(_studentIdController.text),
                    tooltip: 'Search Student',
                  ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _studentIdHasError ? Colors.red : const Color(0xFFE0E0E0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _studentIdHasError ? Colors.red : const Color(0xFFE0E0E0),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _studentIdHasError ? Colors.red : const Color(0xFF667eea),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
        if (_studentIdHasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.warning, size: 14, color: Colors.red),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Invalid format. Use only letters, numbers, hyphens, and commas",
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        if (_verifiedStudentNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (_awardType == 'team') ...[
               const Text("Team Members:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
               const SizedBox(height: 4),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _verifiedStudentNames.map((name) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: const Color(0xFF667eea),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
                label: Text(name, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFFF0F2F5),
              )).toList(),
            ),
        ],
      ],
    );
  }

  Future<void> _downloadExcelTemplate() async {
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final String url = Endpoints.buildUrl("${Endpoints.awards}download_template/");
      final String? token = apiService.authToken;

      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await download_helper.downloadExcelFile(
          response.bodyBytes,
          'awards_import_template.xlsx',
          context,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template download started'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Failed to download template: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importExcelWithImages() async {
    try {
      // 1. Pick Excel File
      FilePickerResult? excelResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (excelResult == null || excelResult.files.single.bytes == null) return;

      // Skip image picking - images are embedded in Excel
      List<XFile> images = [];

      // Upload without showing progress dialog
      setState(() => _isLoading = true);
      
      final apiService = ApiService();
      await apiService.initialize();
      final String url = Endpoints.buildUrl("${Endpoints.awards}import_excel/");
      final String? token = apiService.authToken;

      var request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      // Add Excel
      request.files.add(http.MultipartFile.fromBytes(
        'excel_file',
        excelResult.files.single.bytes!,
        filename: excelResult.files.single.name,
      ));

      // Add Images
      for (int i = 0; i < images.length; i++) {
        final bytes = await images[i].readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image_$i',
          bytes,
          filename: images[i].name,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          // Show success dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('Success'),
                ],
              ),
              content: Text(data['message'] ?? 'Awards imported successfully'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          _loadAwards(); // Refresh list after dialog closes
        }
      } else {
        String msg = 'Import failed';
        List<String> rowErrors = [];
        try {
          final data = json.decode(response.body);
          msg = data['message'] ?? msg;
          if (data['errors'] != null && data['errors'] is List) {
             rowErrors = List<String>.from(data['errors']);
          }
        } catch (_) {}
        
        if (mounted) {
          if (rowErrors.isNotEmpty) {
            _showErrorDialog("Validation Failed", msg, rowErrors);
          } else {
            // Show error dialog
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 28),
                    SizedBox(width: 10),
                    Text('Error'),
                  ],
                ),
                content: Text(msg),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('Error'),
              ],
            ),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showErrorDialog(String title, String message, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text("Please fix the following rows in your Excel sheet and try again:"),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text("• $e", style: const TextStyle(fontSize: 13)),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(
          icon,
          style: const TextStyle(fontSize: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _NavItemWithHover extends StatefulWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemWithHover({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItemWithHover> createState() => _NavItemWithHoverState();
}

class _NavItemWithHoverState extends State<_NavItemWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        transform: Matrix4.identity()
          ..translate(_isHovered ? 8.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: widget.isActive
              ? Colors.white.withValues(alpha: 0.3)
              : _isHovered
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// Glass Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool drawRightBorder;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.drawRightBorder = false,
    this.borderRadius = 12,
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
