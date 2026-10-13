import 'package:flutter/cupertino.dart';

import '../../core/formato.dart';
import '../tema/contexto.dart';
import 'campos.dart';

/// Pregunta sí/no. Regresa true solo si el usuario confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String accion = 'Aceptar',
  bool destructiva = false,
}) async {
  final respuesta = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(titulo),
      content: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(mensaje),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructiva,
          isDefaultAction: !destructiva,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}

/// Aviso con un solo botón.
Future<void> avisar(BuildContext context, {required String titulo, required String mensaje}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(titulo),
      content: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(mensaje),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

/// Pide un monto en un diálogo. Regresa los centavos (0 si se dejó vacío) o
/// null si se canceló.
Future<int?> pedirMonto(
  BuildContext context, {
  required String titulo,
  String? mensaje,
  int inicial = 0,
}) {
  return showCupertinoDialog<int>(
    context: context,
    builder: (_) => _DialogoMonto(titulo: titulo, mensaje: mensaje, inicial: inicial),
  );
}

class _DialogoMonto extends StatefulWidget {
  const _DialogoMonto({required this.titulo, required this.mensaje, required this.inicial});

  final String titulo;
  final String? mensaje;
  final int inicial;

  @override
  State<_DialogoMonto> createState() => _DialogoMontoState();
}

class _DialogoMontoState extends State<_DialogoMonto> {
  late final _monto = TextEditingController(
    text: widget.inicial > 0 ? montoEditable(widget.inicial) : '',
  );
  bool _invalido = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _guardar() {
    final texto = _monto.text.trim();
    final centavos = texto.isEmpty ? 0 : parsearDinero(texto);
    if (centavos == null) {
      setState(() => _invalido = true);
      return;
    }
    Navigator.of(context).pop(centavos);
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final mensaje = widget.mensaje;
    return CupertinoAlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mensaje != null)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(mensaje)),
          const SizedBox(height: 14),
          CupertinoTextField(
            controller: _monto,
            autofocus: true,
            placeholder: '0.00',
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatoMonto,
            prefix: const Padding(padding: EdgeInsets.only(left: 10), child: Text('\$')),
            onChanged: (_) {
              if (_invalido) setState(() => _invalido = false);
            },
            onSubmitted: (_) => _guardar(),
          ),
          if (_invalido)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Revisa el monto.', style: TextStyle(color: tema.negativo)),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class Opcion<T> {
  const Opcion(this.valor, this.etiqueta, {this.seleccionada = false});

  final T valor;
  final String etiqueta;
  final bool seleccionada;
}

/// Hoja de acciones para escoger una opción.
Future<T?> elegirOpcion<T>(
  BuildContext context, {
  required String titulo,
  required List<Opcion<T>> opciones,
  String? mensaje,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(titulo),
      message: mensaje == null ? null : Text(mensaje),
      actions: [
        for (final o in opciones)
          CupertinoActionSheetAction(
            isDefaultAction: o.seleccionada,
            onPressed: () => Navigator.of(ctx).pop(o.valor),
            child: Text(o.etiqueta),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text('Cancelar'),
      ),
    ),
  );
}

/// Hoja inferior con un selector y botones Cancelar / Listo.
Future<T?> _hojaSelector<T>(
  BuildContext context, {
  required Widget Function(ValueChanged<T> alCambiar) selector,
  required T inicial,
}) {
  var seleccion = inicial;
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) {
      final tema = ctx.tema;
      return Container(
        height: 330,
        decoration: BoxDecoration(
          color: tema.hoja,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: tema.bordeVidrio),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.of(ctx).pop(seleccion),
                    child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              Expanded(child: selector((valor) => seleccion = valor)),
            ],
          ),
        ),
      );
    },
  );
}

Future<DateTime?> elegirFecha(
  BuildContext context, {
  required DateTime inicial,
  DateTime? minima,
  DateTime? maxima,
}) {
  return _hojaSelector<DateTime>(
    context,
    inicial: inicial,
    selector: (alCambiar) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: inicial,
      minimumDate: minima,
      maximumDate: maxima,
      dateOrder: DatePickerDateOrder.dmy,
      onDateTimeChanged: alCambiar,
    ),
  );
}

/// Selector de un número entero entre [minimo] y [maximo].
Future<int?> elegirNumero(
  BuildContext context, {
  required int inicial,
  required int minimo,
  required int maximo,
  String Function(int)? etiqueta,
}) {
  final valorInicial = inicial.clamp(minimo, maximo);
  return _hojaSelector<int>(
    context,
    inicial: valorInicial,
    selector: (alCambiar) => CupertinoPicker(
      itemExtent: 38,
      scrollController: FixedExtentScrollController(initialItem: valorInicial - minimo),
      onSelectedItemChanged: (i) => alCambiar(minimo + i),
      children: [
        for (var n = minimo; n <= maximo; n++)
          Center(child: Text(etiqueta == null ? '$n' : etiqueta(n))),
      ],
    ),
  );
}
