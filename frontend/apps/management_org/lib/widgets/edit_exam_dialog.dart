import 'package:flutter/material.dart';
import '../models/examination.dart';
import 'add_exam_section.dart';

class EditExamDialog extends StatefulWidget {
  final Examination exam;
  final Function(int, Map<String, dynamic>) onUpdate;

  const EditExamDialog({required this.exam, required this.onUpdate});

  @override
  State<EditExamDialog> createState() => _EditExamDialogState();
}

class _EditExamDialogState extends State<EditExamDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _durationController;
  late TextEditingController _marksController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  
  String? _type;
  String? _class;
  String? _section;
  DateTime? _date;
  TimeOfDay? _time;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _titleController = TextEditingController(text: e.title);
    _subjectController = TextEditingController(text: e.subject);
    _durationController = TextEditingController(text: e.durationMinutes.toString());
    _marksController = TextEditingController(text: e.maxMarks.toString());
    _descriptionController = TextEditingController(text: e.description);
    _locationController = TextEditingController(text: e.location);
    
    _type = e.type;
    _class = e.grade; // e.g., 'class-1'
    _section = e.section;
    _date = e.date;
    _time = e.time;
  }
  
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _time = time);
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _class == null || _date == null || _time == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      // Reconstruct exam object to reuse _examinationToJson logic if accessible, 
      // OR manually map it here. Since _examinationToJson is private to the other state, we manually map.
      final examDateTime = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute
      );
      
      final data = {
        'Exam_Title': _titleController.text.trim(),
        'Exam_Type': _type,
        'Exam_Date': examDateTime.toIso8601String(),
        'Exam_Time': '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}:00',
        'Exam_Subject': _subjectController.text.trim(),
        'Exam_Class': _class,
        'Exam_Section': _section ?? 'ALL',
        'Exam_Duration': int.parse(_durationController.text.trim()),
        'Exam_Marks': int.parse(_marksController.text.trim()),
        'Exam_Description': _descriptionController.text.trim(),
        'Exam_Location': _locationController.text.trim(),
        'Exam_Status': widget.exam.status, // Preserve status
      };

      await widget.onUpdate(widget.exam.id, data);
      
      if (mounted) Navigator.pop(context, true); // Return true on success
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SizedBox(
        width: 600,
        height: 700, // Fixed height or flexible
          child: SingleChildScrollView(
            child: AddExamSection(
              title: '✏️ Edit Examination',
              buttonLabel: 'Update Examination',
              formKey: _formKey,
              titleController: _titleController,
              typeValue: _type,
              onTypeChanged: (v) => setState(() => _type = v),
              dateValue: _date,
              onPickDate: _pickDate,
              timeValue: _time,
              onPickTime: _pickTime,
              classValue: _class,
              onClassChanged: (v) => setState(() => _class = v),
              sectionValue: _section,
              onSectionChanged: (v) => setState(() => _section = v),
              subjectController: _subjectController,
              durationController: _durationController,
              marksController: _marksController,
              descriptionController: _descriptionController,
              locationController: _locationController,
              onSubmit: _onSubmit,
              isSubmitting: _isSubmitting,
            ),
          ),
      ),
    );
  }
}
