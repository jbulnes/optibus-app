import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getUniqueId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // ID de hardware único en Android
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? 'unknown_ios_id'; 
  }
  
  return 'unknown_device';
}