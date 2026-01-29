import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'package:intl/intl.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherTimetablePage extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final bool canEdit;

  const TeacherTimetablePage({
    Key? key,
    required this.teacherId,
    required this.teacherName,
    this.canEdit = true,
  }) : super(key: key);

  @override
  State<TeacherTimetablePage> createState() => _TeacherTimetablePageState();
}

class _TeacherTimetablePageState extends State<TeacherTimetablePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _timetableEntries = [];
  String _selectedView = 'Daily'; // Daily, Weekly, Monthly
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  bool _isSelectionMode = false;
  Set<int> _selectedEntryIds = {};
  
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  List<String> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  String _formatTimeSlot(String time24) {
    // Converts HH:mm:ss to h:mm AM/PM for time slot labels
    try {
      final parts = time24.split(':');
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      return time24;
    }
  }

  Future<void> _fetchTimetable() async {
    if (!_isLoading) {
      if (mounted) setState(() => _isLoading = true);
    }
    
    try {
      final response = await ApiService().get(
        Endpoints.timetables,
        queryParameters: {'teacher_id': widget.teacherId},
      );

      if (response.success && response.data != null) {
        final rawData = response.data;
        
        final List<dynamic> data;
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map) {
          data = (rawData['results'] ?? rawData['data'] ?? []) as List;
        } else {
          data = [];
        }
        
        setState(() {
          try {
            _timetableEntries = List<Map<String, dynamic>>.from(data);
            
            final slots = <String>{};
            for (var entry in _timetableEntries) {
              final startTime = entry['start_time']?.toString() ?? '';
              if (startTime.isNotEmpty) {
                slots.add(_formatTimeSlot(startTime));
              }
            }
            
            final sortedSlots = slots.toList()..sort((a, b) {
              try {
                int to24(String t) {
                  final parts = t.split(':');
                  if (parts.length < 2) return 0;
                  final h = int.parse(parts[0]);
                  final mParts = parts[1].split(' ');
                  final m = int.parse(mParts[0]);
                  final isPM = t.contains('PM');
                  return (isPM && h != 12 ? h + 12 : (h == 12 && !isPM ? 0 : h)) * 100 + m;
                }
                return to24(a).compareTo(to24(b));
              } catch (e) {
                return 0;
              }
            });
            
            _timeSlots = sortedSlots;
            
            // Set default slots if empty
            if (_timeSlots.isEmpty) {
              _timeSlots = ['8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM'];
            }
          } catch (e) {
            debugPrint('Error processing data: $e');
            _timeSlots = ['8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM'];
          }
        });
      } else {
        debugPrint('API Error: ${response.error}');
      }
    } catch (e) {
      debugPrint('Timetable fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _downloadTemplate() async {
    try {
      final url = Uri.parse(Endpoints.buildUrl(Endpoints.teacherTimetableTemplate));
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch download URL')));
      }
    } catch (e) {
      debugPrint('Error downloading template: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickAndImportFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, 
      );

      if (result != null && result.files.isNotEmpty) {
         if (mounted) setState(() => _isLoading = true);

        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;

        if (fileBytes == null) {
          throw Exception('Could not read file data');
        }

        // Add teacher_id as query parameter for validation
        final endpoint = '${Endpoints.teacherTimetableImport}?teacher_id=${widget.teacherId}';

        final response = await ApiService().uploadFile(
          endpoint,
          fileBytes: fileBytes,
          fileName: fileName,
        );

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data['message'] ?? 'Import successful')),
            );
          }
          _fetchTimetable();
        } else {
           if (mounted) {
            String errorMsg = response.error ?? 'Upload failed';
            if (response.data != null && response.data['errors'] != null) {
              errorMsg += ': ${(response.data['errors'] as List).join(', ')}';
            }
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), duration: const Duration(seconds: 5)),
            );
          }
           if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error importing file: $e');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _deleteAllTimetable() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Timetable'),
        content: Text('Are you sure you want to delete ALL timetable entries for ${widget.teacherName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (mounted) setState(() => _isLoading = true);

      final response = await ApiService().delete(
        '${Endpoints.timetables}delete-by-teacher/?teacher_id=${widget.teacherId}',
      );



      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'All timetable entries deleted')),
          );
        }
        _fetchTimetable();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to delete timetable')),
          );
        }
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error deleting timetable: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEntryIds.clear();
      }
    });
  }

  void _toggleEntrySelection(int entryId) {
    setState(() {
      if (_selectedEntryIds.contains(entryId)) {
        _selectedEntryIds.remove(entryId);
      } else {
        _selectedEntryIds.add(entryId);
      }
    });
  }

  Future<void> _deleteSelectedEntries() async {
    if (_selectedEntryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries selected')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Entries'),
        content: Text('Are you sure you want to delete ${_selectedEntryIds.length} selected entries?'),
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

    if (confirmed != true) return;

    try {
      if (mounted) setState(() => _isLoading = true);

      final response = await ApiService().post(
        '${Endpoints.timetables}delete-selected/',
        body: {'entry_ids': _selectedEntryIds.toList()},
      );


      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Deleted')),
          );
          setState(() {
            _isSelectionMode = false;
            _selectedEntryIds.clear();
          });
        }
        _fetchTimetable();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed')),
          );
        }
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const ManagementSidebar(
            activeRoute: '/teachers',
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTimetableView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timetable - ${widget.teacherName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getViewSubtitle(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedView != 'Weekly') ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _previousDate,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _nextDate,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildViewToggle(),
              const SizedBox(width: 16),
              // Download Template Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.download_rounded, color: Color(0xFF667EEA)),
                  tooltip: 'Download Excel Template',
                  onPressed: _downloadTemplate,
                ),
              ),
              const SizedBox(width: 8),
              // Import Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.upload_file, color: Color(0xFF667EEA)),
                  tooltip: 'Import from Excel',
                  onPressed: _pickAndImportFile,
                ),
              ),
              const SizedBox(width: 8),
              // Selection Mode Buttons
              if (_isSelectionMode) ...[
                // Cancel Selection Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                    onPressed: _toggleSelectionMode,
                  ),
                ),
                const SizedBox(width: 8),
                // Delete Selected Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: Text(
                      'Delete Selected (${_selectedEntryIds.length})',
                      style: const TextStyle(color: Colors.red),
                    ),
                    onPressed: _deleteSelectedEntries,
                  ),
                ),
              ] else ...[
                // Select Button (when not in selection mode)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.checklist, color: Color(0xFF667EEA)),
                    tooltip: 'Select Entries',
                    onPressed: _toggleSelectionMode,
                  ),
                ),
                const SizedBox(width: 8),
                // Delete All Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    tooltip: 'Delete All Timetable',
                    onPressed: _deleteAllTimetable,
                  ),
                ),
              ],
              const SizedBox(width: 16),
              _buildAddButton(),
            ],
          ),
        ],
      ),
    );
  }

  String _getViewSubtitle() {
    if (_selectedView == 'Weekly') {
      return 'Week of ${DateFormat('MMMM d, yyyy').format(DateTime.now())}';
    } else if (_selectedView == 'Daily') {
      return DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    } else {
      return DateFormat('MMMM yyyy').format(_currentMonth);
    }
  }

  void _previousDate() {
    setState(() {
      if (_selectedView == 'Daily') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else if (_selectedView == 'Monthly') {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      }
    });
  }

  void _nextDate() {
    setState(() {
      if (_selectedView == 'Daily') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      } else if (_selectedView == 'Monthly') {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      }
    });
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly'].map((view) {
          final isSelected = _selectedView == view;
          return GestureDetector(
            onTap: () => setState(() => _selectedView = view),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                view,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF667EEA) : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddEntryDialog(),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add Entry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableView() {
    if (_selectedView == 'Weekly') {
      return _buildWeeklyView();
    } else if (_selectedView == 'Daily') {
      return _buildDailyView();
    } else {
      return _buildMonthlyView();
    }
  }

  Widget _buildWeeklyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
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
            // Header row with days
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 80), // Time column width
                  ..._days.map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            // Time slots
            ..._timeSlots.map((timeSlot) => _buildTimeSlotRow(timeSlot)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotRow(String timeSlot) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          Container(
            width: 80,
            padding: const EdgeInsets.all(16),
            child: Text(
              timeSlot,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Day cells
          ..._days.map((day) {
            final dayIndex = _days.indexOf(day);
            final entry = _getEntryForDayAndTime(dayIndex, timeSlot);
            
            return Expanded(
              child: Container(
                height: 80,
                margin: const EdgeInsets.all(4),
                child: entry != null
                    ? _buildTimetableCard(entry)
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getEntryForDayAndTime(int dayIndex, String timeSlot) {
    for (var entry in _timetableEntries) {
      if (entry['day_of_week']?.toString() == dayIndex.toString()) {
        final startTime = entry['start_time']?.toString() ?? '';
        if (startTime.isNotEmpty && _formatTimeSlot(startTime) == timeSlot) {
          return entry;
        }
      }
    }
    return null;
  }

  Widget _buildTimetableCard(Map<String, dynamic> entry) {
    final entryType = entry['entry_type'] ?? 'class';
    Color color;
    
    // Set color based on entry type
    if (entryType == 'break') {
      color = const Color(0xFFED8936); // Orange
    } else if (entryType == 'lunch') {
      color = const Color(0xFF48BB78); // Green
    } else {
      color = Color(int.parse(entry['color']?.replaceAll('#', '0xFF') ?? '0xFF667EEA'));
    }
    
    final entryId = entry['id'] as int;
    final isSelected = _selectedEntryIds.contains(entryId);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleEntrySelection(entryId);
        } else {
          _showEntryDetails(entry);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (entryType != 'class') 
                      Icon(
                        entryType == 'break' ? Icons.coffee_rounded : Icons.restaurant_rounded,
                        size: 14,
                        color: color,
                      ),
                    if (entryType != 'class') const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        entry['subject'] ?? (entryType == 'break' ? 'Break' : 'Lunch'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (entryType == 'class') ...[
                  Text(
                    _formatClass(entry['class_obj']),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry['room'] != null && entry['room'].toString().isNotEmpty)
                    Text(
                      'Room ${entry['room']}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ],
            ),
            if (_isSelectionMode)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? color : Colors.grey,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyView() {
    final dayOfWeek = _selectedDate.weekday - 1; // 0 = Monday, 6 = Sunday
    
    // Filter entries for the selected day
    final dayEntries = _timetableEntries.where((entry) {
      return entry['day_of_week']?.toString() == dayOfWeek.toString();
    }).toList();

    // Sort entries by start time
    dayEntries.sort((a, b) => (a['start_time'] as String).compareTo(b['start_time'] as String));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: dayEntries.isEmpty ? 1 : dayEntries.length,
      itemBuilder: (context, index) {
        if (dayEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No classes scheduled for this day (Checked ${dayOfWeek})',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final entry = dayEntries[index];
        final color = Color(int.parse(entry['color']?.replaceAll('#', '0xFF') ?? '0xFF667EEA'));
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(
                      _formatTime(entry['start_time']),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      _formatTime(entry['end_time']),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Timeline line
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 80,
                    color: Colors.grey[200],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Card
              Expanded(
                child: _buildTimetableCardDetailed(entry, color),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(dynamic timeStr) {
    if (timeStr == null) return '';
    try {
      final parts = timeStr.toString().split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      return timeOfDay.format(context);
    } catch (e) {
      return timeStr.toString();
    }
  }

  String _formatClass(dynamic classObj) {
    if (classObj == null) return '';
    if (classObj is Map) {
      return 'Class ${classObj['name']} - ${classObj['section']}';
    }
    return classObj.toString();
  }

  void _showEntryDetails(Map<String, dynamic> entry) {
    final color = Color(int.parse(entry['color'].replaceAll('#', '0xFF')));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry['subject'] ?? 'No Subject', style: TextStyle(color: color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.access_time, '${_formatTime(entry['start_time'])} - ${_formatTime(entry['end_time'])}'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.people, _formatClass(entry['class_obj'])),
            const SizedBox(height: 12),
            if (entry['room'] != null && entry['room'].toString().isNotEmpty) ...[
              _buildDetailRow(Icons.location_on, 'Room: ${entry['room']}'),
              const SizedBox(height: 12),
            ],
            // Show Day
             _buildDetailRow(Icons.calendar_today, [
                'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
              ][entry['day_of_week'] ?? 0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (widget.canEdit) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close detail dialog
                _deleteEntry(entry['id']);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close detail dialog
                _showEditEntryDialog(entry);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
              child: const Text('Edit'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _buildTimetableCardDetailed(Map<String, dynamic> entry, Color color) {
    final entryId = entry['id'] as int;
    final isSelected = _selectedEntryIds.contains(entryId);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleEntrySelection(entryId);
        } else {
          _showEntryDetails(entry);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? color : Colors.grey,
                  size: 24,
                ),
              ),
            Container(
              width: 6,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['subject'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatClass(entry['class_obj']),
                          style: TextStyle(color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (entry['room'] != null && entry['room'].toString().isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Room ${entry['room']}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!_isSelectionMode)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final startingGridIndex = firstDayOfMonth - 1;

    final List<String> weekDaysSmall = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: weekDaysSmall.map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF718096)),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.4, // Reduced height (taller ratio means shorter height relative to width)
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayNumber = index - startingGridIndex + 1;
                final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
                
                if (!isCurrentMonth) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }

                final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final dayOfWeek = date.weekday - 1;
                final dayEntries = _timetableEntries.where((e) => e['day_of_week'] == dayOfWeek).toList();
                final isToday = date.day == DateTime.now().day && 
                               date.month == DateTime.now().month && 
                               date.year == DateTime.now().year;

                return GestureDetector(
                  onTap: () => _showDayDetails(date, dayEntries),
                  child: Container(
                    decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isToday ? const Color(0xFF667EEA) : Colors.grey[200]!,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Day Number
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCurrentMonth ? const Color(0xFF2D3748) : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                      // Dots at bottom
                      if (dayEntries.isNotEmpty)
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              alignment: WrapAlignment.center,
                              children: dayEntries.take(4).map((e) {
                                final color = Color(int.parse(e['color']?.replaceAll('#', '0xFF') ?? '0xFF667EEA'));
                                return Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(DateTime date, List<dynamic> entries) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.day}/${date.month}/${date.year} Classes'),
        content: SizedBox(
          width: double.maxFinite,
          child: entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No classes scheduled for this day.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final color = Color(int.parse(entry['color']?.replaceAll('#', '0xFF') ?? '0xFF667EEA'));
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showEntryDetails(entry);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry['subject'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_formatTime(entry['start_time'])} - ${_formatTime(entry['end_time'])}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _formatClass(entry['class_obj']),
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    );
                  },
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

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => _TimetableEntryDialog(
        teacherId: widget.teacherId,
        onSave: () {
          Navigator.pop(context);
          _fetchTimetable();
        },
      ),
    );
  }

  void _showEditEntryDialog(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => _TimetableEntryDialog(
        teacherId: widget.teacherId,
        entry: entry,
        onSave: () {
          Navigator.pop(context);
          _fetchTimetable();
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteEntry(entry['id']);
        },
      ),
    );
  }

  Future<void> _deleteEntry(int id) async {
    try {
      final response = await ApiService().delete('${Endpoints.timetables}$id/');
      if (response.success) {
        _fetchTimetable();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timetable entry deleted')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }
}

class _TimetableEntryDialog extends StatefulWidget {
  final String teacherId;
  final Map<String, dynamic>? entry;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _TimetableEntryDialog({
    required this.teacherId,
    this.entry,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_TimetableEntryDialog> createState() => _TimetableEntryDialogState();
}

class _TimetableEntryDialogState extends State<_TimetableEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _sectionController;
  late TextEditingController _roomController;
  
  List<dynamic> _allClasses = [];
  String? _selectedClassName;
  bool _isLoadingClasses = true;

  // New multi-day selection
  Set<int> _selectedDays = {};
  String _entryType = 'class'; // class, break, lunch
  
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  Color _selectedColor = const Color(0xFF667EEA);
  
  final List<Color> _colors = [
    const Color(0xFF667EEA),
    const Color(0xFFED8936),
    const Color(0xFF48BB78),
    const Color(0xFFED64A6),
    const Color(0xFF9F7AEA),
    const Color(0xFFECC94B),
  ];

  final List<String> _availableClasses = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12'
  ];

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.entry?['subject'] ?? '');
    _sectionController = TextEditingController(text: widget.entry?['class_obj']?['section'] ?? '');
    _roomController = TextEditingController(text: widget.entry?['room'] ?? '');
    
    _fetchClasses();
    
    if (widget.entry != null) {
      _selectedDays = {widget.entry!['day_of_week'] ?? 0};
      _entryType = widget.entry!['entry_type'] ?? 'class';
      _selectedColor = Color(int.parse(widget.entry!['color']?.replaceAll('#', '0xFF') ?? '0xFF667EEA'));
      
      // Parse times
      if (widget.entry!['start_time'] != null) {
        final parts = widget.entry!['start_time'].split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (widget.entry!['end_time'] != null) {
        final parts = widget.entry!['end_time'].split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } else {
       // Default to today or Monday
       final today = DateTime.now().weekday - 1;
       _selectedDays = {today >= 0 && today < 7 ? today : 0};
    }
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await ApiService().get(Endpoints.teacherClasses);
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['results'] ?? []);
        setState(() {
          _allClasses = data;
          
          if (widget.entry != null && widget.entry!['class_obj'] != null) {
            final classObj = widget.entry!['class_obj'];
            String rawName = classObj['name']?.toString() ?? '';
             // Normalize: If rawName is "8", try to match "Class 8"
            if (!_availableClasses.contains(rawName)) {
               String potentialName = 'Class $rawName';
               if (_availableClasses.contains(potentialName)) {
                 _selectedClassName = potentialName;
               } else {
                 if (rawName.isNotEmpty) {
                    _availableClasses.add(rawName);
                    _availableClasses.sort(); 
                    _selectedClassName = rawName;
                 }
               }
            } else {
              _selectedClassName = rawName;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching classes for validation: $e');
    } finally {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _saveEntry() async {
    if (_isLoadingClasses) return;
    if (!_formKey.currentState!.validate()) return;

    // Only validate class/section for 'class' type entries
    if (_entryType == 'class') {
      if (_selectedClassName == null || _sectionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Class and enter Section')),
        );
        return;
      }
    }

    int? classId;
    if (_entryType == 'class') {
      // Find class ID matching name and section
      final selectedClass = _allClasses.firstWhere(
        (c) => c['name'] == _selectedClassName && 
               c['section'].toString().toLowerCase() == _sectionController.text.toLowerCase(),
        orElse: () => null,
      );

      if (selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class "$_selectedClassName - ${_sectionController.text}" not found. Please contact admin to create it.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      
      classId = selectedClass['id'];
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoadingClasses = true); 

    try {
      // Loop through each selected day and save
      for (final day in _selectedDays) {
         final data = {
          'teacher_id': widget.teacherId,
          'entry_type': _entryType,
          'day_of_week': day,
          'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
          'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
          'color': '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        };
        
        // Add class-specific fields only for 'class' type
        if (_entryType == 'class') {
          data['class_id'] = classId!; // Safe because we validated above
          data['subject'] = _subjectController.text;
          data['room'] = _roomController.text;
        } else {
          // For break/lunch, use entry_type as subject
          data['subject'] = _entryType == 'break' ? 'Break' : 'Lunch Break';
        }


        if (widget.entry != null) {
          // Update existing
          await ApiService().put('${Endpoints.timetables}${widget.entry!['id']}/', body: data);
        } else {
          // Create new
          await ApiService().post(Endpoints.timetables, body: data);
        }
      }
      
      if (mounted) {
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving timetable: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(time.format(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entry == null ? 'Add Timetable Entry' : 'Edit Timetable Entry'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Entry Type Selector
                DropdownButtonFormField<String>(
                  value: _entryType,
                  decoration: const InputDecoration(
                    labelText: 'Entry Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'class', child: Text('Class')),
                    DropdownMenuItem(value: 'break', child: Text('Break')),
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  ],
                  onChanged: (v) => setState(() {
                    _entryType = v!;
                    // Set default colors
                    if (v == 'break') {
                      _selectedColor = const Color(0xFFED8936); // Orange
                    } else if (v == 'lunch') {
                      _selectedColor = const Color(0xFF48BB78); // Green
                    }
                  }),
                ),
                const SizedBox(height: 16),
                
                // Conditional fields for 'class' type only
                if (_entryType == 'class') ...[
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingClasses)
                     const LinearProgressIndicator(), 
                  
                  Builder(
                    builder: (context) {
                      final List<String> dropdownItems = List.from(_availableClasses);
                      if (_selectedClassName != null && !dropdownItems.contains(_selectedClassName)) {
                        dropdownItems.add(_selectedClassName!);
                        dropdownItems.sort();
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: _selectedClassName,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select a class'),
                        items: dropdownItems.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedClassName = v),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _sectionController,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                    hintText: 'e.g. A, B, Lotus',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                ], // End of conditional class fields
                const SizedBox(height: 16),
                
                const Text('Days', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
                    final isSelected = _selectedDays.contains(index);
                    return FilterChip(
                      label: Text(dayName),
                      selected: isSelected,
                      onSelected: (selected) {
                         setState(() {
                          if (widget.entry != null) {
                             // Edit mode: Single select
                             _selectedDays = {index};
                          } else {
                             // Add mode: Multi select
                             if (selected) {
                               _selectedDays.add(index);
                             } else {
                               if (_selectedDays.length > 1) _selectedDays.remove(index);
                             }
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker('Start Time', _startTime, (time) {
                        setState(() {
                          _startTime = time;
                          // Auto-set end time to start time + 1 hour
                          int newHour = time.hour + 1;
                          int newMinute = time.minute;
                          
                          // Handle day rollover if needed (though unlikely for school)
                          if (newHour >= 24) {
                            newHour = 0;
                          }
                          
                          _endTime = TimeOfDay(hour: newHour, minute: newMinute);
                        });
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker('End Time', _endTime, (time) {
                        setState(() => _endTime = time);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text('Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.onDelete != null)
                      TextButton(
                        onPressed: widget.onDelete,
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoadingClasses ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoadingClasses 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _sectionController.dispose();
    _roomController.dispose();
    super.dispose();
  }
}
