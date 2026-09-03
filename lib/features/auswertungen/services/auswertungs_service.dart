import 'package:taugts/features/auswertungen/models/auswertungsmodelle.dart';

abstract interface class AuswertungsService {
  Future<AuswertungsUebersicht> berechne(AuswertungsFilter filter);
}
