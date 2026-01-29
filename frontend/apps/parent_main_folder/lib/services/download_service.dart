import 'download_mobile.dart' if (dart.library.html) 'download_web.dart';

class DownloadService {
  static Future<void> downloadCertificate(String url, String fileName) async {
    await performDownload(url, fileName);
  }
}

