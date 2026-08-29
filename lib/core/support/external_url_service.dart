import 'package:flutter/services.dart';

abstract interface class ExternalUrlGateway {
  Future<void> oeffnen(String url);
}

class ExternalUrlService implements ExternalUrlGateway {
  static const _kanal = MethodChannel('taugts/external_url');

  @override
  Future<void> oeffnen(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Ungültiger externer Link.');
    }
    await _kanal.invokeMethod<void>('open', {'url': url});
  }
}
