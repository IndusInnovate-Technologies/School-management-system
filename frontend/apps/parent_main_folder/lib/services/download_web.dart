import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Future<void> performDownload(String url, String fileName) async {
  debugPrint('Attempting web download for: $url');
  try {
    // 1. Fetch bytes using Dio
    final dio = Dio();
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null) throw 'No data received';

    // 2. Create Blob and Object URL
    final blob = html.Blob([response.data]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    // 3. Create, style, and click anchor
    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute("download", fileName)
      ..style.display = 'none';
      
    html.document.body?.append(anchor);
    anchor.click();
    
    // 4. Cleanup
    anchor.remove();
    html.Url.revokeObjectUrl(blobUrl);
    debugPrint('Web download triggered successfully');
  } catch (e) {
    debugPrint('Web download error: $e. Falling back to window.open');
    // Final fallback: open in new tab
    html.window.open(url, "_blank");
  }
}

