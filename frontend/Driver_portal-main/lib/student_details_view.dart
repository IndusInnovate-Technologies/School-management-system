import 'package:flutter/material.dart';
import 'driver.dart';

class StudentDetailsView extends StatelessWidget {
  final Student student;
  // optional: the bus stop the student was opened from
  final BusStop? busStop;

  const StudentDetailsView({super.key, required this.student, this.busStop});

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
          if (student.studentId != null && student.studentId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'ID: ${student.studentId}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 24),
          _buildDetailRow('Mother\'s Name:', student.motherName ?? '—'),
          _buildDetailRow('Father\'s Name:', student.fatherName ?? '—'),
          _buildDetailRow('Contact:', student.contact ?? '—'),
          _buildDetailRow('Class:', student.classSection ?? '—'),
          _buildDetailRow('Bus Stop:', busStop != null ? 'Stop ${busStop!.id + 1} - ${busStop!.address.isNotEmpty ? busStop!.address : busStop!.name}' : '—'),
          _buildDetailRow('Pickup Time:', student.pickupTime ?? '—'),
          _buildDetailRow('Drop Off Time:', student.dropoffTime ?? '—'),
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