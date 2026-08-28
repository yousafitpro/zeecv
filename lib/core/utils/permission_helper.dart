import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class PermissionHelper {
  static Future<bool> requestStoragePermission() async {
    // Android 10 (API 29) and above:
    // No old storage permission is required for this approach.
    if (Platform.isAndroid) {
      return true;
    }

    return true;
  }

  static Future<bool> hasStoragePermission() async {
    return true;
  }

  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Public Android Downloads folder
      return Directory('/storage/emulated/0/Download');
    }

    // iOS fallback
    return await getApplicationDocumentsDirectory();
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}