// Used on mobile/desktop: Android emulator needs 10.0.2.2 to reach host
import 'dart:io' show Platform;

String getApiHost() {
  if (Platform.isAndroid) {
    return '10.0.2.2'; // Android emulator alias for host loopback
  }
  return 'localhost';
}
