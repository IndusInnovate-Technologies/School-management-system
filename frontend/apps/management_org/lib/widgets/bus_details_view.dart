import 'package:flutter/material.dart';
import '../models/bus_details_model.dart';
import '../utils.dart';

class BusDetailsView extends StatelessWidget {
  final BusDetails busDetails;

  const BusDetailsView({super.key, required this.busDetails});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildBusInfo(),
          const SizedBox(height: 20),
          _buildDriverInfo(),
          const SizedBox(height: 20),
          _buildRouteInfo(),
          const SizedBox(height: 20),
          _buildStopsSection('Morning Route (Pickup)', busDetails.morningStops),
          const SizedBox(height: 20),
          _buildStopsSection('Afternoon Route (Drop-off)', busDetails.afternoonStops),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Text('🚌', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busDetails.busNumber,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  busDetails.routeName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: busDetails.isActive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              busDetails.isActive ? 'Active' : 'Inactive',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusInfo() {
    return _buildInfoCard(
      'Bus Information',
      [
        _InfoRow('Bus Number', busDetails.busNumber),
        _InfoRow('Bus Type', busDetails.busType),
        _InfoRow('Registration', busDetails.registrationNumber),
        _InfoRow('Capacity', '${busDetails.totalStudents}/${busDetails.capacity}'),
        _InfoRow('Total Stops', '${busDetails.totalStops}'),
        _InfoRow('Total Students', '${busDetails.totalStudents}'),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return _buildInfoCard(
      'Driver Information',
      [
        _InfoRow('Name', busDetails.driverName),
        _InfoRow('Phone', busDetails.driverPhone),
        _InfoRow('License', busDetails.driverLicense),
        if (busDetails.driverExperience != null)
          _InfoRow('Experience', '${busDetails.driverExperience} years'),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return _buildInfoCard(
      'Route Information',
      [
        _InfoRow('Route Name', busDetails.routeName),
        if (busDetails.routeDistance != null)
          _InfoRow('Distance', '${busDetails.routeDistance} km'),
        _InfoRow('Morning Start', busDetails.morningStartTime),
        _InfoRow('Morning End', busDetails.morningEndTime),
        _InfoRow('Afternoon Start', busDetails.afternoonStartTime),
        _InfoRow('Afternoon End', busDetails.afternoonEndTime),
        if (busDetails.notes.isNotEmpty)
          _InfoRow('Notes', busDetails.notes),
      ],
    );
  }

  Widget _buildStopsSection(String title, List<StopDetails> stops) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (stops.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No stops added yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...stops.map((stop) => _buildStopCard(stop)),
        ],
      ),
    );
  }

  Widget _buildStopCard(StopDetails stop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${stop.stopOrder}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          stop.stopName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('Stop ID: ${stop.stopId}'),
            if (stop.stopAddress.isNotEmpty)
              Text('Address: ${stop.stopAddress}'),
            if (stop.stopTime != null)
              Text('Time: ${stop.stopTime}'),
            Text('Students: ${stop.students.length}'),
          ],
        ),
        children: [
          if (stop.students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No students assigned to this stop',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...stop.students.map((student) => _buildStudentTile(student)),
        ],
      ),
    );
  }

  Widget _buildStudentTile(StudentDetails student) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          student.studentName.isNotEmpty 
              ? student.studentName[0].toUpperCase() 
              : '?',
        ),
      ),
      title: Text(student.studentName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${student.studentId}'),
          Text('Class: ${student.studentClass} | Section: ${student.studentSection}'),
          if (student.pickupTime != null)
            Text('Pickup: ${student.pickupTime}'),
          if (student.dropoffTime != null)
            Text('Dropoff: ${student.dropoffTime}'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

