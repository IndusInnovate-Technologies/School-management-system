import 'package:flutter/material.dart';
import 'student_details.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  // sample data - replace with real data source
  List<StudentDetails> get sampleStudents => [
        StudentDetails(
          id: 's1',
          name: 'Maya Patel',
          motherName: 'Kavita Patel',
          fatherName: 'Ramesh Patel',
          contact: '+1 555 0101',
          studentClass: 'Grade 3A',
          photoUrl: null,
        ),
        StudentDetails(
          id: 's2',
          name: 'Arjun Singh',
          motherName: 'Sunita Singh',
          fatherName: 'Rajesh Singh',
          contact: '+1 555 0202',
          studentClass: 'Grade 4B',
          photoUrl: null,
        ),
      ];

  void _showStudentDetails(BuildContext context, StudentDetails student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: StudentDetailsCard(student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = sampleStudents;
    return Scaffold(
      appBar: AppBar(title: const Text('Student Attendance')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: students.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final s = students[i];
          return ListTile(
            leading: GestureDetector(
              onTap: () => _showStudentDetails(context, s),
              child: CircleAvatar(
                radius: 26,
                backgroundImage: s.photoUrl != null ? NetworkImage(s.photoUrl!) : null,
                child: s.photoUrl == null ? Text(s.name.isNotEmpty ? s.name[0] : '?') : null,
              ),
            ),
            title: Text(s.name),
            subtitle: Text(s.studentClass),
            trailing: const Icon(Icons.more_vert),
            onTap: () {
              // tap row - maybe toggle attendance
            },
          );
        },
      ),
    );
  }
}