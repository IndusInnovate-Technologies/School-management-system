class BusDetails {
  final String busNumber;
  final String schoolId;
  final String schoolName;
  final String busType;
  final int capacity;
  final String registrationNumber;
  final String driverName;
  final String driverPhone;
  final String driverLicense;
  final int? driverExperience;
  final String routeName;
  final double? routeDistance;
  final String startLocation;
  final String endLocation;
  final String morningStartTime;
  final String morningEndTime;
  final String afternoonStartTime;
  final String afternoonEndTime;
  final String notes;
  final bool isActive;
  final List<StopDetails> morningStops;
  final List<StopDetails> afternoonStops;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusDetails({
    required this.busNumber,
    required this.schoolId,
    required this.schoolName,
    required this.busType,
    required this.capacity,
    required this.registrationNumber,
    required this.driverName,
    required this.driverPhone,
    required this.driverLicense,
    this.driverExperience,
    required this.routeName,
    this.routeDistance,
    required this.startLocation,
    required this.endLocation,
    required this.morningStartTime,
    required this.morningEndTime,
    required this.afternoonStartTime,
    required this.afternoonEndTime,
    required this.notes,
    required this.isActive,
    required this.morningStops,
    required this.afternoonStops,
    this.createdAt,
    this.updatedAt,
  });

  factory BusDetails.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values from JSON
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed;
      }
      return null;
    }
    
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed;
      }
      return null;
    }
    
    return BusDetails(
      busNumber: json['bus_number']?.toString() ?? '',
      schoolId: json['school_id']?.toString() ?? '',
      schoolName: json['school_name']?.toString() ?? '',
      busType: json['bus_type']?.toString() ?? '',
      capacity: parseInt(json['capacity']) ?? 0,
      registrationNumber: json['registration_number']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      driverPhone: json['driver_phone']?.toString() ?? '',
      driverLicense: json['driver_license']?.toString() ?? '',
      driverExperience: parseInt(json['driver_experience']),
      routeName: json['route_name']?.toString() ?? '',
      routeDistance: parseDouble(json['route_distance']),
      startLocation: json['start_location']?.toString() ?? '',
      endLocation: json['end_location']?.toString() ?? '',
      morningStartTime: json['morning_start_time']?.toString() ?? '',
      morningEndTime: json['morning_end_time']?.toString() ?? '',
      afternoonStartTime: json['afternoon_start_time']?.toString() ?? '',
      afternoonEndTime: json['afternoon_end_time']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      isActive: json['is_active'] ?? false,
      morningStops: (json['morning_stops'] as List?)
          ?.map((stop) => StopDetails.fromJson(stop, json['bus_number']?.toString() ?? ''))
          .toList() ?? [],
      afternoonStops: (json['afternoon_stops'] as List?)
          ?.map((stop) => StopDetails.fromJson(stop, json['bus_number']?.toString() ?? ''))
          .toList() ?? [],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }

  int get totalStops => morningStops.length; // Only count morning stops (afternoon stops have same number but different locations)
  
  int get totalStudents {
    // Only count morning students since afternoon stops show the same students (matched by stop name)
    // Counting both would result in double counting
    return morningStops.fold(0, (sum, stop) => sum + stop.students.length);
  }
}

class StopDetails {
  final String stopId; // Already in format: busnumber_routeprefix_stopnumber
  final String busNumber;
  final String stopName;
  final String stopAddress;
  final String? stopTime;
  final String routeType;
  final int stopOrder;
  final double? latitude;
  final double? longitude;
  final List<StudentDetails> students;
  final int studentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StopDetails({
    required this.stopId,
    required this.busNumber,
    required this.stopName,
    required this.stopAddress,
    this.stopTime,
    required this.routeType,
    required this.stopOrder,
    this.latitude,
    this.longitude,
    required this.students,
    required this.studentCount,
    this.createdAt,
    this.updatedAt,
  });

  factory StopDetails.fromJson(Map<String, dynamic> json, String busNumber) {
    // Helper function to safely parse numeric values from JSON
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed;
      }
      return null;
    }
    
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed;
      }
      return null;
    }
    
    // stop_id is now already in format: busnumber_routeprefix_stopnumber
    final stopId = json['stop_id']?.toString() ?? '';
    
    return StopDetails(
      stopId: stopId,
      busNumber: busNumber,
      stopName: json['stop_name']?.toString() ?? '',
      stopAddress: json['stop_address']?.toString() ?? '',
      stopTime: json['stop_time']?.toString(),
      routeType: json['route_type']?.toString() ?? '',
      stopOrder: parseInt(json['stop_order']) ?? 0,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      students: (json['students'] as List?)
          ?.map((student) => StudentDetails.fromJson(student))
          .toList() ?? [],
      studentCount: parseInt(json['student_count']) ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }
}

class StudentDetails {
  final String id;
  final String studentId;
  final String studentName;
  final String studentClass;
  final String studentSection;
  final String? pickupTime;
  final String? dropoffTime;
  final String busStopName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentDetails({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
    required this.studentSection,
    this.pickupTime,
    this.dropoffTime,
    required this.busStopName,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) {
    return StudentDetails(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id_string']?.toString() ?? json['student']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      studentClass: json['student_class']?.toString() ?? '',
      studentSection: json['student_section']?.toString() ?? '',
      pickupTime: json['pickup_time']?.toString(),
      dropoffTime: json['dropoff_time']?.toString(),
      busStopName: json['bus_stop_name']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }
}

