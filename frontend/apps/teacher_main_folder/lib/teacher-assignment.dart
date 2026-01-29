import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'teacher-profile.dart';

// --- Mock Data for Subjects, Classes, and Sections (CLEANED) ---
const List<String> allSubjects = [
  'Mathematics',
  'General Science',
  'Social Studies',
  'Language I/II/III',
  'Physics',
  'Chemistry',
  'Biology',
  'English Core',
  'Computer Science',
  'History/Civics/Geography',
  'English Language/Literature',
  'Psychology',
  'Economics',
  'Art',
  'Music',
  'History',
];

const Map<String, List<String>> mockSections = {
  'Nursery': ['Teddy Bears', 'Tiny Tots'],
  'LKG': ['Little Stars', 'Sunshine'],
  'UKG': ['Rising Stars', 'Bright Buds'],
  'I': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'II': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'III': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'IV': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'V': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'VI': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'VII': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'VIII': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'IX': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'X': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'XI': ['Science - A', 'Commerce - B', 'Arts - C'],
  'XII': ['Science - A', 'Commerce - B', 'Arts - C'],
};
const List<String> allClasses = [
  'Nursery',
  'LKG',
  'UKG',
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
  'XI',
  'XII',
];

// --- Model Class: Assignment (Updated) ---
class Assignment {
  final int id;
  String title;
  String board;
  String subject;
  String className;
  String section;
  DateTime dueDate;
  int marks;
  int weightage;
  String description;
  String instructions;
  String resources;
  String type;
  String submissionType;
  String priority;
  bool isCompleted;

  Assignment({
    required this.id,
    required this.title,
    required this.board,
    required this.subject,
    required this.className,
    required this.section,
    required this.dueDate,
    required this.marks,
    required this.weightage,
    required this.description,
    required this.instructions,
    this.resources = '',
    required this.type,
    required this.submissionType,
    required this.priority,
    this.isCompleted = false,
  });

  // Helper method for creating a copy, useful for editing
  Assignment copyWith({
    String? title,
    String? board,
    String? subject,
    String? className,
    String? section,
    DateTime? dueDate,
    int? marks,
    int? weightage,
    String? description,
    String? instructions,
    String? resources,
    String? type,
    String? submissionType,
    String? priority,
    bool? isCompleted,
  }) {
    return Assignment(
      id: id,
      title: title ?? this.title,
      board: board ?? this.board,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      section: section ?? this.section,
      dueDate: dueDate ?? this.dueDate,
      marks: marks ?? this.marks,
      weightage: weightage ?? this.weightage,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      resources: resources ?? this.resources,
      type: type ?? this.type,
      submissionType: submissionType ?? this.submissionType,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// --- Main Application Widget ---
void main() {
  runApp(const TeacherDashboardApp());
}

class TeacherDashboardApp extends StatelessWidget {
  const TeacherDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assignment Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Segoe UI',
      ),
      home: const AssignmentDashboardScreen(),
    );
  }
}

// --- Dashboard Screen (Stateful Widget to manage data) ---
class AssignmentDashboardScreen extends StatefulWidget {
  const AssignmentDashboardScreen({super.key});

  @override
  State<AssignmentDashboardScreen> createState() =>
      _AssignmentDashboardScreenState();
}

class _AssignmentDashboardScreenState extends State<AssignmentDashboardScreen> {
  // Mock Data
  late List<Assignment> assignments;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  // Form State Variables and Controllers (for Create Form)
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _marksController = TextEditingController(
    text: '100',
  );
  final TextEditingController _weightageController = TextEditingController(
    text: '20',
  );
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _instController = TextEditingController();
  final TextEditingController _resController = TextEditingController();

  String? _selectedSubject;
  String? _selectedClass;
  String? _selectedSection;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedType;
  String? _selectedSubmissionType;
  String _selectedPriority = 'Medium';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Simplified Mock Initialization - Subject names updated to match the new list
    assignments = [
      Assignment(
        id: 1,
        title: "Algebra Problem Set",
        board: "CBSE",
        subject: "Mathematics", // Updated from "Mathematics (CBSE)"
        className: "X",
        section: "A - Fredo Fighters",
        dueDate: DateTime.now().subtract(const Duration(days: 30)),
        marks: 50,
        weightage: 10,
        description:
            "Complete problems 1-20 from Chapter 3 on Quadratic Equations. Show all intermediate steps clearly for full credit.",
        instructions:
            "Submit a single PDF file containing your handwritten or digitally prepared solutions. Late submissions will incur a 10% penalty per day.",
        resources: "Textbook PDF, Solution Guide Link",
        type: "Homework",
        submissionType: "Online",
        priority: "High",
        isCompleted: false,
      ),
      Assignment(
        id: 3,
        title: "English Essay",
        board: "ICSE",
        subject:
            "English Language/Literature", // Retained name from the simplified list
        className: "XII",
        section: "Arts - C",
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        marks: 75,
        weightage: 30,
        description:
            "Write a critical 1000-word essay on 'The Role of Social Media in Modern Democracy'. Focus on two primary arguments.",
        instructions:
            "Use MLA format (8th edition). The essay must be submitted via the LMS text box and a hard copy to the teacher's desk.",
        resources: "Guide Link",
        type: "Essay",
        submissionType: "Both",
        priority: "Critical",
        isCompleted: true, // Example of a completed assignment
      ),
    ];
  }

  // --- Core Logic ---

  void _onClassChanged(String? newClass) {
    setState(() {
      _selectedClass = newClass;
      // Resets section when class changes to avoid invalid state
      _selectedSection = null;
    });
  }

  void _createAssignment() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        final newAssignment = Assignment(
          id: assignments.length + 1,
          // Board hardcoded as N/A
          board: "N/A",
          title: _titleController.text,
          subject: _selectedSubject!,
          className: _selectedClass!,
          section: _selectedSection!,
          dueDate: _selectedDueDate,
          marks: int.tryParse(_marksController.text) ?? 0,
          weightage: int.tryParse(_weightageController.text) ?? 0,
          description: _descController.text,
          instructions: _instController.text,
          resources: _resController.text,
          type: _selectedType!,
          submissionType: _selectedSubmissionType!,
          priority: _selectedPriority,
          isCompleted: false,
        );
        assignments.insert(0, newAssignment);
        _resetForm();
      });
      _showSnackBar('Assignment created successfully!');
    }
  }

  void _updateAssignment(Assignment updatedAssignment) {
    setState(() {
      final index = assignments.indexWhere((a) => a.id == updatedAssignment.id);
      if (index != -1) {
        assignments[index] = updatedAssignment;
      }
    });
    _showSnackBar('Assignment updated successfully!');
  }

  void _deleteAssignment(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this assignment?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                assignments.removeWhere((a) => a.id == id);
              });
              Navigator.of(ctx).pop();
              _showSnackBar('Assignment deleted successfully.');
            },
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _marksController.text = '100';
    _weightageController.text = '20';
    _descController.clear();
    _instController.clear();
    _resController.clear();
    setState(() {
      _selectedSubject = null;
      _selectedClass = null;
      _selectedSection = null;
      _selectedDueDate = DateTime.now().add(const Duration(days: 1));
      _selectedType = null;
      _selectedSubmissionType = null;
      _selectedPriority = 'Medium';
    });
  }

  // --- UI Helpers ---

  Map<String, dynamic> getAssignmentStatus(Assignment assignment) {
    if (assignment.isCompleted) {
      return {'text': 'Completed', 'color': Colors.blue};
    }

    final dueDate = assignment.dueDate;
    final now = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final due = dueDate.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final diffDays = due.difference(now).inDays;

    if (diffDays < 0) {
      return {'text': 'Overdue', 'color': Colors.redAccent};
    } else if (diffDays <= 1) {
      return {'text': 'Due Soon', 'color': Colors.amber.shade700};
    } else {
      return {'text': 'Active', 'color': Colors.green};
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // --- Management Components ---

  Widget _buildManagementRow(
    String title, {
    required VoidCallback onAdd,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title Management:',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Form Input Widgets ---

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
    bool isDense = false,
    bool hasLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hasLabel ? label : null,
          hintText: !hasLabel ? hint : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: isDense
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12)
              : const EdgeInsets.all(15),
          labelStyle: const TextStyle(overflow: TextOverflow.ellipsis),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (isNumber && int.tryParse(value) == null) {
            return 'Must be a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selectedValue,
    void Function(String?) onChanged, {
    bool isDense = false,
    bool hasLabel = true,
    bool isTight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: hasLabel ? label : null,
          hintText: !hasLabel ? label : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: isTight
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 10)
              : const EdgeInsets.all(15).copyWith(right: 15),
          isDense: isDense,
          labelStyle: const TextStyle(overflow: TextOverflow.ellipsis),
        ),
        initialValue: selectedValue,
        hint: Text(label, overflow: TextOverflow.ellipsis),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select a $label' : null,
      ),
    );
  }

  Widget _buildDatePickerField({
    required DateTime initialDate,
    required void Function(DateTime) onDateSelected,
    bool isDense = false,
    bool hasLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
          );
          if (picked != null && picked != initialDate) {
            onDateSelected(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: hasLabel ? 'Due Date' : null,
            hintText: !hasLabel ? 'Due Date' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: isDense
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 10)
                : const EdgeInsets.all(15),
            labelStyle: const TextStyle(overflow: TextOverflow.ellipsis),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  _dateFormatter.format(initialDate),
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Form Builder (For Create Assignment) ---
  Widget _buildAssignmentForm() {
    final List<String> currentSections = _selectedClass != null
        ? mockSections[_selectedClass] ?? const []
        : const [];

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 1. Assignment Title (Full width)
          _buildTextField(
            _titleController,
            'Assignment Title',
            'Enter assignment title',
          ),

          // 2. Class Dropdown (Full width)
          _buildDropdownField(
            'Class',
            allClasses,
            _selectedClass,
            _onClassChanged,
            isDense: false,
            hasLabel: false,
          ),

          // 3. Section Dropdown (Full width)
          _buildDropdownField(
            'Section',
            currentSections,
            _selectedSection,
            (value) => setState(() => _selectedSection = value),
            isDense: false,
            hasLabel: false,
          ),

          // Class/Section Management
          _buildManagementRow(
            'Class/Section',
            onAdd: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Class/Section'),
                  content: const Text('Feature coming soon'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            onEdit: () {
              if (_selectedClass == null) {
                _showSnackBar('Please select a class first');
                return;
              }
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Class/Section'),
                  content: Text('Edit Class: ${_selectedClass ?? 'N/A'}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          // 4. Subject (Full width)
          _buildDropdownField(
            'Subject',
            allSubjects,
            _selectedSubject,
            (value) => setState(() => _selectedSubject = value),
            isDense: false,
            hasLabel: false,
          ),

          // Subject Management
          _buildManagementRow(
            'Subject',
            onAdd: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Subject'),
                  content: const Text('Feature coming soon'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            onEdit: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Edit Subjects'),
                  content: const Text('Feature coming soon'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          // 5. Due Date & Max Marks (Row - kept together as they are short)
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  initialDate: _selectedDueDate,
                  onDateSelected: (newDate) =>
                      setState(() => _selectedDueDate = newDate),
                  isDense: true,
                  hasLabel: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _marksController,
                  'Max Marks',
                  '100',
                  isNumber: true,
                  isDense: true,
                  hasLabel: false,
                ),
              ),
            ],
          ),

          // 6. Weightage (Full width with labelText)
          _buildTextField(
            _weightageController,
            'Weightage (%)',
            'e.g., 20',
            isNumber: true,
          ),

          // 7. Description & Instructions (Full width with labelText)
          _buildTextField(
            _descController,
            'Assignment Description',
            'Enter detailed assignment description...',
            maxLines: 3,
          ),
          _buildTextField(
            _instController,
            'Instructions',
            'Enter instructions for students...',
            maxLines: 3,
          ),

          // 8. Additional Resources (Full width with labelText)
          _buildTextField(
            _resController,
            'Additional Resources',
            'Links or file names (optional)',
            maxLines: 2,
          ),

          // 9. Assignment Type & Submission Type - Fixed to stack on mobile
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Stacked (Column) layout for narrow screens
                return Column(
                  children: [
                    _buildDropdownField(
                      'Assignment Type',
                      [
                        'Homework',
                        'Project',
                        'Lab Report',
                        'Essay',
                        'Presentation',
                        'Quiz',
                      ],
                      _selectedType,
                      (value) => setState(() => _selectedType = value),
                      isDense: false,
                      hasLabel: true,
                      isTight: false,
                    ),
                    _buildDropdownField(
                      'Submission Type',
                      ['Online', 'Offline', 'Both'],
                      _selectedSubmissionType,
                      (value) =>
                          setState(() => _selectedSubmissionType = value),
                      isDense: false,
                      hasLabel: true,
                      isTight: false,
                    ),
                  ],
                );
              } else {
                // Side-by-side (Row) layout for wider screens/desktop
                return Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        'Assignment Type',
                        [
                          'Homework',
                          'Project',
                          'Lab Report',
                          'Essay',
                          'Presentation',
                          'Quiz',
                        ],
                        _selectedType,
                        (value) => setState(() => _selectedType = value),
                        isDense: true,
                        hasLabel: false,
                        isTight: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdownField(
                        'Submission Type',
                        ['Online', 'Offline', 'Both'],
                        _selectedSubmissionType,
                        (value) =>
                            setState(() => _selectedSubmissionType = value),
                        isDense: true,
                        hasLabel: false,
                        isTight: true,
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          // 10. Priority (Full width with labelText)
          _buildDropdownField(
            'Priority',
            ['Low', 'Medium', 'High', 'Critical'],
            _selectedPriority,
            (value) => setState(() => _selectedPriority = value ?? 'Medium'),
          ),
          const SizedBox(height: 10),

          // Submit Button
          ElevatedButton(
            onPressed: _createAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF51cf66),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Create Assignment',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modal Implementations ---

  Widget _buildModalDetailItem(
    String label,
    String value, {
    bool isHeading = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isHeading ? 8.0 : 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHeading ? 16 : 12,
              color: isHeading ? Colors.deepPurple.shade700 : Colors.grey,
              fontWeight: isHeading ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: TextStyle(
              fontSize: isHeading ? 18 : 14,
              color: isHeading ? Colors.black87 : Colors.black54,
              fontWeight: isHeading ? FontWeight.normal : FontWeight.w500,
            ),
            softWrap: true,
          ),
          if (isHeading)
            const Divider(
              height: 15,
              thickness: 1,
              color: Colors.deepPurpleAccent,
            ),
        ],
      ),
    );
  }

  void _showViewAssignmentModal(Assignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          assignment.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildModalDetailItem(
                'Class/Section',
                '${assignment.className} (${assignment.section})',
                isHeading: true,
              ),
              _buildModalDetailItem('Subject', assignment.subject),
              _buildModalDetailItem(
                'Due Date',
                _dateFormatter.format(assignment.dueDate),
              ),
              _buildModalDetailItem('Max Marks', '${assignment.marks}'),
              _buildModalDetailItem('Weightage', '${assignment.weightage}%'),
              const Divider(height: 15, thickness: 1, color: Colors.black12),
              _buildModalDetailItem('Description', assignment.description),
              const Divider(height: 15, thickness: 1, color: Colors.black12),
              _buildModalDetailItem('Instructions', assignment.instructions),
              const Divider(height: 15, thickness: 1, color: Colors.black12),
              _buildModalDetailItem('Resources', assignment.resources),
              _buildModalDetailItem('Type', assignment.type),
              _buildModalDetailItem(
                'Submission Type',
                assignment.submissionType,
              ),
              _buildModalDetailItem('Priority', assignment.priority),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showEditAssignmentModal(Assignment assignment) {
    // Local state management for the edit form
    final editFormKey = GlobalKey<FormState>();
    String? editedTitle = assignment.title;
    String? editedSubject = assignment.subject;
    String? editedClass = assignment.className;
    String? editedSection = assignment.section;
    DateTime editedDueDate = assignment.dueDate;
    int? editedMarks = assignment.marks;
    int? editedWeightage = assignment.weightage;
    String? editedDescription = assignment.description;
    String? editedInstructions = assignment.instructions;
    String? editedResources = assignment.resources;
    String? editedType = assignment.type;
    String? editedSubmissionType = assignment.submissionType;
    String? editedPriority = assignment.priority;

    showDialog(
      context: context,
      builder: (ctx) {
        // State management for the dialog's dropdowns
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<String> currentSections = editedClass != null
                ? mockSections[editedClass] ?? const []
                : const [];

            return AlertDialog(
              title: const Text('Edit Assignment'),
              content: SizedBox(
                width:
                    MediaQuery.of(context).size.width * 0.8, // Make modal wider
                child: SingleChildScrollView(
                  child: Form(
                    key: editFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Title
                        TextFormField(
                          initialValue: editedTitle,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          onChanged: (value) => editedTitle = value,
                        ),
                        // Class
                        _buildDropdownField('Class', allClasses, editedClass, (
                          value,
                        ) {
                          setDialogState(() {
                            editedClass = value;
                            editedSection =
                                null; // Reset section on class change
                          });
                        }, hasLabel: true),
                        // Section
                        _buildDropdownField(
                          'Section',
                          currentSections,
                          editedSection,
                          (value) =>
                              setDialogState(() => editedSection = value),
                          hasLabel: true,
                        ),
                        // Subject
                        _buildDropdownField(
                          'Subject',
                          allSubjects,
                          editedSubject,
                          (value) =>
                              setDialogState(() => editedSubject = value),
                          hasLabel: true,
                        ),
                        // Due Date
                        _buildDatePickerField(
                          initialDate: editedDueDate,
                          onDateSelected: (newDate) =>
                              setDialogState(() => editedDueDate = newDate),
                          hasLabel: true,
                        ),
                        // Marks
                        TextFormField(
                          initialValue: editedMarks.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Max Marks',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              int.tryParse(value ?? '') == null
                              ? 'Must be a number'
                              : null,
                          onChanged: (value) {
                            setState(() {
                              editedMarks = int.tryParse(value) ?? 0;
                            });
                          },
                        ),
                        // Weightage
                        TextFormField(
                          initialValue: editedWeightage.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Weightage (%)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              int.tryParse(value ?? '') == null
                              ? 'Must be a number'
                              : null,
                          onChanged: (value) {
                            setState(() {
                              editedWeightage = int.tryParse(value) ?? 0;
                            });
                          },
                        ),
                        // Description
                        TextFormField(
                          initialValue: editedDescription,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 3,
                          onChanged: (value) => editedDescription = value,
                        ),
                        // Instructions
                        TextFormField(
                          initialValue: editedInstructions,
                          decoration: const InputDecoration(
                            labelText: 'Instructions',
                          ),
                          maxLines: 3,
                          onChanged: (value) => editedInstructions = value,
                        ),
                        // Resources
                        TextFormField(
                          initialValue: editedResources,
                          decoration: const InputDecoration(
                            labelText: 'Resources',
                          ),
                          maxLines: 2,
                          onChanged: (value) => editedResources = value,
                        ),
                        // Type
                        _buildDropdownField(
                          'Type',
                          [
                            'Homework',
                            'Project',
                            'Lab Report',
                            'Essay',
                            'Presentation',
                            'Quiz',
                          ],
                          editedType,
                          (value) => setDialogState(() => editedType = value),
                          hasLabel: true,
                        ),
                        // Submission Type
                        _buildDropdownField(
                          'Submission Type',
                          ['Online', 'Offline', 'Both'],
                          editedSubmissionType,
                          (value) => setDialogState(
                            () => editedSubmissionType = value,
                          ),
                          hasLabel: true,
                        ),
                        // Priority
                        _buildDropdownField(
                          'Priority',
                          ['Low', 'Medium', 'High', 'Critical'],
                          editedPriority,
                          (value) =>
                              setDialogState(() => editedPriority = value),
                          hasLabel: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (editFormKey.currentState!.validate() &&
                        editedSection != null) {
                      final updatedAssignment = assignment.copyWith(
                        title: editedTitle,
                        subject: editedSubject,
                        className: editedClass,
                        section: editedSection,
                        dueDate: editedDueDate,
                        marks: editedMarks,
                        weightage: editedWeightage,
                        description: editedDescription,
                        instructions: editedInstructions,
                        resources: editedResources,
                        type: editedType,
                        submissionType: editedSubmissionType,
                        priority: editedPriority,
                      );
                      _updateAssignment(updatedAssignment);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Final Build Method (for full code completeness) ---

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        // The background color of the Scaffold determines the background color outside the main scrollable area
        backgroundColor: Colors.white,
        appBar: AppBar(
        // --- START NEW APP BAR IMPLEMENTATION ---
        toolbarHeight: 70, // Slightly taller for the gradient effect
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Assignment Management',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        // Gradient background
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: const [],
        // --- END NEW APP BAR IMPLEMENTATION ---
      ),
      body: SingleChildScrollView(
        // Reduced horizontal padding to allow containers to stretch wider
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),

            _buildStatsRow(),
            const SizedBox(height: 30),

            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFormCard()),
                      const SizedBox(width: 30),
                      Expanded(child: _buildListCard()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 30),
                      _buildListCard(),
                    ],
                  ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  // **Helper Widget: Build Form Card**
  Widget _buildFormCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✏️ Create New Assignment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          _buildAssignmentForm(),
        ],
      ),
    );
  }

  // **Helper Widget: Build List Card**
  Widget _buildListCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Recent Assignments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        assignments.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No assignments found.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  return _buildAssignmentCard(assignments[index]);
                },
              ),
      ],
    );
  }

  // **STAT CARDS ROW**
  Widget _buildStatsRow() {
    int total = 0;
    int active = 0;
    int due = 0;
    int overdue = 0;
    int completed = 0;

    for (var a in assignments) {
      total++;
      if (a.isCompleted) {
        completed++;
      }
      // Pass the assignment object to getAssignmentStatus
      final status = getAssignmentStatus(a)['text'];
      if (status == 'Active') {
        active++;
      } else if (status == 'Due Soon') {
        due++;
      } else if (status == 'Overdue') {
        overdue++;
      }
    }

    // Correct total assignment counts by excluding completed assignments from status counts,
    // but the required logic here is slightly complex given the mock data structure.
    // For simplicity and matching previous functionality, we include all status categories.
    // The Completed count is accurate based on the mock setup.

    final List<Map<String, dynamic>> stats = [
      {
        'label': 'Total Assignments',
        'number': total,
        'color': Colors.deepPurple,
        'icon': Icons.assignment_outlined,
      },
      {
        'label': 'Completed',
        'number': completed,
        'color': Colors.blue,
        'icon': Icons.check_circle_outline,
      },
      {
        'label': 'Active',
        'number': active,
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      },
      {
        'label': 'Due Soon',
        'number': due,
        'color': Colors.amber,
        'icon': Icons.access_time,
      },
      {
        'label': 'Overdue',
        'number': overdue,
        'color': Colors.redAccent,
        'icon': Icons.warning_amber,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(stats.length, (index) {
          final stat = stats[index];

          Color contentColor = stat['color'] as Color;
          Color accentColor;
          IconData icon;

          if (stat['label'] == 'Total Assignments') {
            accentColor = const Color(0xFF9370DB);
            icon = Icons.assignment_outlined;
          } else if (stat['label'] == 'Completed') {
            accentColor = Colors.blue.shade300;
            contentColor = Colors.blue.shade700;
            icon = Icons.check_circle_outline;
          } else if (stat['label'] == 'Due Soon') {
            accentColor = const Color(0xFFFDD835);
            contentColor = Colors.amber.shade700;
            icon = Icons.access_time;
          } else if (stat['label'] == 'Overdue') {
            accentColor = Colors.red.shade300;
            contentColor = Colors.red.shade700;
            icon = Icons.warning_amber;
          } else {
            accentColor = Colors.green.shade300;
            contentColor = Colors.green.shade700;
            icon = stat['icon'] as IconData;
          }

          return Padding(
            padding: EdgeInsets.only(
              right: index < stats.length - 1 ? 15.0 : 0,
            ),
            child: SizedBox(
              width: 160,
              child: _buildStatCard(
                stat['label'].toString(),
                stat['number'].toString(),
                contentColor,
                accentColor,
                icon,
              ),
            ),
          );
        }),
      ),
    );
  }

  // **STAT CARD WIDGET**
  Widget _buildStatCard(
    String label,
    String value,
    Color contentColor,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      width: 160,
      height: 110,
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
                Icon(icon, color: contentColor, size: 24),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
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

  // **ASSIGNMENT CARD LIST ITEM**
  Widget _buildAssignmentCard(Assignment assignment) {
    // Pass the assignment object to getAssignmentStatus
    final status = getAssignmentStatus(assignment);
    final statusText = status['text'];
    final statusColor = status['color'] as Color;

    return Card(
      elevation: 2,
      // Reduced margin to make card fit tighter inside the _buildListCard padding
      margin: const EdgeInsets.only(bottom: 12, left: 0, right: 0),
      color: Colors.white, // Explicitly set background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        // Reduced internal padding to match desired close fit
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${assignment.subject} • ${assignment.className} (${assignment.section})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status text (unboxed)
                Text(
                  statusText.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.black12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildDetailItem(
                  'Due Date',
                  _dateFormatter.format(assignment.dueDate),
                ),
                _buildDetailItem(
                  'Marks',
                  '${assignment.marks} (${assignment.weightage}%)',
                ),
                _buildDetailItem('Type', assignment.type),
                _buildDetailItem('Submission', assignment.submissionType),
              ],
            ),
            const SizedBox(height: 10),
            _buildContentDetail('Description:', assignment.description),
            _buildContentDetail('Instructions:', assignment.instructions),
            _buildContentDetail(
              'Resources:',
              assignment.resources.isEmpty ? 'None' : assignment.resources,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final viewBtn = ElevatedButton(
                  onPressed: () => _showViewAssignmentModal(assignment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(color: Colors.white),
                  ),
                );
                final editBtn = ElevatedButton(
                  onPressed: () => _showEditAssignmentModal(assignment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.white),
                  ),
                );
                final delBtn = IconButton(
                  onPressed: () => _deleteAssignment(assignment.id),
                  icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                );

                if (constraints.maxWidth < 300) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: double.infinity, child: viewBtn),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: editBtn),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: delBtn),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: viewBtn),
                    const SizedBox(width: 8),
                    Expanded(child: editBtn),
                    const SizedBox(width: 8),
                    delBtn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return SizedBox(
      width: 150,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentDetail(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
