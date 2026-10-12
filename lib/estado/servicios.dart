import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/seguridad/almacen_seguro.dart';
import '../core/seguridad/servicio_auth.dart';
import '../data/base_datos.dart';
import '../data/repositorio.dart';

/// Se sobreescribe en main() con la instancia real.
final almacenSeguroProvider = Provider<AlmacenSeguro>((ref) => AlmacenSeguroDispositivo());

final servicioAuthProvider = Provider<ServicioAuth>(
  (ref) => ServicioAuth(ref.watch(almacenSeguroProvider)),
);

/// La base se abre la primera vez que una pantalla pide datos (después de
/// desbloquear).
final baseDatosProvider = FutureProvider<Database>((ref) async {
  final db = await BaseDatos.abrir(ref.watch(almacenSeguroProvider));
  ref.onDispose(db.close);
  return db;
});

final repositorioProvider = FutureProvider<Repositorio>(
  (ref) async => Repositorio(await ref.watch(baseDatosProvider.future)),
);
