import 'package:taugts/features/suche/models/suchmodelle.dart';

abstract interface class SucheService {
  Future<List<Suchtreffer>> suche(Suchfilter filter);
}
