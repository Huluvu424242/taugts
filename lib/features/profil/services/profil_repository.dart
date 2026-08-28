import 'package:taugts/features/profil/models/profil.dart';

abstract interface class ProfilRepository {
  Future<Profil> ladeOderErstelleProfil();
  Future<void> speichereProfil(Profil profil);
}
