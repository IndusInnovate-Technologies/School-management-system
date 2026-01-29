import 'package:flutter/material.dart';

class AddExamSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final String? typeValue;
  final ValueChanged<String?> onTypeChanged;
  final DateTime? dateValue;
  final Future<void> Function() onPickDate;
  final TimeOfDay? timeValue;
  final Future<void> Function() onPickTime;
  final String? classValue;
  final ValueChanged<String?> onClassChanged;
  final String? sectionValue;
  final ValueChanged<String?> onSectionChanged;
  final TextEditingController subjectController;
  final TextEditingController durationController;
  final TextEditingController marksController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final Future<void> Function() onSubmit;
  final bool isSubmitting;
  final String title;
  final String buttonLabel;

  // Class options hardcoded here as they were used in the original file
  // Should ideally be passed in or shared
  static const List<DropdownMenuItem<String>> _classOptions = [
    DropdownMenuItem(value: 'class-1', child: Text('Class 1')),
    DropdownMenuItem(value: 'class-2', child: Text('Class 2')),
    DropdownMenuItem(value: 'class-3', child: Text('Class 3')),
    DropdownMenuItem(value: 'class-4', child: Text('Class 4')),
    DropdownMenuItem(value: 'class-5', child: Text('Class 5')),
    DropdownMenuItem(value: 'class-6', child: Text('Class 6')),
    DropdownMenuItem(value: 'class-7', child: Text('Class 7')),
    DropdownMenuItem(value: 'class-8', child: Text('Class 8')),
    DropdownMenuItem(value: 'class-9', child: Text('Class 9')),
    DropdownMenuItem(value: 'class-10', child: Text('Class 10')),
    DropdownMenuItem(value: 'class-11', child: Text('Class 11')),
    DropdownMenuItem(value: 'class-12', child: Text('Class 12')),
  ];

  const AddExamSection({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.typeValue,
    required this.onTypeChanged,
    required this.dateValue,
    required this.onPickDate,
    required this.timeValue,
    required this.onPickTime,
    required this.classValue,
    required this.onClassChanged,
    required this.sectionValue,
    required this.onSectionChanged,
    required this.subjectController,
    required this.durationController,
    required this.marksController,
    required this.descriptionController,
    required this.locationController,
    required this.onSubmit,
    required this.isSubmitting,
    this.title = '➕ Add New Examination',
    this.buttonLabel = 'Add Examination',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: titleController,
              label: 'Exam Title',
              hint: 'Enter exam title',
            ),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Exam Type',
                    value: typeValue,
                    onChanged: onTypeChanged,
                    items: const [
                      DropdownMenuItem(value: 'unit-test', child: Text('Unit Test')),
                      DropdownMenuItem(value: 'mid-term', child: Text('Mid Term')),
                      DropdownMenuItem(value: 'final', child: Text('Final Exam')),
                      DropdownMenuItem(value: 'practical', child: Text('Practical')),
                      DropdownMenuItem(value: 'project', child: Text('Project')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DatePickerField(
                    label: 'Exam Date',
                    value: dateValue,
                    onTap: onPickDate,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TimePickerField(
                    label: 'Exam Time',
                    value: timeValue,
                    onTap: onPickTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Class',
                    value: classValue,
                    onChanged: onClassChanged,
                    items: _classOptions,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Section',
                    value: sectionValue,
                    onChanged: onSectionChanged,
                    items: const [
                       DropdownMenuItem(value: 'ALL', child: Text('ALL')),
                       DropdownMenuItem(value: 'A', child: Text('A')),
                       DropdownMenuItem(value: 'B', child: Text('B')),
                       DropdownMenuItem(value: 'C', child: Text('C')),
                       DropdownMenuItem(value: 'D', child: Text('D')),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: subjectController,
                    label: 'Subject',
                    hint: 'Enter subject',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: durationController,
                    label: 'Duration (minutes)',
                    hint: '90',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: marksController,
                    label: 'Maximum Marks',
                    hint: '100',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: locationController,
                    label: 'Exam Location',
                    hint: 'Hall A / Room 101',
                  ),
                ),
              ],
            ),
            _buildTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Enter exam description and instructions',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.isEmpty ? 'This field is required' : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<DropdownMenuItem<String>> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select')),
          ...items,
        ],
        validator: (val) => val == null ? 'Required' : null,
        onChanged: onChanged,
      ),
    );
  }
}

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final Future<void> Function() onTap;

  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select date'
        : '${value!.day}/${value!.month}/${value!.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: value == null ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final Future<void> Function() onTap;

  const TimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        value == null ? 'Select time' : value!.format(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: const Icon(Icons.access_time),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: value == null ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
