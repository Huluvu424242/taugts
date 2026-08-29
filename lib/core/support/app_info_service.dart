import 'package:flutter/services.dart';
import 'package:taugts/core/support/app_info.dart';

abstract interface class AppInfoGateway {
  Future<AppInfo> laden();
}

class AppInfoService implements AppInfoGateway {
  static const _kanal = MethodChannel('taugts/app_info');

  @override
  Future<AppInfo> laden() async {
    final daten = await _kanal.invokeMapMethod<String, dynamic>('getAppInfo');
    final version = daten?['version']?.toString().trim() ?? '';
    final buildNumber = daten?['buildNumber']?.toString().trim() ?? '';
    if (version.isEmpty) {
      throw const FormatException('Die installierte App-Version fehlt.');
    }
    return AppInfo(version: version, buildNumber: buildNumber);
  }
}
