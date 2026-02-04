import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms (Android, iOS, etc.).
/// Template download via blob is only supported on web.
Future<void> downloadExcelFile(
  List<int> bytes,
  String filename,
  BuildContext context,
) async {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template download is available on the web app.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
