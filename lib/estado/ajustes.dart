import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/seguridad/almacen_seguro.dart';
import '../ui/tema/lino_tema.dart';
import '../ui/tema/temas.dart';
import 'servicios.dart';

/// Preferencias del usuario. Se guardan en el almacén seguro.
class Ajustes {
  const Ajustes({
    this.temaId = temaPorDefectoId,
    this.privacidad = false,
    this.huellaActiva = false,
    this.bloqueoSegundos = 30,
  });

  final String temaId;

  /// Oculta todos los montos en pantalla.
  final bool privacidad;
  final bool huellaActiva;

  /// Tiempo en segundo plano tras el cual se vuelve a pedir PIN o huella.
  final int bloqueoSegundos;

  Ajustes copyWith({
    String? temaId,
    bool? privacidad,
    bool? huellaActiva,
    int? bloqueoSegundos,
  }) =>
      Ajustes(
        temaId: temaId ?? this.temaId,
        privacidad: privacidad ?? this.privacidad,
        huellaActiva: huellaActiva ?? this.huellaActiva,
        bloqueoSegundos: bloqueoSegundos ?? this.bloqueoSegundos,
      );
}

class AlmacenAjustes {
  AlmacenAjustes(this._almacen);

  final AlmacenSeguro _almacen;

  static const _kTema = 'ajuste_tema';
  static const _kPrivacidad = 'ajuste_privacidad';
  static const _kHuella = 'ajuste_huella';
  static const _kBloqueo = 'ajuste_bloqueo_segundos';

  Future<Ajustes> cargar() async {
    const base = Ajustes();
    return Ajustes(
      temaId: await _almacen.leer(_kTema) ?? base.temaId,
      privacidad: (await _almacen.leer(_kPrivacidad)) == '1',
      huellaActiva: (await _almacen.leer(_kHuella)) == '1',
      bloqueoSegundos:
          int.tryParse(await _almacen.leer(_kBloqueo) ?? '') ?? base.bloqueoSegundos,
    );
  }

  Future<void> guardar(Ajustes a) async {
    await _almacen.escribir(_kTema, a.temaId);
    await _almacen.escribir(_kPrivacidad, a.privacidad ? '1' : '0');
    await _almacen.escribir(_kHuella, a.huellaActiva ? '1' : '0');
    await _almacen.escribir(_kBloqueo, '${a.bloqueoSegundos}');
  }
}

/// Se sobreescribe en main() con lo leído antes de arrancar, para que el tema
/// correcto aparezca desde el primer cuadro.
final ajustesInicialesProvider = Provider<Ajustes>((ref) => const Ajustes());

class AjustesNotifier extends Notifier<Ajustes> {
  @override
  Ajustes build() => ref.watch(ajustesInicialesProvider);

  AlmacenAjustes get _almacen => AlmacenAjustes(ref.read(almacenSeguroProvider));

  Future<void> _actualizar(Ajustes nuevos) async {
    state = nuevos;
    await _almacen.guardar(nuevos);
  }

  Future<void> cambiarTema(String id) => _actualizar(state.copyWith(temaId: id));

  Future<void> cambiarPrivacidad(bool valor) =>
      _actualizar(state.copyWith(privacidad: valor));

  Future<void> alternarPrivacidad() => cambiarPrivacidad(!state.privacidad);

  Future<void> cambiarHuella(bool valor) => _actualizar(state.copyWith(huellaActiva: valor));

  Future<void> cambiarBloqueo(int segundos) =>
      _actualizar(state.copyWith(bloqueoSegundos: segundos));
}

final ajustesProvider = NotifierProvider<AjustesNotifier, Ajustes>(AjustesNotifier.new);

final temaProvider = Provider<LinoTema>(
  (ref) => temaPorId(ref.watch(ajustesProvider.select((a) => a.temaId))),
);

final privacidadProvider = Provider<bool>(
  (ref) => ref.watch(ajustesProvider.select((a) => a.privacidad)),
);
