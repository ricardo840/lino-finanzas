import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/formato.dart';
import '../tema/contexto.dart';
import 'vidrio.dart';

/// Campo de texto con estilo de vidrio.
class CampoVidrio extends StatelessWidget {
  const CampoVidrio({
    super.key,
    required this.controller,
    this.placeholder,
    this.teclado,
    this.formatos,
    this.prefijo,
    this.estilo,
    this.alineacion = TextAlign.start,
    this.autofocus = false,
    this.maxLength,
    this.mayusculas = TextCapitalization.sentences,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatos;
  final String? prefijo;
  final TextStyle? estilo;
  final TextAlign alineacion;
  final bool autofocus;
  final int? maxLength;
  final TextCapitalization mayusculas;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final estiloTexto = estilo ?? tema.cuerpo.copyWith(fontSize: 16);
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: teclado,
      inputFormatters: formatos,
      autofocus: autofocus,
      maxLength: maxLength,
      textAlign: alineacion,
      textCapitalization: mayusculas,
      keyboardAppearance: tema.brillo,
      cursorColor: tema.acento,
      onChanged: onChanged,
      style: estiloTexto,
      placeholderStyle: estiloTexto.copyWith(color: tema.textoSecundario),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefix: prefijo == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(prefijo!, style: estiloTexto.copyWith(color: tema.textoSecundario)),
            ),
      decoration: BoxDecoration(
        color: tema.campo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tema.bordeVidrio),
      ),
    );
  }
}

/// Da formato al monto mientras se escribe (comas de miles y dos decimales) y
/// deja el cursor en su lugar.
class FormateadorMonto extends TextInputFormatter {
  const FormateadorMonto();

  static final _significativo = RegExp(r'[0-9.]');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final texto = formatearMontoEscrito(nuevo.text);
    final fin = nuevo.selection.end;
    if (fin < 0) {
      return TextEditingValue(
        text: texto,
        selection: TextSelection.collapsed(offset: texto.length),
      );
    }
    // Se cuentan los dígitos y puntos que quedan antes del cursor y se coloca
    // después de esa misma cantidad en el texto con comas.
    final antes = nuevo.text.substring(0, fin.clamp(0, nuevo.text.length));
    final significativos = _significativo.allMatches(antes).length;
    var posicion = 0;
    var vistos = 0;
    while (posicion < texto.length && vistos < significativos) {
      if (texto[posicion] != ',') vistos++;
      posicion++;
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: posicion),
    );
  }
}

/// Formateadores para los campos de monto.
const List<TextInputFormatter> formatoMonto = [FormateadorMonto()];

/// Etiqueta en mayúsculas encima de un campo o sección.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(texto.toUpperCase(), style: context.tema.etiqueta),
      );
}

/// Panel que agrupa filas separadas por líneas finas.
class GrupoFilas extends StatelessWidget {
  const GrupoFilas({super.key, required this.filas});

  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return PanelVidrio(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) Container(height: 0.5, color: tema.bordeVidrio),
            filas[i],
          ],
        ],
      ),
    );
  }
}

/// Fila que abre un selector: etiqueta a la izquierda, valor y flecha a la
/// derecha.
class FilaSelector extends StatelessWidget {
  const FilaSelector({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onTap,
    this.icono,
  });

  final String etiqueta;
  final String valor;
  final VoidCallback? onTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Presionable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (icono != null) ...[
              Icon(icono, size: 20, color: tema.acento),
              const SizedBox(width: 12),
            ],
            Text(etiqueta, style: tema.cuerpo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.cuerpo.copyWith(color: tema.textoSecundario),
              ),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_right, size: 16, color: tema.textoSecundario),
          ],
        ),
      ),
    );
  }
}

/// Fila con interruptor.
class FilaInterruptor extends StatelessWidget {
  const FilaInterruptor({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
    this.descripcion,
    this.icono,
  });

  final String etiqueta;
  final String? descripcion;
  final bool valor;
  final ValueChanged<bool>? onChanged;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 20, color: tema.acento),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: tema.cuerpo),
                if (descripcion != null) ...[
                  const SizedBox(height: 2),
                  Text(descripcion!, style: tema.secundario),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: valor,
            onChanged: onChanged,
            activeTrackColor: tema.acento,
          ),
        ],
      ),
    );
  }
}
