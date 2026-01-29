import 'package:flutter/material.dart';

String formatTimeWith24h(BuildContext context, dynamic time) {
  if (time == null) return 'Not set';
  
  TimeOfDay? tod;
  if (time is TimeOfDay) {
    tod = time;
  } else if (time is String) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      tod = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
  }
  
  if (tod == null) return 'Invalid time';

  // Format 12h: HH:mm AM/PM
  final hourOfPeriod = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
  final minute = tod.minute.toString().padLeft(2, '0');
  final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
  final formatted12h = '${hourOfPeriod.toString().padLeft(2, '0')}:$minute $period';

  // Format 24h: HH:mm
  final hour24 = tod.hour.toString().padLeft(2, '0');
  final minute24 = tod.minute.toString().padLeft(2, '0');
  final formatted24h = '$hour24:$minute24';

  return '$formatted12h ($formatted24h)';
}

