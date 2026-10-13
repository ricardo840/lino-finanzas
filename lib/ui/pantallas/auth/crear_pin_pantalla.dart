import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/seguridad/servicio_auth.dart';
import '../../../estado/ajustes.dart';
import '../../../estado/auth.dart';
import '../../../estado/servicios.dart';
import '../../tema/contexto.dart';
import '../../widgets/fondo_lino.dart';
import '../../widgets/logo_lino.dart';
import '../../widgets/teclado_pin.dart';
import '../../widgets/vidrio.dart';

enum _Paso { nuevo, confirmar, huella }

/// Primera vez: crear el PIN de 6 dígitos y, si el teléfono lo permite,
/// activar la huella. Se dibuja fuera del Navigator (sin diálogos).
class CrearPinPantalla extends ConsumerStatefulWidget {
  const CrearPinPantalla({super.key});

  @override
  ConsumerState<CrearPinPantalla> createState() => _CrearPinPantallaState();
}

class _CrearPinPantallaState extends ConsumerState<CrearPinPantalla> {
  _Paso _paso = _Paso.nuevo;
  String _pin = '';
  String _primerPin = '';
  String? _mensaje;
  bool _error = false;
  bool _ocupado = false;

  void _alDigito(String digito) {
    if (_ocupado || _pin.length >= ServicioAuth.longitudPin) return;
    setState(() {
      _pin += digito;
      _error = false;
      _mensaje = null;
    });
    if (_pin.length == ServicioAuth.longitudPin) _completar();
  }

  void _alBorrar() {
    if (_pin.isEmpty || _ocupado) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _marcarError(String mensaje, {bool reiniciar = false}) {
    context.vibrarError();
    setState(() {
      _error = true;
      _mensaje = mensaje;
      _pin = '';
      if (reiniciar) {
        _primerPin = '';
        _paso = _Paso.nuevo;
      }
    });
  }

  Future<void> _completar() async {
    if (_paso == _Paso.nuevo) {
      final problema = ServicioAuth.problemaConPin(_pin);
      if (problema != null) {
        _marcarError(problema);
        return;
      }
      setState(() {
        _primerPin = _pin;
        _pin = '';
        _paso = _Paso.confirmar;
      });
      return;
    }

    if (_pin != _primerPin) {
      _marcarError('Los PIN no coinciden. Empecemos de nuevo.', reiniciar: true);
      return;
    }

    setState(() => _ocupado = true);
    await ref.read(authProvider.notifier).crearPin(_pin);
    if (!mounted) return;
    if (ref.read(authProvider).biometriaDisponible) {
      setState(() {
        _ocupado = false;
        _paso = _Paso.huella;
      });
    } else {
      ref.read(authProvider.notifier).finalizarRegistro();
    }
  }

  Future<void> _activarHuella() async {
    setState(() => _ocupado = true);
    final ok = await ref.read(servicioAuthProvider).autenticarConBiometria();
    if (ok) await ref.read(ajustesProvider.notifier).cambiarHuella(true);
    if (!mounted) return;
    ref.read(authProvider.notifier).finalizarRegistro();
  }

  @override
  Widget build(BuildContext context) {
    return FondoLino(
      child: SafeArea(
        child: _paso == _Paso.huella ? _vistaHuella() : _vistaPin(),
      ),
    );
  }

  Widget _vistaPin() {
    final tema = context.tema;
    final titulo = _paso == _Paso.nuevo ? 'Crea tu PIN' : 'Confirma tu PIN';
    final ayuda = _paso == _Paso.nuevo
        ? 'Seis dígitos para abrir Lino. Tus datos se guardan cifrados solo en este teléfono.'
        : 'Escríbelo otra vez.';
    return Column(
      children: [
        const Spacer(flex: 3),
        const LogoLino(tamano: 64),
        const SizedBox(height: 20),
        Text(titulo, style: tema.titulo),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(ayuda, style: tema.secundario, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 24),
        IndicadorPin(llenos: _pin.length, error: _error),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: Center(
            child: _ocupado
                ? const CupertinoActivityIndicator()
                : Text(
                    _mensaje ?? '',
                    textAlign: TextAlign.center,
                    style: tema.secundario.copyWith(color: tema.negativo),
                  ),
          ),
        ),
        const Spacer(flex: 2),
        TecladoPin(alDigito: _alDigito, alBorrar: _alBorrar, habilitado: !_ocupado),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _vistaHuella() {
    final tema = context.tema;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 3),
          Icon(CupertinoIcons.lock_shield, size: 64, color: tema.acento),
          const SizedBox(height: 20),
          Text('Desbloqueo con huella', style: tema.titulo),
          const SizedBox(height: 8),
          Text(
            'Abre Lino con tu huella. El PIN seguirá funcionando como respaldo.',
            style: tema.secundario,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          BotonLino(texto: 'Activar huella', onPressed: _activarHuella, cargando: _ocupado),
          const SizedBox(height: 12),
          BotonLino(
            texto: 'Ahora no',
            estilo: EstiloBoton.secundario,
            onPressed: _ocupado ? null : ref.read(authProvider.notifier).finalizarRegistro,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
