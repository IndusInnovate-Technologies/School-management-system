// lib/main.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
// Removed `file_picker` dependency for emulator/demo builds.
// We provide a small local stub `_PickedFile` and a simulated picker.

void main() {
  runApp(const StudyMaterialsApp());
}

/// Simple local representation of a picked file for demo/emulator builds.
class _PickedFile {
  final String name;
  final int size; // bytes
  _PickedFile({required this.name, required this.size});
}

class StudyMaterialsApp extends StatelessWidget {
  const StudyMaterialsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Materials Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: createMaterialColor(const Color(0xFF667EEA)),
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DashboardScreen(),
    );
  }
}

/// A utility to create a MaterialColor from a single color (used for theme).
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05];
  final Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;
  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

/// Model for a material item
class MaterialItem {
  int id;
  String title;
  String subject;
  String className;
  String type;
  String description;
  double sizeMB;
  DateTime date;
  List<String> tags;
  String fileName;

  MaterialItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.type,
    required this.description,
    required this.sizeMB,
    required this.date,
    required this.tags,
    required this.fileName,
  });
}

/// Dashboard screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data
  final List<MaterialItem> _materials = [
    MaterialItem(
      id: 1,
      title: "Calculus Fundamentals",
      subject: "mathematics",
      className: "class-12",
      type: "notes",
      description:
          "Comprehensive notes on calculus fundamentals including limits, derivatives, and integrals.",
      sizeMB: 2.5,
      date: DateTime(2024, 1, 15),
      tags: ["calculus", "advanced", "notes"],
      fileName: "calculus_fundamentals.pdf",
    ),
    MaterialItem(
      id: 2,
      title: "Physics Lab Report Template",
      subject: "science",
      className: "class-11",
      type: "worksheet",
      description:
          "Standard template for physics laboratory reports with guidelines and formatting.",
      sizeMB: 1.8,
      date: DateTime(2024, 1, 12),
      tags: ["lab", "template", "physics"],
      fileName: "physics_lab_template.docx",
    ),
    MaterialItem(
      id: 3,
      title: "English Literature Analysis",
      subject: "english",
      className: "class-10",
      type: "assignment",
      description:
          "Assignment guidelines for analyzing classic English literature texts.",
      sizeMB: 3.2,
      date: DateTime(2024, 1, 10),
      tags: ["literature", "analysis", "assignment"],
      fileName: "english_literature_analysis.pdf",
    ),
    MaterialItem(
      id: 4,
      title: "Chemistry Periodic Table",
      subject: "science",
      className: "class-11",
      type: "presentation",
      description: "Interactive presentation on the periodic table.",
      sizeMB: 5.1,
      date: DateTime(2024, 1, 8),
      tags: ["chemistry", "periodic", "presentation"],
      fileName: "chemistry_periodic_table.pptx",
    ),
    MaterialItem(
      id: 5,
      title: "History Timeline",
      subject: "history",
      className: "class-10",
      type: "notes",
      description:
          "Comprehensive timeline of major historical events for exam preparation.",
      sizeMB: 4.7,
      date: DateTime(2024, 1, 5),
      tags: ["history", "timeline", "exam"],
      fileName: "history_timeline.pdf",
    ),
  ];

  // UI state
  String filterSubject = '';
  String filterClass = '';
  String filterType = '';
  DateTime? filterDate;
  String filterDateStr = '';
  String sortBy = 'date';

  // Upload form controllers
  final _titleController = TextEditingController();
  String selectedSubject = '';
  String selectedClass = '';
  String selectedType = '';
  String selectedBoard = '';
  final _tagsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // file picker results
  // For demo builds without native plugins, use a simple local file stub.
  // When integrating a real picker plugin, restore PlatformFile or XFile usage.
  List<_PickedFile> pickedFiles = [];

  // upload simulation
  double uploadProgress = 0.0;
  bool isUploading = false;

  // id generator
  int _nextId = 6;

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<MaterialItem> get filteredAndSortedMaterials {
    List<MaterialItem> list = _materials.where((m) {
      final subjectMatch =
          filterSubject.isEmpty || m.subject == filterSubject.toLowerCase();
      final classMatch =
          filterClass.isEmpty || m.className == filterClass.toLowerCase();
      final typeMatch =
          filterType.isEmpty || m.type == filterType.toLowerCase();
      return subjectMatch && classMatch && typeMatch;
    }).toList();

    switch (sortBy) {
      case 'name':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'size':
        list.sort((a, b) => a.sizeMB.compareTo(b.sizeMB));
        break;
      case 'type':
        list.sort((a, b) => a.type.compareTo(b.type));
        break;
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }

    return list;
  }

  // pick files using file_picker
  Future<void> pickFiles() async {
    // In the emulator/demo we don't use native file pickers. Show a small
    // dialog to simulate selecting a file. For real builds, replace this
    // implementation with a plugin call (e.g. file_picker or file_selector).
    final chosen = await showDialog<_PickedFile?>(
      context: context,
      builder: (context) => AlertDialog(
          title: const Text('Simulate File Pick'),
        content: const Text('This demo simulates picking a sample PDF file.'),
        actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_PickedFile(name: 'sample.pdf', size: 1024 * 500)),
              child: const Text('Pick Sample'),
            ),
        ],
      ),
    );

    if (chosen != null) {
      setState(() {
        pickedFiles = [chosen];
      });
    }
  }

  void resetForm() {
    _titleController.clear();
    selectedSubject = '';
    selectedClass = '';
    selectedType = '';
    selectedBoard = '';
    _tagsController.clear();
    _descriptionController.clear();
    pickedFiles = [];
    setState(() {});
  }

  Future<void> uploadMaterial() async {
    // validation
    if (_titleController.text.trim().isEmpty ||
        selectedSubject.isEmpty ||
        selectedClass.isEmpty ||
        selectedType.isEmpty ||
        pickedFiles.isEmpty) {
      _showSnack('Please fill required fields and select at least one file.');
      return;
    }

    // start simulated upload
    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    // simulate progress
    final random = Random();
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      setState(() {
        uploadProgress += 0.05 + random.nextDouble() * 0.15;
        if (uploadProgress >= 1.0) {
          uploadProgress = 1.0;
        }
      });

      if (uploadProgress >= 1.0) {
        timer.cancel();
        // create MaterialItem(s) from pickedFiles (if multiple, create multiple entries OR combine)
        for (var pf in pickedFiles) {
          final sizeMB = pf.size / (1024 * 1024);
          final item = MaterialItem(
            id: _nextId++,
            title: _titleController.text.trim(),
            subject: selectedSubject,
            className: selectedClass,
            type: selectedType,
            description: _descriptionController.text.trim(),
            sizeMB: double.parse((sizeMB).toStringAsFixed(2)),
            date: DateTime.now(),
            tags: _tagsController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            fileName: pf.name,
          );
          _materials.insert(0, item);
        }

        // reset UI after short delay
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() {
            isUploading = false;
            uploadProgress = 0.0;
            resetForm();
          });
          _showSnack('Material(s) uploaded successfully!');
        });
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _deleteMaterial(int id) {
    final idx = _materials.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      final title = _materials[idx].title;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Material'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _materials.removeWhere((m) => m.id == id);
                    });
                    _showSnack('Material deleted');
                  },
                  child: const Text('Delete'),
                ),
          ],
        ),
      );
    }
  }

  void _editMaterial(int id) {
    final item = _materials.firstWhere(
      (m) => m.id == id,
      orElse: () => throw 'not found',
    );
    // For Option A single-file demo we will just show a dialog and allow changing title/description
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final idx = _materials.indexWhere((m) => m.id == id);
                  if (idx >= 0) {
                    setState(() {
                      _materials[idx].title = titleCtrl.text.trim();
                      _materials[idx].description = descCtrl.text.trim();
                    });
                    Navigator.of(context).pop();
                    _showSnack('Material updated');
                  }
                },
                child: const Text('Save'),
              ),
        ],
      ),
    );
  }

  void _downloadMaterial(MaterialItem item) {
    // In a demo app we just show a notification. Real behavior would call a backend or use platform APIs.
    _showSnack('Downloading ${item.fileName} ...');
  }

  // small helper to format date
  String fmtDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  // compute summary metrics
  int get totalMaterialsCount => _materials.length;
  double get totalSizeMB => _materials.fold(0.0, (p, e) => p + e.sizeMB);
  int get activeClasses => _materials.map((m) => m.className).toSet().length;
  int get thisMonthCount {
    final now = DateTime.now();
    return _materials
        .where((m) => m.date.year == now.year && m.date.month == now.month)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: change layout based on width
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E6BFF), Color(0xFF7A4BE6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Teacher',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // refresh behaviour: simple reorder and notify
                      setState(() {
                        _materials.shuffle();
                      });
                      _showSnack('Materials refreshed');
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isNarrow = width < 900;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Page header
                      const SizedBox(height: 18),
                      Text(
                        'Study Materials Management',
                        style: TextStyle(
                          fontSize: isNarrow ? 26 : 34,
                          fontWeight: FontWeight.w800,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Upload and organize study materials for your classes',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),

                      // Stats slider - horizontal row of 4 cards (slideable)
                      SizedBox(
                        height: 110,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final widgets = [
                                _buildStatCard(
                                  '📚',
                                  totalMaterialsCount.toString(),
                                  'Total Materials',
                                ),
                                _buildStatCard(
                                  '📁',
                                  totalSizeMB.toStringAsFixed(1),
                                  'Total Size (MB)',
                                ),
                                _buildStatCard(
                                  '👥',
                                  activeClasses.toString(),
                                  'Active Classes',
                                ),
                                _buildStatCard(
                                  '📅',
                                  thisMonthCount.toString(),
                                  'This Month',
                                ),
                              ];
                              // reduced card width to fit more on screen
                              return SizedBox(
                                width: 160,
                                child: widgets[index],
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemCount: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upload section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 12),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '📤',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Upload New Material',
                                  style: TextStyle(
                                    fontSize: isNarrow ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                // optional action buttons could go here
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Upload form fields - stack line-by-line for clarity
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFormField(
                                  'Title',
                                  TextField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildFormField(
                                  'Subject',
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedSubject.isEmpty
                                        ? null
                                        : selectedSubject,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'mathematics',
                                        child: Text('Mathematics'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'science',
                                        child: Text('Science'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'english',
                                        child: Text('English'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'history',
                                        child: Text('History'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'geography',
                                        child: Text('Geography'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'physics',
                                        child: Text('Physics'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'chemistry',
                                        child: Text('Chemistry'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'biology',
                                        child: Text('Biology'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        selectedSubject = v ?? '';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildFormField(
                                  'Class',
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedClass.isEmpty
                                        ? null
                                        : selectedClass,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'class-10',
                                        child: Text('Class 10'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'class-11',
                                        child: Text('Class 11'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'class-12',
                                        child: Text('Class 12'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        selectedClass = v ?? '';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildFormField(
                                  'Type',
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedType.isEmpty
                                        ? null
                                        : selectedType,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'notes',
                                        child: Text('Notes'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'assignment',
                                        child: Text('Assignment'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'worksheet',
                                        child: Text('Worksheet'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'presentation',
                                        child: Text('Presentation'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'video',
                                        child: Text('Video'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'audio',
                                        child: Text('Audio'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'other',
                                        child: Text('Other'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        selectedType = v ?? '';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildFormField(
                                  'Board',
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedBoard.isEmpty
                                        ? null
                                        : selectedBoard,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'cbse',
                                        child: Text('CBSE'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'icse',
                                        child: Text('ICSE'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'state',
                                        child: Text('State Board'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'international',
                                        child: Text('International'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        selectedBoard = v ?? '';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildFormField(
                                  'Tags (comma separated)',
                                  TextField(
                                    controller: _tagsController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              'Description',
                              TextField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // File upload area
                            GestureDetector(
                              onTap: pickFiles,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.04),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 18,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder, size: 32),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pickedFiles.isEmpty
                                                ? 'Click to upload or drag and drop files here'
                                                : 'Selected: ${pickedFiles.map((e) => e.name).join(", ")}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Supports PDF, DOC, PPT, Images, Videos (Max 50MB)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: pickFiles,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Choose Files'),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // upload progress
                            if (isUploading)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: uploadProgress,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(uploadProgress * 100).round()}% uploading...',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: isUploading
                                      ? null
                                      : uploadMaterial,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Upload Material'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: resetForm,
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Materials list section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 12),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '📚',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Study Materials',
                                  style: TextStyle(
                                    fontSize: isNarrow ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Filters stacked line-by-line: Subject, Class, Type, Date
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFormField(
                                  'Subject',
                                  DropdownButtonFormField<String>(
                                    initialValue: filterSubject.isEmpty
                                        ? null
                                        : filterSubject,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'mathematics',
                                        child: Text('Mathematics'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'science',
                                        child: Text('Science'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'english',
                                        child: Text('English'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'history',
                                        child: Text('History'),
                                      ),
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text('All Subjects'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        filterSubject = v ?? '';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildFormField(
                                  'Class',
                                  DropdownButtonFormField<String>(
                                    initialValue: filterClass.isEmpty
                                        ? null
                                        : filterClass,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'class-10',
                                        child: Text('Class 10'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'class-11',
                                        child: Text('Class 11'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'class-12',
                                        child: Text('Class 12'),
                                      ),
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text('All Classes'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        filterClass = v ?? '';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildFormField(
                                  'Type',
                                  DropdownButtonFormField<String>(
                                    initialValue: filterType.isEmpty
                                        ? null
                                        : filterType,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'notes',
                                        child: Text('Notes'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'assignment',
                                        child: Text('Assignment'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'worksheet',
                                        child: Text('Worksheet'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'presentation',
                                        child: Text('Presentation'),
                                      ),
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text('All Types'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        filterType = v ?? '';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildFormField(
                                  'Date',
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            filterDate ?? DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          filterDate = picked;
                                          filterDateStr =
                                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                        });
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          hintText: filterDateStr.isEmpty
                                              ? 'Select date'
                                              : filterDateStr,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                filterDate = null;
                                                filterDateStr = '';
                                              });
                                            },
                                            icon: const Icon(Icons.clear),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Materials grid/list
                            Builder(
                              builder: (context) {
                                final items = filteredAndSortedMaterials;
                                if (items.isEmpty) {
                                  return SizedBox(
                                    height: 160,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            '📚',
                                            style: TextStyle(
                                              fontSize: 46,
                                              color: Colors.black26,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'No materials found matching your criteria',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // grid crossAxisCount depends on width; increase card height for saved books view
                                int crossCount = 1;
                                if (width > 1200) {
                                  crossCount = 3;
                                } else if (width > 800)
                                  crossCount = 2;
                                else
                                  crossCount = 1;

                                // adjust childAspectRatio (width/height). larger ratio => shorter cards.
                                double childAspect = crossCount == 1
                                    ? 1.2
                                    : 1.4;
                                // if there are many items (e.g., 5+), make cards shorter (increase ratio)
                                if (items.length >= 5) {
                                  childAspect = crossCount == 1 ? 1.6 : 1.8;
                                }

                                return GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossCount,
                                        childAspectRatio: childAspect,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: items.length,
                                  itemBuilder: (context, idx) {
                                    final m = items[idx];
                                    return MaterialCard(
                                      item: m,
                                      onDownload: () => _downloadMaterial(m),
                                      onEdit: () => _editMaterial(m.id),
                                      onDelete: () => _deleteMaterial(m.id),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String icon, String number, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        // show a colored stroke only at the top edge to match app bar style
        border: const Border(
          top: BorderSide(color: Color(0xFF8E6BFF), width: 3.0),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Widget for individual material card
class MaterialCard extends StatelessWidget {
  final MaterialItem item;
  final VoidCallback onDownload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MaterialCard({
    super.key,
    required this.item,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
  });

  String fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header (stacked)
          Text(
            item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "${capitalize(item.subject)} • ${item.className.replaceAll('class-', 'Class ')}",
            style: const TextStyle(
              color: Color(0xFF667EEA),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // action buttons aligned to right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined, color: Colors.green),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF667EEA)),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            item.description,
            style: const TextStyle(color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.insert_drive_file, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "${item.sizeMB.toStringAsFixed(1)} MB",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    fmtDate(item.date),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.tags.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
