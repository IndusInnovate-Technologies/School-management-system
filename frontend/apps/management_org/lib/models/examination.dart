import 'package:flutter/material.dart';

class Examination {
  final int id;
  final String title;
  final String type;
  final DateTime date;
  final TimeOfDay time;
  final String grade;
  final String subject;
  final int durationMinutes;
  final int maxMarks;
  final String description;
  final String location;
  final String status;
  final String section;

  Examination({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.time,
    required this.grade,
    required this.subject,
    required this.durationMinutes,
    required this.maxMarks,
    required this.description,
    required this.location,
    required this.status,
    this.section = 'ALL',
  });

  Examination copyWith({
    int? id,
    String? title,
    String? type,
    DateTime? date,
    TimeOfDay? time,
    String? grade,
    String? subject,
    int? durationMinutes,
    int? maxMarks,
    String? description,
    String? location,
    String? status,
    String? section,
  }) {
    return Examination(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      time: time ?? this.time,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxMarks: maxMarks ?? this.maxMarks,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      section: section ?? this.section,
    );
  }
}
