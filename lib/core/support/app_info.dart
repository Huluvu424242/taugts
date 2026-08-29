class AppInfo {
  const AppInfo({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;

  String get displayVersion =>
      buildNumber.isEmpty ? version : '$version+$buildNumber';
}
