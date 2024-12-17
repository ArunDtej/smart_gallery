import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestPhotoPermissions() async {
    var photoPermission = Permission.photos;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        photoPermission = Permission.storage;
      } else {
        photoPermission = Permission.photos;
      }
    }

    if (await photoPermission.request().isGranted) {
      return true;
    }
    return false;
  }

 
  
}
