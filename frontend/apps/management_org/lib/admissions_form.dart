import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'admissions.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class AdmissionForm extends StatefulWidget {
  final Admission? initialData;
  final bool isSubmitting;
  final String submitLabel;
  final Function(Map<String, dynamic> data, Uint8List? photoBytes) onSubmit;

  const AdmissionForm({
    super.key,
    this.initialData,
    required this.isSubmitting,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<AdmissionForm> createState() => _AdmissionFormState();
}

class _AdmissionFormState extends State<AdmissionForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _studentNameController;
  late TextEditingController _parentNameController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _applyingClassController;
  
  DateTime? _dateOfBirth;
  String? _gender;
  String? _category;
  Uint8List? _selectedImageBytes;
  
  @override
  void initState() {
    super.initState();
    _studentNameController = TextEditingController(text: widget.initialData?.studentName ?? '');
    _parentNameController = TextEditingController(text: widget.initialData?.parentName ?? '');
    _addressController = TextEditingController(text: widget.initialData?.address ?? '');
    _emailController = TextEditingController(text: widget.initialData?.email ?? '');
    _parentPhoneController = TextEditingController(text: widget.initialData?.parentPhone ?? '');
    _applyingClassController = TextEditingController(text: widget.initialData?.applyingClass ?? '');
    
    _dateOfBirth = widget.initialData?.dateOfBirth;
    _gender = widget.initialData?.gender;
    _category = widget.initialData?.category;
  }
  
  @override
  void dispose() {
    _studentNameController.dispose();
    _parentNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _parentPhoneController.dispose();
    _applyingClassController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Date of Birth')),
        );
        return;
      }
      
      final data = {
        'student_name': _studentNameController.text,
        'parent_name': _parentNameController.text,
        'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        'gender': _gender ?? 'Male',
        'applying_class': _applyingClassController.text,
        'address': _addressController.text,
        'category': _category ?? 'General',
        'email': _emailController.text,
        'parent_phone': _parentPhoneController.text,
      };
      
      widget.onSubmit(data, _selectedImageBytes);
    }
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _selectedImageBytes != null 
                  ? MemoryImage(_selectedImageBytes!) 
                  : (widget.initialData?.profilePhotoUrl != null 
                      ? NetworkImage(widget.initialData!.profilePhotoUrl!) as ImageProvider
                      : null),
                child: (_selectedImageBytes == null && widget.initialData?.profilePhotoUrl == null)
                    ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _studentNameController,
            decoration: const InputDecoration(labelText: 'Student Name *', border: OutlineInputBorder()),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          
          TextFormField(
            controller: _parentNameController,
            decoration: const InputDecoration(labelText: 'Parent Name *', border: OutlineInputBorder()),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          
          ListTile(
            title: Text(_dateOfBirth == null ? 'Date of Birth *' : 'DOB: ${DateFormat('yyyy-MM-dd').format(_dateOfBirth!)}'),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _dateOfBirth = date);
            },
          ),
          const SizedBox(height: 15),
          
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(labelText: 'Gender *', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _gender = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          
          TextFormField(
            controller: _applyingClassController,
            decoration: const InputDecoration(labelText: 'Applying Class *', border: OutlineInputBorder()),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()),
            maxLines: 3,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 15),
          
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'General', child: Text('General')),
              DropdownMenuItem(value: 'OBC', child: Text('OBC')),
              DropdownMenuItem(value: 'SC', child: Text('SC')),
              DropdownMenuItem(value: 'ST', child: Text('ST')),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 15),
          
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),
          
          TextFormField(
            controller: _parentPhoneController,
            decoration: const InputDecoration(labelText: 'Parent Phone', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 25),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isSubmitting ? null : _handleSubmit,
              child: widget.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}
