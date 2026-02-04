import 'package:flutter/material.dart';
import 'driver.dart';

class StudentDetails {
  final String id;
  final String name;
  final String motherName;
  final String fatherName;
  final String contact;
  final String studentClass;
  final String? photoUrl;

  StudentDetails({
    required this.id,
    required this.name,
    required this.motherName,
    required this.fatherName,
    required this.contact,
    required this.studentClass,
    this.photoUrl,
  });
}

class StudentDetailsCard extends StatelessWidget {
  final StudentDetails student;
  const StudentDetailsCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
            child: student.photoUrl == null ? Text(student.name.isNotEmpty ? student.name[0] : '?', style: const TextStyle(fontSize: 28)) : null,
          ),
          const SizedBox(height: 12),
          Text(student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _infoRow('Mother', student.motherName),
          _infoRow('Father', student.fatherName),
          _infoRow('Contact', student.contact),
          _infoRow('Class', student.studentClass),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class StudentDetailsView extends StatelessWidget {
  final Student student;

  const StudentDetailsView({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: student.id.isEven ? Colors.pink.shade100 : Colors.blue.shade100,
            child: Text(
              student.name.substring(0, 1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: student.id.isEven ? Colors.pink.shade800 : Colors.blue.shade800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            student.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Mother\'s Name:', 'Sarah Wilson'),
          _buildDetailRow('Father\'s Name:', 'James Wilson'),
          _buildDetailRow('Contact:', '+1 (555) 123-4567'),
          _buildDetailRow('Class:', '5th Grade - Section A'),
          _buildDetailRow('Bus Stop:', 'Stop #1 - Main Street'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}