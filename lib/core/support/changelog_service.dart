import 'package:flutter/services.dart';

abstract interface class ChangelogGateway {
  Future<String> laden();
}

class AssetChangelogService implements ChangelogGateway {
  const AssetChangelogService();

  @override
  Future<String> laden() => rootBundle.loadString('CHANGELOG.md');
}
