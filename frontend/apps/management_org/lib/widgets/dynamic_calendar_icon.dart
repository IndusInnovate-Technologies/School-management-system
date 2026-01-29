import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DynamicCalendarIcon extends StatelessWidget {
  const DynamicCalendarIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = now.day.toString();
    // Using MMM (e.g., JAN, FEB) for consistent 3-letter month fit
    final month = DateFormat('MMM').format(now).toUpperCase();

    return Container(
      width: 44, 
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // Month Header (Red background)
            Container(
              width: double.infinity,
              height: 14, 
              color: const Color(0xFFE53935), 
              alignment: Alignment.center,
              child: Text(
                month,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Day Body
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.0, 
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
