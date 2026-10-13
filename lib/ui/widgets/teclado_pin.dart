import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import 'vidrio.dart';

/// Seis círculos que se rellenan conforme se teclea el PIN.
class IndicadorPin extends StatelessWidget {
  const IndicadorPin({super.key, required this.llenos, this.longitud = 6, this.error = false});

  final int llenos;
  final int longitud;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final color = error ? tema.negativo : tema.texto;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < longitud; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.symmetric(horizontal: 9),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < llenos ? color : const Color(0x00000000),
              border: Border.all(
                color: error ? tema.negativo : tema.textoSecundario,
                width: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// Teclado numérico para el PIN.
class TecladoPin extends StatelessWidget {
  const TecladoPin({
    super.key,
    required this.alDigito,
    required this.alBorrar,
    this.accionIzquierda,
    this.habilitado = true,
  });

  final ValueChanged<String> alDigito;
  final VoidCallback alBorrar;

  /// Espacio libre abajo a la izquierda (p. ej. botón de huella).
  final Widget? accionIzquierda;
  final bool habilitado;

  static const double _tamano = 76;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;

    Widget tecla(String digito) => _TeclaPin(
          digito: digito,
          onTap: habilitado
              ? () {
                  context.vibrarToque();
                  alDigito(digito);
                }
              : null,
        );

    const filas = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final fila in filas)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final d in fila) tecla(d)],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: _tamano, height: _tamano, child: accionIzquierda),
            tecla('0'),
            SizedBox(
              width: _tamano,
              height: _tamano,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: habilitado ? alBorrar : null,
                child: Icon(CupertinoIcons.delete_left, size: 28, color: tema.texto),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeclaPin extends StatelessWidget {
  const _TeclaPin({required this.digito, required this.onTap});

  final String digito;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return SizedBox(
      width: TecladoPin._tamano,
      height: TecladoPin._tamano,
      child: PanelVidrio(
        radio: TecladoPin._tamano / 2,
        padding: EdgeInsets.zero,
        desenfoque: false,
        onTap: onTap,
        child: Center(
          child: Text(
            digito,
            style: TextStyle(
              color: tema.texto,
              fontSize: 30,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
