import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:main_login/main.dart' as main_login;
import 'main.dart' as app;
import 'dashboard.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'widgets/school_profile_header.dart';

// --- Style Constants ---

const Color primaryColorDark = Color(0xFF764BA2);
const Color primaryColorLight = Color(0xFF667EEA);
const Color backgroundColor = Color(0xFFf8f9fa);
const Color textColor = Color(0xFF333333);
const Color secondaryTextColor = Color(0xFF666666);
const Color tertiaryTextColor = Color(0xFF888888);

// --- Data Models and Mock Data ---

class CampusFeature {
  final int id;
  final String name;
  final String category;
  final String description;
  final String location;
  final String? capacity;
  final String status;
  final DateTime dateAdded;
  final String? imageUrl;

  CampusFeature({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    this.capacity,
    required this.status,
    required this.dateAdded,
    this.imageUrl,
  });

  factory CampusFeature.fromJson(Map<String, dynamic> json) {
    return CampusFeature(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? 'academic',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      capacity: json['capacity'],
      status: json['status'] ?? 'active',
      dateAdded: json['date_added'] != null
          ? DateTime.parse(json['date_added'])
          : DateTime.now(),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'location': location,
      'capacity': capacity,
      'status': status,
    };
  }

  CampusFeature copyWith({
    int? id,
    String? name,
    String? category,
    String? description,
    String? location,
    String? capacity,
    String? status,
    DateTime? dateAdded,
    String? imageUrl,
  }) {
    return CampusFeature(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      dateAdded: dateAdded ?? this.dateAdded,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

// Mock data now uses DateTime objects, matching the stateful class structure
final List<CampusFeature> mockCampusFeatures = [
  CampusFeature(
    id: 1,
    name: 'Modern Library',
    category: 'academic',
    description:
        'State-of-the-art library with digital resources, study rooms, and multimedia facilities.',
    location: 'Main Building, 2nd Floor',
    capacity: '200 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 15),
  ),
  CampusFeature(
    id: 2,
    name: 'Olympic-size Swimming Pool',
    category: 'sports',
    description:
        '50-meter swimming pool with diving boards and professional coaching facilities.',
    location: 'Sports Complex',
    capacity: '100 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 10),
  ),
  CampusFeature(
    id: 3,
    name: 'Robotics Lab',
    category: 'technology',
    description:
        'Advanced robotics laboratory with 3D printers, Arduino kits, and AI programming stations.',
    location: 'Technology Block',
    capacity: '30 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 20),
  ),
  CampusFeature(
    id: 4,
    name: 'Art Studio',
    category: 'arts',
    description:
        'Creative art studio with painting, sculpture, and digital art facilities.',
    location: 'Arts Building',
    capacity: '50 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 12),
  ),
  CampusFeature(
    id: 5,
    name: 'Solar Power Plant',
    category: 'infrastructure',
    description:
        'Sustainable energy solution with rooftop solar panels generating 100kW power.',
    location: 'Campus Rooftops',
    capacity: 'Entire campus',
    status: 'active',
    dateAdded: DateTime(2024, 1, 5),
  ),
  CampusFeature(
    id: 6,
    name: 'Cafeteria',
    category: 'amenities',
    description:
        'Multi-cuisine cafeteria serving healthy meals with seating for 300 students.',
    location: 'Student Center',
    capacity: '300 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 8),
  ),
  CampusFeature(
    id: 7,
    name: 'Meditation Garden',
    category: 'speciality',
    description:
        'Peaceful meditation garden with walking paths, water features, and seating areas.',
    location: 'Campus Center',
    capacity: '100 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 18),
  ),
  CampusFeature(
    id: 8,
    name: 'Basketball Court',
    category: 'sports',
    description:
        'Professional basketball court with electronic scoreboard and spectator seating.',
    location: 'Sports Complex',
    capacity: '200 spectators',
    status: 'active',
    dateAdded: DateTime(2024, 1, 14),
  ),
  CampusFeature(
    id: 9,
    name: 'Computer Lab',
    category: 'technology',
    description:
        'Modern computer laboratory with 50 workstations and high-speed internet.',
    location: 'Technology Block',
    capacity: '50 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 16),
  ),
  CampusFeature(
    id: 10,
    name: 'Auditorium',
    category: 'infrastructure',
    description:
        '500-seat auditorium with professional sound and lighting systems.',
    location: 'Main Building',
    capacity: '500 people',
    status: 'active',
    dateAdded: DateTime(2024, 1, 11),
  ),
  CampusFeature(
    id: 11,
    name: 'Green House',
    category: 'speciality',
    description:
        'Educational greenhouse for botany studies and environmental awareness.',
    location: 'Science Block',
    capacity: '30 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 22),
  ),
  CampusFeature(
    id: 12,
    name: 'Music Room',
    category: 'arts',
    description:
        'Soundproof music room with various instruments and recording equipment.',
    location: 'Arts Building',
    capacity: '40 students',
    status: 'active',
    dateAdded: DateTime(2024, 1, 19),
  ),
];

// --- Utility Functions (Consolidated) ---

LinearGradient getStatusGradient(String status) {
  switch (status) {
    case 'active':
      return const LinearGradient(
        colors: [primaryColorLight, primaryColorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case 'under-construction':
      return const LinearGradient(
        colors: [Color(0xFFffa726), Color(0xFFff7043)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case 'planned':
      return const LinearGradient(
        colors: [Color(0xFF42a5f5), Color(0xFF1976d2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case 'maintenance':
      return const LinearGradient(
        colors: [Color(0xFFef5350), Color(0xFFd32f2f)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    default:
      return const LinearGradient(
        colors: [primaryColorLight, primaryColorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  }
}

Color _getFeatureStatusColor(String status) {
  switch (status) {
    case 'active':
      return Colors.green;
    case 'under-construction':
      return Colors.orange;
    case 'planned':
      return Colors.blue;
    case 'maintenance':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String getCategoryIcon(String category) {
  const icons = {
    'academic': '📚',
    'sports': '⚽',
    'technology': '💻',
    'arts': '🎨',
    'infrastructure': '🏗️',
    'amenities': '🏪',
    'speciality': '⭐',
  };
  return icons[category] ?? '🏫';
}

String getCategoryDisplayName(String category) {
  const displayNames = {
    'academic': 'Academic Facilities',
    'sports': 'Sports & Recreation',
    'technology': 'Technology & Labs',
    'arts': 'Arts & Culture',
    'infrastructure': 'Infrastructure',
    'amenities': 'Amenities',
    'speciality': 'Campus Speciality',
  };
  return displayNames[category] ?? 'Unknown';
}

String getStatusDisplayName(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'under-construction':
      return 'Under Construction';
    case 'planned':
      return 'Planned';
    case 'maintenance':
      return 'Under Maintenance';
    default:
      return 'Unknown';
  }
}

// --- Main Screen (using the functional structure) ---

class CampusLifeManagementPage extends StatefulWidget {
  const CampusLifeManagementPage({super.key});

  @override
  State<CampusLifeManagementPage> createState() =>
      _CampusLifeManagementPageState();
}

class _CampusLifeManagementPageState extends State<CampusLifeManagementPage> {
  // Use a mutable list for state management
  List<CampusFeature> _allFeatures = [];
  List<CampusFeature> _filteredFeatures = [];
  String _searchQuery = '';
  String _categoryFilter = '';
  String _statusFilter = '';
  String _sortBy = 'date'; // 'date', 'name', 'category'
  bool _sortAscending = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Form Controllers for embedded form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  String _selectedCategory = '';
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  Future<void> _loadFeatures() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.get(Endpoints.campusFeatures);
      if (response.success && response.data != null) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data as List;
        } else if (response.data is Map && (response.data as Map)['results'] != null) {
          data = (response.data as Map)['results'] as List;
        }

        setState(() {
          _allFeatures = data.map((d) => CampusFeature.fromJson(d)).toList();
          _filterFeatures();
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load campus features';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading campus features: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _filterFeatures() {
    setState(() {
      _filteredFeatures = _allFeatures.where((feature) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            feature.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            feature.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            feature.location.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory =
            _categoryFilter.isEmpty || feature.category == _categoryFilter;

        final matchesStatus =
            _statusFilter.isEmpty || feature.status == _statusFilter;

        return matchesSearch && matchesCategory && matchesStatus;
      }).toList();
      _sortFeatures();
    });
  }

  void _sortFeatures() {
    _filteredFeatures.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.dateAdded.compareTo(b.dateAdded);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  Map<String, dynamic> _getStats() {
    return {
      'total': _allFeatures.length,
      'active': _allFeatures.where((f) => f.status == 'active').length,
      'specialities': _allFeatures
          .where((f) => f.category == 'speciality')
          .length,
      'satisfaction': '95%',
    };
  }

  Future<void> _addFeature(CampusFeature feature) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.post(Endpoints.campusFeatures, body: feature.toJson());
      if (response.success) {
        await _loadFeatures();
        _resetForm();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to add feature'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding feature: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFeature(CampusFeature updatedFeature) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.put('${Endpoints.campusFeatures}${updatedFeature.id}/', body: updatedFeature.toJson());
      if (response.success) {
        await _loadFeatures();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to update feature'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating feature: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFeature(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this feature?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.delete('${Endpoints.campusFeatures}$id/');
      if (response.success) {
        await _loadFeatures();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to delete feature'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting feature: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitEmbeddedForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      final feature = CampusFeature(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        capacity: _capacityController.text.trim().isEmpty
            ? null
            : _capacityController.text.trim(),
        status: _selectedStatus,
        dateAdded: DateTime.now(),
      );
      _addFeature(feature);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campus feature added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _capacityController.clear();
    setState(() {
      _selectedCategory = '';
      _selectedStatus = 'active';
    });
  }


  void _exportData(BuildContext context) {
    final csv = StringBuffer();
    csv.writeln(
      'ID,Name,Category,Description,Location,Capacity,Status,Date Added',
    );
    for (final feature in _filteredFeatures) {
      csv.writeln(
        '${feature.id},${feature.name},${feature.category},"${feature.description.replaceAll('"', '""')}",${feature.location},${feature.capacity ?? 'N/A'},${feature.status},${DateFormat('yyyy-MM-dd').format(feature.dateAdded)}',
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export ready! ${_filteredFeatures.length} records prepared.',
        ),
        action: SnackBarAction(
          label: 'Copy CSV',
          onPressed: () {
            // Placeholder for copy to clipboard logic
          },
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to main login page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const main_login.LoginScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _viewFeature(BuildContext context, CampusFeature feature) {
    showDialog(
      context: context,
      builder: (context) => _FeatureDetailDialog(feature: feature),
    );
  }

  void _showEditFeatureDialog(BuildContext context, CampusFeature feature) {
    showDialog(
      context: context,
      builder: (context) => _FeatureFormDialog(
        feature: feature,
        onSave: (updatedFeature) {
          _updateFeature(updatedFeature);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campus feature updated successfully!'),
            ),
          );
        },
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
  Widget build(BuildContext context) {
    final stats = _getStats();

    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          _buildSidebar(),
          // --- MAIN CONTENT AREA ---
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: Column(
                children: [
                  // --- CONTENT BODY ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- TOP HEADER ---
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                            margin: const EdgeInsets.only(bottom: 30),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Campus Life Management',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ),
                                _buildUserInfo(),
                                const SizedBox(width: 20),
                                _buildBackButton(),
                              ],
                            ),
                          ),
                          // Stats Overview
                          _StatsOverview(stats: stats),
                          const SizedBox(height: 30),

                          // Add New Feature Form
                          if (ApiService().userRole != 'financial')
                            _buildAddFeatureSection(),
                          if (ApiService().userRole != 'financial')
                            const SizedBox(height: 30),

                          // Search & Filter Bar
                          _FilterBar(
                            currentQuery: _searchQuery,
                            currentCategory: _categoryFilter,
                            currentStatus: _statusFilter,
                            onSearchChanged: (value) {
                              _searchQuery = value;
                              _filterFeatures();
                            },
                            onCategoryChanged: (value) {
                              _categoryFilter = value ?? '';
                              _filterFeatures();
                            },
                            onStatusChanged: (value) {
                              _statusFilter = value ?? '';
                              _filterFeatures();
                            },
                            onSortChanged: (sortBy, isAscending) {
                              _sortBy = sortBy;
                              _sortAscending = isAscending;
                              _sortFeatures();
                            },
                          ),
                          const SizedBox(height: 30),

                          // Features Grid
                          _isLoading 
                            ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
                            : _errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                        const SizedBox(height: 16),
                                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadFeatures,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                : _FeaturesGrid(
                                    features: _filteredFeatures,
                                    onView: _viewFeature,
                                    onEdit: _showEditFeatureDialog,
                                    onDelete: _deleteFeature,
                                  ),
                        ],
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

  Widget _buildAddFeatureSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('➕', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                const Text(
                  'Add New Feature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 15),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Feature Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCategory.isEmpty
                        ? null
                        : _selectedCategory,
                    items: [
                      ...const {
                        'academic': 'Academic Facilities',
                        'sports': 'Sports & Recreation',
                        'technology': 'Technology & Labs',
                        'arts': 'Arts & Culture',
                        'infrastructure': 'Infrastructure',
                        'amenities': 'Amenities',
                        'speciality': 'Campus Speciality',
                      }.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? '';
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'under-construction',
                        child: Text('Under Construction'),
                      ),
                      DropdownMenuItem(
                        value: 'planned',
                        child: Text('Planned'),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('Under Maintenance'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value ?? 'active';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 200 students',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: InkWell(
                onTap: _submitEmbeddedForm,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColorLight, primaryColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Add Feature",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Reusable Component Widgets (Consolidated and Renamed) ---

// Nav Item (from V2)
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
        leading: Text(icon, style: const TextStyle(fontSize: 18)),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

class _NavItemOld extends StatefulWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavItemOld({
    required this.icon,
    required this.title,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<_NavItemOld> createState() => _NavItemOldState();
}

class _NavItemOldState extends State<_NavItemOld> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.isActive
              ? Colors.white.withValues(alpha: 0.3)
              : _isHovered
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ListTile(
          leading: Text(widget.icon, style: const TextStyle(fontSize: 20)),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.isActive || _isHovered
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: widget.isActive || _isHovered ? 15.0 : 14.0,
            ),
            child: Text(widget.title),
          ),
          selected: widget.isActive,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// User Info (from V1)
class UserInfo extends StatelessWidget {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [primaryColorLight, primaryColorDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manager',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'School Admin',
              style: TextStyle(color: secondaryTextColor, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

// Logout Button (from V1)
class LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
    );
  }
}

// Stats Overview (from V2, renamed and updated to use V1's data map)
class _StatsOverview extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsOverview({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.35,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          icon: '🏫',
          label: 'Total Features',
          value: stats['total'].toString(),
          color: primaryColorLight,
        ),
        _StatCard(
          icon: '🎯',
          label: 'Active Features',
          value: stats['active'].toString(),
          color: Colors.green,
        ),
        _StatCard(
          icon: '⭐',
          label: 'Specialities',
          value: stats['specialities'].toString(),
          color: Colors.orange,
        ),
        _StatCard(
          icon: '📈',
          label: 'Satisfaction',
          value: stats['satisfaction'].toString(),
          color: Colors.blue,
        ),
      ],
    );
  }
}

// Stat Card (from V2, renamed and updated styles)
class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 40, color: color)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// Filter Bar (combined search, filter, and sort logic)
class _FilterBar extends StatelessWidget {
  final String currentQuery;
  final String currentCategory;
  final String currentStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final Function(String sortBy, bool isAscending) onSortChanged;

  const _FilterBar({
    required this.currentQuery,
    required this.currentCategory,
    required this.currentStatus,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search & Filtering',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search features by name, location, or description...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 15),
              // Sort Dropdown
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                  ),
                  initialValue: 'date', // Default sort
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date Added')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(
                      value: 'category',
                      child: Text('Category'),
                    ),
                  ],
                  onChanged: (value) =>
                      onSortChanged(value!, false), // Default Descending
                ),
              ),
              const SizedBox(width: 10),
              // Sort Order Toggle (Needs State to track ascending/descending, handled in parent)
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 24),
                onPressed: () {
                  // In a real stateful widget, this would toggle the order
                },
                tooltip: 'Toggle Sort Order',
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category Filter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                  ),
                  initialValue: currentCategory.isEmpty
                      ? null
                      : currentCategory,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Categories'),
                    ),
                    ...const {
                      'academic': 'Academic Facilities',
                      'sports': 'Sports & Recreation',
                      'technology': 'Technology & Labs',
                      'arts': 'Arts & Culture',
                      'infrastructure': 'Infrastructure',
                      'amenities': 'Amenities',
                      'speciality': 'Campus Speciality',
                    }.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status Filter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                  ),
                  initialValue: currentStatus.isEmpty ? null : currentStatus,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Status'),
                    ),
                    ...const {
                      'active': 'Active',
                      'under-construction': 'Under Construction',
                      'planned': 'Planned',
                      'maintenance': 'Under Maintenance',
                    }.entries.map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(getStatusDisplayName(e.key)),
                      ),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Features Grid (from V2, renamed and updated card implementation)
class _FeaturesGrid extends StatelessWidget {
  final List<CampusFeature> features;
  final Function(BuildContext, CampusFeature) onView;
  final Function(BuildContext, CampusFeature) onEdit;
  final Function(int) onDelete;

  const _FeaturesGrid({
    required this.features,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Campus Features List',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        features.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No features match your criteria.'),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.9, // Adjusted for card content
                ),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return _CampusFeatureCard(
                    feature: feature,
                    categoryIcon: getCategoryIcon(feature.category),
                    onView: () => onView(context, feature),
                    onEdit: () => onEdit(context, feature),
                    onDelete: () => onDelete(feature.id),
                  );
                },
              ),
      ],
    );
  }
}

// Campus Feature Card (from V2, fully styled and functional)
class _CampusFeatureCard extends StatelessWidget {
  final CampusFeature feature;
  final String categoryIcon;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CampusFeatureCard({
    required this.feature,
    required this.categoryIcon,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon, Title, Status Tag, Three-dot Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(categoryIcon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          feature.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getFeatureStatusColor(
                          feature.status,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        getStatusDisplayName(feature.status),
                        style: TextStyle(
                          color: _getFeatureStatusColor(feature.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      onSelected: (value) {
                        if (value == 'view') {
                          onView();
                        } else if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text(
                                'Are you sure you want to delete ${feature.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    onDelete();
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 16),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        if (ApiService().userRole != 'financial') ...[
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            // Description
            Expanded(
              child: Text(
                feature.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 10),
            // Details Rows
            _DetailRow(
              label: 'Category:',
              value: getCategoryDisplayName(feature.category),
            ),
            _DetailRow(label: 'Location:', value: feature.location),
            if (feature.capacity != null)
              _DetailRow(label: 'Capacity:', value: feature.capacity!),
            _DetailRow(
              label: 'Added Date:',
              value: DateFormat('MMM dd, yyyy').format(feature.dateAdded),
            ),
          ],
        ),
      ),
    );
  }
}

// Detail Row (from V2)
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tertiaryTextColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Feature Detail Dialog (from V2)
class _FeatureDetailDialog extends StatelessWidget {
  final CampusFeature feature;

  const _FeatureDetailDialog({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    feature.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _DetailItem('Category', getCategoryDisplayName(feature.category)),
              _DetailItem('Description', feature.description),
              _DetailItem('Location', feature.location),
              if (feature.capacity != null)
                _DetailItem('Capacity', feature.capacity!),
              _DetailItem('Status', getStatusDisplayName(feature.status)),
              _DetailItem(
                'Date Added',
                DateFormat('MMM dd, yyyy').format(feature.dateAdded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Detail Item for Dialog (from V2)
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Feature Form Dialog (from V2)
class _FeatureFormDialog extends StatefulWidget {
  final CampusFeature? feature;
  final Function(CampusFeature) onSave;

  const _FeatureFormDialog({this.feature, required this.onSave});

  @override
  State<_FeatureFormDialog> createState() => _FeatureFormDialogState();
}

class _FeatureFormDialogState extends State<_FeatureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;

  String _category = '';
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final feature = widget.feature;
    _nameController = TextEditingController(text: feature?.name ?? '');
    _descriptionController = TextEditingController(
      text: feature?.description ?? '',
    );
    _locationController = TextEditingController(text: feature?.location ?? '');
    _capacityController = TextEditingController(text: feature?.capacity ?? '');
    _category = feature?.category ?? '';
    _status = feature?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_category.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select category')));
        return;
      }

      final feature = CampusFeature(
        // Ensure new IDs are unique and sequential
        id: widget.feature?.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: _nameController.text.trim(),
        category: _category,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        capacity: _capacityController.text.trim().isEmpty
            ? null
            : _capacityController.text.trim(),
        status: _status,
        dateAdded: widget.feature?.dateAdded ?? DateTime.now(),
      );

      widget.onSave(feature);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.feature == null
                        ? 'Add New Campus Feature'
                        : 'Edit Campus Feature',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Feature Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter feature name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _category.isEmpty ? null : _category,
                        items: [
                          ...const {
                            'academic': 'Academic Facilities',
                            'sports': 'Sports & Recreation',
                            'technology': 'Technology & Labs',
                            'arts': 'Arts & Culture',
                            'infrastructure': 'Infrastructure',
                            'amenities': 'Amenities',
                            'speciality': 'Campus Speciality',
                          }.entries.map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _category = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              decoration: const InputDecoration(
                                labelText: 'Capacity/Size (Optional)',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., 500 students, 2 acres',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Status *',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _status,
                              items: const [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem(
                                  value: 'under-construction',
                                  child: Text('Under Construction'),
                                ),
                                DropdownMenuItem(
                                  value: 'planned',
                                  child: Text('Planned'),
                                ),
                                DropdownMenuItem(
                                  value: 'maintenance',
                                  child: Text('Under Maintenance'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _status = value ?? 'active';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      widget.feature == null ? 'Add Feature' : 'Update Feature',
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
