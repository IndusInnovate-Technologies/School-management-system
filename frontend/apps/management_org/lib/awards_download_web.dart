import 'package:flutter/material.dart';
import 'dart:html' as html;

/// Web-only implementation: trigger browser download via Blob and AnchorElement.
Future<void> downloadExcelFile(
  List<int> bytes,
  String filename,
  BuildContext context,
) async {
  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: downloadUrl)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(downloadUrl);
}
