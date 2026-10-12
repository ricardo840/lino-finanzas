import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/seguridad/servicio_auth.dart';
import 'servicios.dart';

enum FaseAuth {
  /// Leyendo si ya existe un PIN.
  cargando,

  /// Primera vez: hay que crear el PIN.
  crearPin,

  /// Hay PIN y la app está bloqueada.
  bloqueada,
  desbloqueada,
}

class EstadoAuth {
  const EstadoAuth({
    required this.fase,
    this.sesionIniciada = false,
    this.biometriaDisponible = false,
  });

  final FaseAuth fase;

  /// Ya se desbloqueó al menos una vez desde que abrió la app (la interfaz
  /// principal se construye a partir de entonces).
  final bool sesionIniciada;
  final bool biometriaDisponible;

  EstadoAuth copyWith({FaseAuth? fase, bool? sesionIniciada, bool? biometriaDisponible}) =>
      EstadoAuth(
        fase: fase ?? this.fase,
        sesionIniciada: sesionIniciada ?? this.sesionIniciada,
        biometriaDisponible: biometriaDisponible ?? this.biometriaDisponible,
      );
}

class AuthNotifier extends Notifier<EstadoAuth> {
  @override
  EstadoAuth build() {
    unawaited(Future<void>.microtask(_iniciar));
    return const EstadoAuth(fase: FaseAuth.cargando);
  }

  ServicioAuth get _servicio => ref.read(servicioAuthProvider);

  bool get autenticandoBiometria => _servicio.autenticandoBiometria;

  Future<void> _iniciar() async {
    final tienePin = await _servicio.tienePin();
    final biometria = await _servicio.biometriaDisponible();
    state = EstadoAuth(
      fase: tienePin ? FaseAuth.bloqueada : FaseAuth.crearPin,
      biometriaDisponible: biometria,
    );
  }

  Future<void> crearPin(String pin) => _servicio.guardarPin(pin);

  /// Cierra el flujo de primera vez y entra a la app.
  void finalizarRegistro() => _desbloquear();

  Future<ResultadoPin> ingresarPin(String pin) async {
    final resultado = await _servicio.verificarPin(pin);
    if (resultado.correcto) _desbloquear();
    return resultado;
  }

  Future<bool> ingresarConBiometria() async {
    final ok = await _servicio.autenticarConBiometria();
    if (ok) _desbloquear();
    return ok;
  }

  void bloquear() {
    if (state.fase == FaseAuth.desbloqueada) {
      state = state.copyWith(fase: FaseAuth.bloqueada);
    }
  }

  void _desbloquear() =>
      state = state.copyWith(fase: FaseAuth.desbloqueada, sesionIniciada: true);
}

final authProvider = NotifierProvider<AuthNotifier, EstadoAuth>(AuthNotifier.new);
