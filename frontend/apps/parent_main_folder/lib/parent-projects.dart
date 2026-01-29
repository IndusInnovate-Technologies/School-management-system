import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_service.dart' as api;

// --- NEW FUNCTION TO CREATE CUSTOM MATERIAL COLOR ---
// This resolves the common conflict/error when defining a custom primary color.
MaterialColor createMaterialColor(Color color) {
  final List<double> strengths = <double>[
    .05,
    .1,
    .2,
    .3,
    .4,
    .5,
    .6,
    .7,
    .8,
    .9,
  ];
  final Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (var strength in strengths) {
    final int key = (strength * 1000).round(); // yields 50,100,...,900
    swatch[key] = Color.fromRGBO(r, g, b, strength);
  }

  return MaterialColor(color.value, swatch);
}

void main() => runApp(
  MaterialApp(
    home: const StudentProjectsPage(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      // FIX: Use the custom blue color as a PrimarySwatch to avoid errors
      primarySwatch: createMaterialColor(const Color(0xFF6A67FC)),
      // AppBar and UI elements will now correctly pick up this color
      primaryColor: const Color(0xFF6A67FC),
    ),
  ),
);

// Data models (Unchanged)
class Project {
  final int id;
  final String title;
  final String subject;
  final String status; // ongoing, completed, pending
  final double progress;
  final DateTime dueDate;
  final DateTime? submittedDate;
  final String? grade;
  final String description;
  final String teacher;
  final List<String> teamMembers;
  final List<String> files;

  Project({
    required this.id,
    required this.title,
    required this.subject,
    required this.status,
    required this.progress,
    required this.dueDate,
    this.submittedDate,
    this.grade,
    required this.description,
    required this.teacher,
    required this.teamMembers,
    required this.files,
  });
}

class UpcomingProject {
  final String title;
  final String subject;
  final DateTime dueDate;
  final String teacher;

  UpcomingProject({
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.teacher,
  });
}

class StudentProjectsPage extends StatefulWidget {
  const StudentProjectsPage({super.key});

  @override
  State<StudentProjectsPage> createState() => _StudentProjectsPageState();
}

class _StudentProjectsPageState extends State<StudentProjectsPage> {
  // Mock data (Unchanged)
  List<Project> allProjects = [];
  List<UpcomingProject> allUpcoming = [];

  String statusFilter = "all";
  String subjectFilter = "all";
  String searchTerm = "";
  bool _isLoading = true;



  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await api.ApiService.authenticatedRequest('student-parent/projects/', method: 'GET');
      if (response.statusCode == 200) {
        final dynamic rawData = json.decode(response.body);
        final List<dynamic> data;
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map && rawData.containsKey('results')) {
          data = rawData['results'];
        } else {
          data = [];
        }
        
        setState(() {
          allProjects = data.map((json) {
            // Backend returns flat structure now via serializer, but let's handle potential nested dicts if serializer acts up
            // Serializer structure: {id, title, subject, description, due_date, class_obj, teacher, file, ...}
            
            // Use teacher_name directly as provided by StudentProjectViewSerializer
            String teacherName = json['teacher_name'] ?? 'Unknown Teacher';
            
            // Fallback for legacy data or if serializer changes
            if (json['teacher'] != null && json['teacher'] is Map) {
                final teacherData = json['teacher'];
                teacherName = "${teacherData['first_name'] ?? ''} ${teacherData['last_name'] ?? ''}".trim();
                if (teacherName.isEmpty) teacherName = teacherData['employee_no'] ?? 'Teacher';
            }

            return Project(
              id: json['id'],
              title: json['title'] ?? 'Untitled',
              subject: json['subject'] ?? 'General',
              status: json['status'] ?? 'pending',
              progress: (json['status'] == 'completed' || json['status'] == 'submitted') ? 1.0 : (json['progress'] ?? 0.0) / 100.0,
              dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
              submittedDate: json['submission_date'] != null ? DateTime.tryParse(json['submission_date']) : null,
              grade: json['grade'],
              description: json['description'] ?? '',
              teacher: teacherName,
              teamMembers: [],
              files: json['file'] != null ? [json['file'].toString()] : [],
            );
          }).toList();
          
          // Populate upcoming projects (Due in future and not completed)
          final now = DateTime.now();
          allUpcoming = allProjects
              .where((p) => p.dueDate.isAfter(now) && p.status != 'completed')
              .take(3) // Top 3
              .map((p) => UpcomingProject(
                    title: p.title,
                    subject: p.subject,
                    dueDate: p.dueDate,
                    teacher: p.teacher,
                  ))
              .toList();

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error: $e');
    }
  }



  // Filtering logic (Unchanged)
  List<Project> get filteredProjects {
    return allProjects.where((project) {
      final statusMatches =
          statusFilter == "all" || project.status == statusFilter;
      final subjectMatches =
          subjectFilter == "all" ||
          project.subject.toLowerCase() == subjectFilter;
      final searchMatches =
          project.title.toLowerCase().contains(searchTerm) ||
          project.description.toLowerCase().contains(searchTerm) ||
          project.teacher.toLowerCase().contains(searchTerm);
      return statusMatches && subjectMatches && searchMatches;
    }).toList();
  }

  // Statistics (Unchanged)
  int get totalProjects => allProjects.length;
  int get ongoingProjects =>
      allProjects.where((p) => p.status == "ongoing").length;
  int get completedProjects =>
      allProjects.where((p) => p.status == "completed").length;
  int get upcomingProjectsCount => allUpcoming.length;
  int get completionRate => (totalProjects == 0)
      ? 0
      : ((completedProjects / totalProjects) * 100).round();

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    const appBarColor = Color(0xFF6A67FC);

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Projects Dashboard",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProjects,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Horizontal Stats (Styled to match the image cards)
                    _buildHorizontalStats(),
                    const SizedBox(height: 20),

                    // 3. Filters and Search
                    _buildFiltersAndSearch(),
                    const SizedBox(height: 15),

                    // 4. Upcoming Projects
                    _buildUpcomingProjectsSection(),
                    const SizedBox(height: 20),

                    // 5. Project List Header
                    Text(
                      "📝 All Projects (${filteredProjects.length})",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333333),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 6. Project List
                    _buildProjectList(),
                    const SizedBox(height: 20),

                    // 7. Statistics
                    _buildStatisticsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET BUILDERS (UPDATED) ---

  // Horizontal Stats Card Container
  Widget _buildHorizontalStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Styled for GPA/Class Rank look
            _statCard(
              Icons.book,
              totalProjects,
              'Total Projects',
              const Color(0xFF7246D9),
            ), // Purple
            _statCard(
              Icons.schedule,
              ongoingProjects,
              'Ongoing',
              Colors.orange,
            ), // Orange
            _statCard(
              Icons.check_circle_outline,
              completedProjects,
              'Completed',
              Colors.green,
            ), // Green check icon
            _statCard(
              Icons.calendar_today,
              allUpcoming.length,
              'Upcoming',
              const Color(0xff764ba2),
            ), // Custom color
          ],
        ),
      ),
    );
  }

  // Individual Stat Card (COMPACT STACKED STYLE - Matching Image 2)
  Widget _statCard(IconData icon, int number, String label, Color accentColor) {
    return Container(
      width: 115,
      height: 110, // Matching the requested rectangle look
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accentColor, size: 28),
                const SizedBox(height: 6),
                Text(
                  number.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff333333),
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filters and Search (Unchanged)
  Widget _buildFiltersAndSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field (Full Width)
        TextField(
          decoration: InputDecoration(
            hintText: "Search projects...",
            prefixIcon: const Icon(Icons.search, color: Color(0xff764ba2)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          onChanged: (v) => setState(() => searchTerm = v.toLowerCase()),
        ),
        const SizedBox(height: 12),

        // Dropdowns (Side by Side if possible, or stacked)
        Row(
          children: [
            Expanded(
              child: _filterDropdown(statusFilter, {
                'all': 'All Status',
                'ongoing': 'Ongoing',
                'completed': 'Completed',
                'pending': 'Pending',
              }, (v) => setState(() => statusFilter = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _filterDropdown(subjectFilter, {
                'all': 'All Subjects',
                'science': 'Science',
                'mathematics': 'Math',
                'english': 'English',
                'social studies': 'Social Studies',
              }, (v) => setState(() => subjectFilter = v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterDropdown(
    String selected,
    Map<String, String> items,
    void Function(String) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffe2e2e2), width: 1.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => onChanged(v!),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff764ba2)),
          style: const TextStyle(
            color: Color(0xff333333),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Project List (Unchanged)
  Widget _buildProjectList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredProjects.length,
      itemBuilder: (context, index) {
        return _projectCardMobile(filteredProjects[index]);
      },
    );
  }

  Widget _projectCardMobile(Project project) {
    Color statusColor;
    String statusText =
        project.status[0].toUpperCase() + project.status.substring(1);
    if (project.status == 'ongoing') {
      statusColor = const Color(0xffffd43b);
    } else if (project.status == 'completed') {
      statusColor = const Color(0xff51cf66);
    } else {
      statusColor = const Color(0xffff6b6b);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Title & Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xff333333),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor.darken(0.3),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 15),

            // 2. Core Details (Stacked vertically for narrow screen)
            _detailItem('Subject', project.subject),
            _detailItem(
              'Due Date',
              "${project.dueDate.year}-${project.dueDate.month}-${project.dueDate.day}",
            ),
            _detailItem('Teacher', project.teacher),
            if (project.grade != null) _detailItem('Class', project.grade!),
            const SizedBox(height: 15),

            // 3. Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(project.progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress,
                backgroundColor: const Color(0xffe9ecef),
                valueColor: const AlwaysStoppedAnimation(Color(0xff764ba2)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 15),

            // 4. Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text(
                      'Details',
                      style: TextStyle(fontSize: 14),
                    ),
                    onPressed: () => _showDetailsDialog(context, project),
                  ),
                ),
                if (project.files.isNotEmpty) const SizedBox(width: 8),
                if (project.files.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff764ba2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text(
                        'Files',
                        style: TextStyle(fontSize: 14),
                      ),
                      onPressed: () => _showSnackbar(
                        'Downloading files for ${project.title}',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for item details in card (Unchanged)
  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        '$label: ${value.length > 30 ? '${value.substring(0, 30)}...' : value}',
        style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
      ),
    );
  }

  // Upcoming Projects Section (Unchanged)
  Widget _buildUpcomingProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.calendar_today, color: Color(0xff764ba2)),
            SizedBox(width: 8),
            Text(
              "Upcoming Projects",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xff333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Use a ListView for vertical stacking of upcoming cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allUpcoming.length,
          itemBuilder: (context, index) => _upcomingCard(allUpcoming[index]),
        ),
      ],
    );
  }

  Widget _upcomingCard(UpcomingProject p) {
    return Container(
      padding: const EdgeInsets.all(13),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xff28a745), width: 4),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            "Due: ${p.dueDate.year}-${p.dueDate.month}-${p.dueDate.day} | ${p.subject}",
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          Text(
            "Teacher: ${p.teacher}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Statistics Section (Unchanged)
  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.bar_chart, color: Color(0xff764ba2)),
            SizedBox(width: 8),
            Text(
              "Project Statistics",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xff333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            children: [
              _statBar('Overall Completion Rate', completionRate),
              _statBarWithValue(
                'Average Grade (Completed)',
                85,
                'A-',
              ), // Manually provided mock stat
              _statBar('On-Time Submission Rate', 90),
            ],
          ),
        ),
      ],
    );
  }

  // Progress Bar Stat (Unchanged)
  Widget _statBar(String label, int percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$percent%",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: const Color(0xffe9ecef),
              valueColor: const AlwaysStoppedAnimation(Color(0xff764ba2)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Progress Bar Stat with Custom Value (Unchanged)
  Widget _statBarWithValue(String label, int percent, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: const Color(0xffe9ecef),
              valueColor: const AlwaysStoppedAnimation(Color(0xff764ba2)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Utility Functions (Unchanged)
  void _showSnackbar(String message) {
    // Check if context is available before showing Snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
    }
  }

  void _showDetailsDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(project.title),
          content: SingleChildScrollView(
            child: Text(
              "Subject: ${project.subject}\nStatus: ${project.status[0].toUpperCase() + project.status.substring(1)}\nDue Date: ${project.dueDate.year}-${project.dueDate.month}-${project.dueDate.day}\nTeacher: ${project.teacher}\nTeam: ${project.teamMembers.join(', ')}\n\nDescription: ${project.description}\n\nFiles: ${project.files.join(', ')}",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Extension to darken colors slightly for text contrast on light backgrounds
extension on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    final newLightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}
