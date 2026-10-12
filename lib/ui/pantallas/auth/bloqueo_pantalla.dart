import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formato.dart';
import '../../../core/seguridad/servicio_auth.dart';
import '../../../estado/ajustes.dart';
import '../../../estado/auth.dart';
import '../../../estado/servicios.dart';
import '../../tema/contexto.dart';
import '../../widgets/fondo_lino.dart';
import '../../widgets/logo_lino.dart';
import '../../widgets/teclado_pin.dart';

/// Pantalla de bloqueo: PIN de 6 dígitos o huella.
///
/// Se dibuja encima de toda la app (fuera del Navigator), así que no abre
/// diálogos.
class BloqueoPantalla extends ConsumerStatefulWidget {
  const BloqueoPantalla({super.key});

  @override
  ConsumerState<BloqueoPantalla> createState() => _BloqueoPantallaState();
}

class _BloqueoPantallaState extends ConsumerState<BloqueoPantalla> {
  String _pin = '';
  String? _mensaje;
  bool _error = false;
  bool _verificando = false;
  DateTime? _bloqueadoHasta;
  Timer? _reloj;

  bool get _huellaActiva =>
      ref.read(ajustesProvider).huellaActiva && ref.read(authProvider).biometriaDisponible;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final hasta = await ref.read(servicioAuthProvider).bloqueadoHasta();
    if (!mounted) return;
    if (hasta != null) {
      _iniciarEspera(hasta);
    } else if (_huellaActiva) {
      await _usarHuella();
    }
  }

  Future<void> _usarHuella() async {
    if (_bloqueadoHasta != null) return;
    await ref.read(authProvider.notifier).ingresarConBiometria();
  }

  void _alDigito(String digito) {
    if (_verificando || _bloqueadoHasta != null || _pin.length >= ServicioAuth.longitudPin) {
      return;
    }
    setState(() {
      _pin += digito;
      _error = false;
      _mensaje = null;
    });
    if (_pin.length == ServicioAuth.longitudPin) _verificar();
  }

  void _alBorrar() {
    if (_pin.isEmpty || _verificando) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verificar() async {
    setState(() => _verificando = true);
    final resultado = await ref.read(authProvider.notifier).ingresarPin(_pin);
    if (!mounted || resultado.correcto) return;
    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _verificando = false;
      _pin = '';
      _error = true;
      _mensaje = resultado.bloqueadoHasta == null
          ? 'PIN incorrecto. Te quedan '
              '${plural(resultado.intentosRestantes, 'intento', 'intentos')}.'
          : null;
    });
    final hasta = resultado.bloqueadoHasta;
    if (hasta != null) _iniciarEspera(hasta);
  }

  void _iniciarEspera(DateTime hasta) {
    _reloj?.cancel();
    setState(() => _bloqueadoHasta = hasta);
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (DateTime.now().isAfter(hasta)) {
        t.cancel();
        setState(() {
          _bloqueadoHasta = null;
          _error = false;
          _mensaje = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final hasta = _bloqueadoHasta;
    final segundos = hasta == null ? 0 : hasta.difference(DateTime.now()).inSeconds + 1;
    final aviso = hasta != null
        ? 'Demasiados intentos. Espera ${segundos >= 60 ? '${(segundos / 60).ceil()} min' : '$segundos s'}.'
        : (_mensaje ?? '');

    return FondoLino(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            const LogoLino(tamano: 64),
            const SizedBox(height: 20),
            Text('Ingresa tu PIN', style: tema.titulo),
            const SizedBox(height: 24),
            IndicadorPin(llenos: _pin.length, error: _error),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: Center(
                child: _verificando
                    ? const CupertinoActivityIndicator()
                    : Text(
                        aviso,
                        textAlign: TextAlign.center,
                        style: tema.secundario.copyWith(
                          color: _error || hasta != null ? tema.negativo : null,
                        ),
                      ),
              ),
            ),
            const Spacer(flex: 2),
            TecladoPin(
              alDigito: _alDigito,
              alBorrar: _alBorrar,
              habilitado: !_verificando && hasta == null,
              accionIzquierda: _huellaActiva
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _usarHuella,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.lock_shield, size: 28, color: tema.acento),
                          const SizedBox(height: 2),
                          Text('Huella', style: tema.secundario.copyWith(color: tema.acento, fontSize: 11)),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
