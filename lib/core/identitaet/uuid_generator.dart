import 'package:uuid/uuid.dart';

abstract interface class IdGenerator {
  String neueId();
}

class UuidGenerator implements IdGenerator {
  const UuidGenerator();

  static const _uuid = Uuid();

  @override
  String neueId() => _uuid.v4();
}
