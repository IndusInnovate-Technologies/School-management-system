import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

Future<void> performDownload(String url, String fileName) async {
  try {
    final dio = Dio();
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    
    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(response.data),
      quality: 100,
      name: fileName,
    );
    
    if (result['isSuccess'] == true) {
      // Success
    } else {
      throw 'Failed to save image';
    }
  } catch (e) {
    rethrow;
  }
}

