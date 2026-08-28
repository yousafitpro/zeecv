import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestStoragePermission() async {
    // Android 10+ does not need the old storage permission
    if (Platform.isAndroid) {
      return true;
    }

    return true;
  }

  static Future<bool> hasStoragePermission() async {
    return true;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}