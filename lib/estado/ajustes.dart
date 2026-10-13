import 'dart:ui' show Brightness, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/seguridad/almacen_seguro.dart';
import '../ui/tema/lino_tema.dart';
import '../ui/tema/temas.dart';
import 'servicios.dart';

/// Preferencias del usuario. Se guardan en el almacén seguro.
class Ajustes {
  const Ajustes({
    this.temaId = temaPorDefectoId,
    this.temaAutomatico = false,
    this.temaClaroId = temaClaroPorDefectoId,
    this.temaOscuroId = temaPorDefectoId,
    this.reducirDesenfoque = false,
    this.vibracion = true,
    this.privacidad = false,
    this.ocultarAlAbrir = false,
    this.huellaActiva = false,
    this.bloqueoSegundos = 30,
    this.sueldoHabitual = 0,
    this.cuentaPredeterminadaId,
  });

  /// Tema elegido cuando no se sigue al sistema.
  final String temaId;

  /// Usa [temaClaroId] u [temaOscuroId] según el modo claro u oscuro del
  /// teléfono.
  final bool temaAutomatico;
  final String temaClaroId;
  final String temaOscuroId;

  /// Quita el desenfoque de los paneles de vidrio.
  final bool reducirDesenfoque;

  /// Respuesta háptica al tocar.
  final bool vibracion;

  /// Oculta todos los montos en pantalla.
  final bool privacidad;

  /// Activa [privacidad] cada vez que la app se abre o se bloquea.
  final bool ocultarAlAbrir;
  final bool huellaActiva;

  /// Tiempo en segundo plano tras el cual se vuelve a pedir PIN o huella.
  final int bloqueoSegundos;

  /// Sueldo semanal habitual en centavos (0 si no se ha definido). Solo se
  /// usa para estimaciones; el presupuesto usa los sueldos registrados.
  final int sueldoHabitual;

  /// Cuenta que se propone al registrar un movimiento.
  final int? cuentaPredeterminadaId;

  Ajustes copyWith({
    String? temaId,
    bool? temaAutomatico,
    String? temaClaroId,
    String? temaOscuroId,
    bool? reducirDesenfoque,
    bool? vibracion,
    bool? privacidad,
    bool? ocultarAlAbrir,
    bool? huellaActiva,
    int? bloqueoSegundos,
    int? sueldoHabitual,
  }) =>
      Ajustes(
        temaId: temaId ?? this.temaId,
        temaAutomatico: temaAutomatico ?? this.temaAutomatico,
        temaClaroId: temaClaroId ?? this.temaClaroId,
        temaOscuroId: temaOscuroId ?? this.temaOscuroId,
        reducirDesenfoque: reducirDesenfoque ?? this.reducirDesenfoque,
        vibracion: vibracion ?? this.vibracion,
        privacidad: privacidad ?? this.privacidad,
        ocultarAlAbrir: ocultarAlAbrir ?? this.ocultarAlAbrir,
        huellaActiva: huellaActiva ?? this.huellaActiva,
        bloqueoSegundos: bloqueoSegundos ?? this.bloqueoSegundos,
        sueldoHabitual: sueldoHabitual ?? this.sueldoHabitual,
        cuentaPredeterminadaId: cuentaPredeterminadaId,
      );

  /// Copia con otra cuenta predeterminada (null para quitarla).
  Ajustes conCuentaPredeterminada(int? id) => Ajustes(
        temaId: temaId,
        temaAutomatico: temaAutomatico,
        temaClaroId: temaClaroId,
        temaOscuroId: temaOscuroId,
        reducirDesenfoque: reducirDesenfoque,
        vibracion: vibracion,
        privacidad: privacidad,
        ocultarAlAbrir: ocultarAlAbrir,
        huellaActiva: huellaActiva,
        bloqueoSegundos: bloqueoSegundos,
        sueldoHabitual: sueldoHabitual,
        cuentaPredeterminadaId: id,
      );

  /// Valores tal como se guardan, por clave del almacén.
  Map<String, String> _aTexto() => {
        'ajuste_tema': temaId,
        'ajuste_tema_automatico': temaAutomatico ? '1' : '0',
        'ajuste_tema_claro': temaClaroId,
        'ajuste_tema_oscuro': temaOscuroId,
        'ajuste_reducir_desenfoque': reducirDesenfoque ? '1' : '0',
        'ajuste_vibracion': vibracion ? '1' : '0',
        'ajuste_privacidad': privacidad ? '1' : '0',
        'ajuste_ocultar_al_abrir': ocultarAlAbrir ? '1' : '0',
        'ajuste_huella': huellaActiva ? '1' : '0',
        'ajuste_bloqueo_segundos': '$bloqueoSegundos',
        'ajuste_sueldo_habitual': '$sueldoHabitual',
        'ajuste_cuenta_predeterminada': cuentaPredeterminadaId == null ? '' : '$cuentaPredeterminadaId',
      };
}

class AlmacenAjustes {
  AlmacenAjustes(this._almacen);

  final AlmacenSeguro _almacen;

  Future<Ajustes> cargar() async {
    const base = Ajustes();
    final guardado = <String, String?>{
      for (final clave in base._aTexto().keys) clave: await _almacen.leer(clave),
    };
    bool logico(String clave, bool porDefecto) {
      final valor = guardado[clave];
      return valor == null ? porDefecto : valor == '1';
    }

    return Ajustes(
      temaId: guardado['ajuste_tema'] ?? base.temaId,
      temaAutomatico: logico('ajuste_tema_automatico', base.temaAutomatico),
      temaClaroId: guardado['ajuste_tema_claro'] ?? base.temaClaroId,
      temaOscuroId: guardado['ajuste_tema_oscuro'] ?? base.temaOscuroId,
      reducirDesenfoque: logico('ajuste_reducir_desenfoque', base.reducirDesenfoque),
      vibracion: logico('ajuste_vibracion', base.vibracion),
      privacidad: logico('ajuste_privacidad', base.privacidad),
      ocultarAlAbrir: logico('ajuste_ocultar_al_abrir', base.ocultarAlAbrir),
      huellaActiva: logico('ajuste_huella', base.huellaActiva),
      bloqueoSegundos:
          int.tryParse(guardado['ajuste_bloqueo_segundos'] ?? '') ?? base.bloqueoSegundos,
      sueldoHabitual: int.tryParse(guardado['ajuste_sueldo_habitual'] ?? '') ?? base.sueldoHabitual,
      cuentaPredeterminadaId: int.tryParse(guardado['ajuste_cuenta_predeterminada'] ?? ''),
    );
  }

  /// Guarda solo lo que cambió: cada escritura al almacén seguro es lenta.
  Future<void> guardar(Ajustes nuevos, {Ajustes? anteriores}) async {
    final previo = anteriores?._aTexto();
    for (final entrada in nuevos._aTexto().entries) {
      if (previo != null && previo[entrada.key] == entrada.value) continue;
      await _almacen.escribir(entrada.key, entrada.value);
    }
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
    final anteriores = state;
    state = nuevos;
    await _almacen.guardar(nuevos, anteriores: anteriores);
  }

  /// Elige un tema. Si se sigue al sistema, sustituye al claro o al oscuro
  /// según el tipo del tema elegido.
  Future<void> cambiarTema(String id) {
    if (!state.temaAutomatico) return _actualizar(state.copyWith(temaId: id));
    return temaPorId(id).esOscuro
        ? _actualizar(state.copyWith(temaOscuroId: id))
        : _actualizar(state.copyWith(temaClaroId: id));
  }

  /// Al activarlo, el tema que se estaba usando queda como el claro o el
  /// oscuro; al apagarlo, se conserva el que se está viendo.
  Future<void> cambiarTemaAutomatico(bool valor) {
    if (valor) {
      final actual = temaPorId(state.temaId);
      return _actualizar(
        actual.esOscuro
            ? state.copyWith(temaAutomatico: true, temaOscuroId: actual.id)
            : state.copyWith(temaAutomatico: true, temaClaroId: actual.id),
      );
    }
    final visible = _temaVisible(state, ref.read(brilloSistemaProvider));
    return _actualizar(state.copyWith(temaAutomatico: false, temaId: visible));
  }

  Future<void> cambiarReducirDesenfoque(bool valor) =>
      _actualizar(state.copyWith(reducirDesenfoque: valor));

  Future<void> cambiarVibracion(bool valor) => _actualizar(state.copyWith(vibracion: valor));

  Future<void> cambiarPrivacidad(bool valor) =>
      _actualizar(state.copyWith(privacidad: valor));

  Future<void> alternarPrivacidad() => cambiarPrivacidad(!state.privacidad);

  Future<void> cambiarOcultarAlAbrir(bool valor) =>
      _actualizar(state.copyWith(ocultarAlAbrir: valor));

  Future<void> cambiarHuella(bool valor) => _actualizar(state.copyWith(huellaActiva: valor));

  Future<void> cambiarBloqueo(int segundos) =>
      _actualizar(state.copyWith(bloqueoSegundos: segundos));

  Future<void> cambiarSueldoHabitual(int centavos) =>
      _actualizar(state.copyWith(sueldoHabitual: centavos));

  Future<void> cambiarCuentaPredeterminada(int? id) =>
      _actualizar(state.conCuentaPredeterminada(id));
}

final ajustesProvider = NotifierProvider<AjustesNotifier, Ajustes>(AjustesNotifier.new);

/// Modo claro u oscuro del teléfono. Lo actualiza LinoApp cuando cambia.
class BrilloSistema extends Notifier<Brightness> {
  @override
  Brightness build() => PlatformDispatcher.instance.platformBrightness;

  void fijar(Brightness brillo) => state = brillo;
}

final brilloSistemaProvider = NotifierProvider<BrilloSistema, Brightness>(BrilloSistema.new);

/// Id del tema que toca mostrar con esos ajustes y ese modo del teléfono.
String _temaVisible(Ajustes ajustes, Brightness brillo) {
  if (!ajustes.temaAutomatico) return ajustes.temaId;
  return brillo == Brightness.dark ? ajustes.temaOscuroId : ajustes.temaClaroId;
}

final temaProvider = Provider<LinoTema>(
  (ref) => temaPorId(_temaVisible(ref.watch(ajustesProvider), ref.watch(brilloSistemaProvider))),
);

final privacidadProvider = Provider<bool>(
  (ref) => ref.watch(ajustesProvider.select((a) => a.privacidad)),
);
