import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formato.dart';
import '../../../core/seguridad/servicio_auth.dart';
import '../../../estado/servicios.dart';
import '../../tema/contexto.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/paginas.dart';
import '../../widgets/teclado_pin.dart';

enum _Paso { actual, nuevo, confirmar }

/// Cambia el PIN: pide el actual, el nuevo y su confirmación.
class CambiarPinPantalla extends ConsumerStatefulWidget {
  const CambiarPinPantalla({super.key});

  @override
  ConsumerState<CambiarPinPantalla> createState() => _CambiarPinPantallaState();
}

class _CambiarPinPantallaState extends ConsumerState<CambiarPinPantalla> {
  _Paso _paso = _Paso.actual;
  String _pin = '';
  String _nuevo = '';
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

  void _marcarError(String mensaje, {_Paso? volverA}) {
    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _ocupado = false;
      _error = true;
      _mensaje = mensaje;
      _pin = '';
      if (volverA != null) _paso = volverA;
    });
  }

  Future<void> _completar() async {
    final servicio = ref.read(servicioAuthProvider);
    switch (_paso) {
      case _Paso.actual:
        setState(() => _ocupado = true);
        final r = await servicio.verificarPin(_pin);
        if (!mounted) return;
        if (!r.correcto) {
          _marcarError(
            r.bloqueadoHasta != null
                ? 'Demasiados intentos. Intenta más tarde.'
                : 'PIN incorrecto. Te quedan ${plural(r.intentosRestantes, 'intento', 'intentos')}.',
          );
          return;
        }
        setState(() {
          _ocupado = false;
          _pin = '';
          _paso = _Paso.nuevo;
        });
      case _Paso.nuevo:
        final problema = ServicioAuth.problemaConPin(_pin);
        if (problema != null) {
          _marcarError(problema);
          return;
        }
        setState(() {
          _nuevo = _pin;
          _pin = '';
          _paso = _Paso.confirmar;
        });
      case _Paso.confirmar:
        if (_pin != _nuevo) {
          _marcarError('No coinciden. Escribe el nuevo PIN otra vez.', volverA: _Paso.nuevo);
          return;
        }
        setState(() => _ocupado = true);
        await servicio.guardarPin(_pin);
        if (!mounted) return;
        await avisar(context, titulo: 'PIN actualizado', mensaje: 'Usa tu nuevo PIN la próxima vez que abras Lino.');
        if (!mounted) return;
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final titulo = switch (_paso) {
      _Paso.actual => 'Escribe tu PIN actual',
      _Paso.nuevo => 'Escribe el nuevo PIN',
      _Paso.confirmar => 'Confirma el nuevo PIN',
    };
    return PaginaSecundaria(
      titulo: 'Cambiar PIN',
      cuerpo: Column(
        children: [
          const Spacer(flex: 2),
          Text(titulo, style: tema.titulo),
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
          const Spacer(),
          TecladoPin(alDigito: _alDigito, alBorrar: _alBorrar, habilitado: !_ocupado),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
