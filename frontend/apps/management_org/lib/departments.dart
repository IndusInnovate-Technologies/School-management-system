import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart' as app;
import 'dashboard.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'dart:ui';
import 'widgets/school_profile_header.dart';

class Department {
  final int id;
  final String? schoolId;
  final String? schoolName;
  final String name;
  final String code;
  final String head;
  final String email;
  final int faculty;
  final int students;
  final int courses;
  final String? description;
  final String? phone;
  final DateTime? establishedDate;

  Department({
    required this.id,
    this.schoolId,
    this.schoolName,
    required this.name,
    required this.code,
    required this.head,
    required this.email,
    required this.faculty,
    required this.students,
    required this.courses,
    this.description,
    this.phone,
    this.establishedDate,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      schoolId: json['school_id'],
      schoolName: json['school_name'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      head: json['head_name'] ?? '',
      email: json['email'] ?? '',
      faculty: json['faculty_count'] ?? 0,
      students: json['student_count'] ?? 0,
      courses: json['course_count'] ?? 0,
      description: json['description'],
      phone: json['phone'],
      establishedDate: json['established_date'] != null
          ? DateTime.parse(json['established_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'head_name': head,
      'email': email,
      'faculty_count': faculty,
      'student_count': students,
      'course_count': courses,
      'description': description,
      'phone': phone,
      'established_date': established_date_str,
    };
  }
  
  String? get established_date_str => establishedDate != null 
    ? "${establishedDate!.year}-${establishedDate!.month.toString().padLeft(2, '0')}-${establishedDate!.day.toString().padLeft(2, '0')}"
    : null;

  Department copyWith({
    int? id,
    String? schoolId,
    String? schoolName,
    String? name,
    String? code,
    String? head,
    String? email,
    int? faculty,
    int? students,
    int? courses,
    String? description,
    String? phone,
    DateTime? establishedDate,
  }) {
    return Department(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      name: name ?? this.name,
      code: code ?? this.code,
      head: head ?? this.head,
      email: email ?? this.email,
      faculty: faculty ?? this.faculty,
      students: students ?? this.students,
      courses: courses ?? this.courses,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      establishedDate: establishedDate ?? this.establishedDate,
    );
  }
}

class DepartmentsManagementPage extends StatefulWidget {
  const DepartmentsManagementPage({super.key});

  @override
  State<DepartmentsManagementPage> createState() =>
      _DepartmentsManagementPageState();
}

class _DepartmentsManagementPageState extends State<DepartmentsManagementPage> {
  List<Department> _allDepartments = [];
  List<Department> _filteredDepartments = [];
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'code', 'faculty', 'students'
  bool _sortAscending = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.get(Endpoints.departments);
      if (response.success && response.data != null) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data as List;
        } else if (response.data is Map && (response.data as Map)['results'] != null) {
          data = (response.data as Map)['results'] as List;
        }
        
        setState(() {
          _allDepartments = data.map((d) => Department.fromJson(d)).toList();
          _filterDepartments();
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load departments';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading departments: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterDepartments() {
    setState(() {
      _filteredDepartments = _allDepartments.where((dept) {
        final matchesSearch = _searchQuery.isEmpty ||
            dept.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dept.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dept.head.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dept.email.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesSearch;
      }).toList();
      _sortDepartments();
    });
  }

  void _sortDepartments() {
    _filteredDepartments.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'code':
          comparison = a.code.compareTo(b.code);
          break;
        case 'faculty':
          comparison = a.faculty.compareTo(b.faculty);
          break;
        case 'students':
          comparison = a.students.compareTo(b.students);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  Map<String, dynamic> _getStats() {
    final totalFaculty =
        _allDepartments.fold(0, (sum, dept) => sum + dept.faculty);
    final totalStudents =
        _allDepartments.fold(0, (sum, dept) => sum + dept.students);
    final totalCourses =
        _allDepartments.fold(0, (sum, dept) => sum + dept.courses);
    final avgFacultyPerDept = _allDepartments.isEmpty ? 0 : totalFaculty / _allDepartments.length;

    return {
      'totalDepartments': _allDepartments.length,
      'totalFaculty': totalFaculty,
      'totalStudents': totalStudents,
      'totalCourses': totalCourses,
      'avgFaculty': avgFacultyPerDept.round(),
      'facultySatisfaction': '92%',
      'studentSuccessRate': '88%',
    };
  }

  Future<void> _addDepartment(Department department) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.post(Endpoints.departments, body: department.toJson());
      if (response.success) {
        await _loadDepartments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to add department'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding department: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDepartment(Department updatedDepartment) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.put('${Endpoints.departments}${updatedDepartment.id}/', body: updatedDepartment.toJson());
      if (response.success) {
        await _loadDepartments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to update department'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating department: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDepartment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this department?'),
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
      final response = await apiService.delete('${Endpoints.departments}$id/');
      if (response.success) {
        await _loadDepartments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to delete department'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting department: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _exportData() {
    final csv = StringBuffer();
    csv.writeln(
        'ID,Name,Code,Head,Email,Phone,Faculty,Students,Courses,Established Date');
    for (final dept in _filteredDepartments) {
      csv.writeln(
          '${dept.id},${dept.name},${dept.code},${dept.head},${dept.email},${dept.phone ?? 'N/A'},${dept.faculty},${dept.students},${dept.courses},${dept.establishedDate != null ? DateFormat('yyyy-MM-dd').format(dept.establishedDate!) : 'N/A'}');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Export ready! ${_filteredDepartments.length} records prepared.'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // In a real app, you'd copy to clipboard or save to file
          },
        ),
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
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main Content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Department Management',
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
                      ),
                    // Stats Overview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: GridView.count(
                        crossAxisCount: 4,
                        childAspectRatio: 1.35,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: [
                          _StatCard(
                            label: 'Total Departments',
                            value: stats['totalDepartments']!.toString(),
                            icon: '🏢',
                            color: const Color(0xFF667EEA),
                          ),
                          _StatCard(
                            label: 'Total Faculty',
                            value: stats['totalFaculty']!.toString(),
                            icon: '👨‍🏫',
                            color: Colors.green,
                          ),
                          _StatCard(
                            label: 'Total Courses',
                            value: stats['totalCourses']!.toString(),
                            icon: '📚',
                            color: Colors.orange,
                          ),
                          _StatCard(
                            label: 'Total Students',
                            value: stats['totalStudents']!.toString(),
                            icon: '👥',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    // Search and Sort
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search departments...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                                _filterDepartments();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButton<String>(
                              value: _sortBy,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                    value: 'name', child: Text('Sort by Name')),
                                DropdownMenuItem(
                                    value: 'code', child: Text('Sort by Code')),
                                DropdownMenuItem(
                                    value: 'faculty',
                                    child: Text('Sort by Faculty')),
                                DropdownMenuItem(
                                    value: 'students',
                                    child: Text('Sort by Students')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _sortBy = value!;
                                  _sortDepartments();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(_sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward),
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                                _sortDepartments();
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
                            tooltip: 'Sort Order',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Main Content Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Departments Grid
                        Expanded(
                          flex: 2,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
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
                                            onPressed: _loadDepartments,
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _filteredDepartments.isEmpty
                                      ? Container(
                                          padding: const EdgeInsets.all(20),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.business_outlined,
                                                    size: 64, color: Colors.grey[400]),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No departments found',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(20),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 20,
                                            mainAxisSpacing: 20,
                                            mainAxisExtent: 210,
                                          ),
                                          itemCount: _filteredDepartments.length,
                                          itemBuilder: (context, index) {
                                            return _DepartmentCard(
                                              department: _filteredDepartments[index],
                                              onView: () => _viewDepartment(
                                                  context, _filteredDepartments[index]),
                                              onEdit: () => _showEditDepartmentDialog(
                                                  context,
                                                  _filteredDepartments[index]),
                                              onDelete: () => _deleteDepartment(
                                                  _filteredDepartments[index].id),
                                            );
                                          },
                                        ),
                        ),
                        // Sidebar
                        Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 20),
                          child: Column(
                            children: [
                                // Quick Actions
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
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
                                        'Quick Actions',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      if (ApiService().userRole != 'financial')
                                        _QuickActionItem(
                                          icon: Icons.add,
                                          label: 'Add New Department',
                                          onTap: () =>
                                              _showAddDepartmentDialog(context),
                                        ),
                                      _QuickActionItem(
                                        icon: Icons.bar_chart,
                                        label: 'View Statistics',
                                        onTap: () => _showStatisticsDialog(context),
                                      ),
                                      _QuickActionItem(
                                        icon: Icons.upload,
                                        label: 'Export Data',
                                        onTap: _exportData,
                                      ),
                                      _QuickActionItem(
                                        icon: Icons.people,
                                        label: 'Manage Faculty',
                                        onTap: () => _showFacultyManagementDialog(context),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Additional Stats
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _MiniStatCard(
                                        icon: '📈',
                                        number: stats['facultySatisfaction']!,
                                        label: 'Faculty Satisfaction',
                                      ),
                                      const SizedBox(height: 15),
                                      _MiniStatCard(
                                        icon: '🎯',
                                        number: stats['studentSuccessRate']!,
                                        label: 'Student Success Rate',
                                      ),
                                      const SizedBox(height: 15),
                                      _MiniStatCard(
                                        icon: '👨‍🏫',
                                        number: '${stats['avgFaculty']}',
                                        label: 'Avg Faculty/Dept',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
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

  void _viewDepartment(BuildContext context, Department department) {
    showDialog(
      context: context,
      builder: (context) => _DepartmentDetailDialog(department: department),
    );
  }

  void _showAddDepartmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _DepartmentFormDialog(
        onSave: (department) {
          _addDepartment(department);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department added successfully!')),
          );
        },
      ),
    );
  }

  void _showEditDepartmentDialog(BuildContext context, Department department) {
    showDialog(
      context: context,
      builder: (context) => _DepartmentFormDialog(
        department: department,
        onSave: (updatedDepartment) {
          _updateDepartment(updatedDepartment);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department updated successfully!')),
          );
        },
      ),
    );
  }

  void _showStatisticsDialog(BuildContext context) {
    final stats = _getStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Department Statistics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow('Total Departments', stats['totalDepartments']!.toString()),
              _StatRow('Total Faculty', stats['totalFaculty']!.toString()),
              _StatRow('Total Students', stats['totalStudents']!.toString()),
              _StatRow('Total Courses', stats['totalCourses']!.toString()),
              _StatRow('Average Faculty/Dept', stats['avgFaculty']!.toString()),
              _StatRow('Faculty Satisfaction', stats['facultySatisfaction']!),
              _StatRow('Student Success Rate', stats['studentSuccessRate']!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFacultyManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faculty Management'),
        content: const Text(
            'Faculty Management Interface:\n\n• Assign faculty to departments\n• View faculty profiles\n• Manage teaching assignments\n• Track faculty performance\n• Schedule classes\n• Manage workloads'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/teachers');
            },
            child: const Text('Go to Teachers'),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
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
                color: Color(0xFF333333),
              ),
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
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentCard({
    required this.department,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      department.code.isNotEmpty ? department.code[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${department.code} Department',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    number: department.faculty.toString(),
                    label: 'Faculty',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatItem(
                    number: department.students.toString(),
                    label: 'Students',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatItem(
                    number: department.courses.toString(),
                    label: 'Courses',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('View', style: TextStyle(fontSize: 13)),
                  ),
                ),
                if (ApiService().userRole != 'financial') ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Department'),
                            content: Text(
                                'Are you sure you want to delete ${department.name} Department?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  onDelete();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Department deleted')),
                                  );
                                },
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Delete', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$number $label',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF667EEA).withValues(alpha: 0.1),
          border: Border.all(
            color: const Color(0xFF667EEA).withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF667EEA)),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String icon;
  final String number;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF666666),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentDetailDialog extends StatelessWidget {
  final Department department;

  const _DepartmentDetailDialog({required this.department});

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
                  const Text(
                    'Department Details',
                    style: TextStyle(
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
              _DetailItem('Name', department.name),
              _DetailItem('Code', department.code),
              _DetailItem('Head of Department', department.head),
              _DetailItem('Email', department.email),
              if (department.phone != null)
                _DetailItem('Phone', department.phone!),
              _DetailItem('Faculty Members', department.faculty.toString()),
              _DetailItem('Students', department.students.toString()),
              _DetailItem('Courses', department.courses.toString()),
              if (department.establishedDate != null)
                _DetailItem('Established',
                    DateFormat('MMM dd, yyyy').format(department.establishedDate!)),
              if (department.description != null)
                _DetailItem('Description', department.description!),
            ],
          ),
        ),
      ),
    );
  }
}

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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentFormDialog extends StatefulWidget {
  final Department? department;
  final Function(Department) onSave;

  const _DepartmentFormDialog({
    this.department,
    required this.onSave,
  });

  @override
  State<_DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<_DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _headController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _facultyController;
  late TextEditingController _studentsController;
  late TextEditingController _coursesController;
  late TextEditingController _descriptionController;

  DateTime? _establishedDate;

  @override
  void initState() {
    super.initState();
    final dept = widget.department;
    _nameController = TextEditingController(text: dept?.name ?? '');
    _codeController = TextEditingController(text: dept?.code ?? '');
    _headController = TextEditingController(text: dept?.head ?? '');
    _emailController = TextEditingController(text: dept?.email ?? '');
    _phoneController = TextEditingController(text: dept?.phone ?? '');
    _facultyController =
        TextEditingController(text: dept?.faculty.toString() ?? '');
    _studentsController =
        TextEditingController(text: dept?.students.toString() ?? '');
    _coursesController =
        TextEditingController(text: dept?.courses.toString() ?? '');
    _descriptionController =
        TextEditingController(text: dept?.description ?? '');
    _establishedDate = dept?.establishedDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _headController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facultyController.dispose();
    _studentsController.dispose();
    _coursesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final department = Department(
        id: widget.department?.id ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        head: _headController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        faculty: int.tryParse(_facultyController.text.trim()) ?? 0,
        students: int.tryParse(_studentsController.text.trim()) ?? 0,
        courses: int.tryParse(_coursesController.text.trim()) ?? 0,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        establishedDate: _establishedDate,
      );

      widget.onSave(department);
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
                    widget.department == null
                        ? 'Add New Department'
                        : 'Edit Department',
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Department Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter department name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'Department Code *',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., CS, ME, EE',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter department code';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _headController,
                              decoration: const InputDecoration(
                                labelText: 'Head of Department *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter head of department';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _establishedDate ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _establishedDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 8),
                                    Text(
                                      _establishedDate == null
                                          ? 'Established Date (Optional)'
                                          : DateFormat('MMM dd, yyyy')
                                              .format(_establishedDate!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _facultyController,
                              decoration: const InputDecoration(
                                labelText: 'Number of Faculty *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter number of faculty';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _studentsController,
                              decoration: const InputDecoration(
                                labelText: 'Number of Students *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter number of students';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _coursesController,
                              decoration: const InputDecoration(
                                labelText: 'Number of Courses *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter number of courses';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
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
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                        widget.department == null ? 'Add Department' : 'Update Department'),
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
