import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../estado/ajustes.dart';
import '../../tema/contexto.dart';
import '../../tema/lino_tema.dart';
import '../../tema/temas.dart';
import '../../widgets/campos.dart';
import '../../widgets/fondo_lino.dart';
import '../../widgets/vidrio.dart';

class TemasPantalla extends ConsumerWidget {
  const TemasPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.tema;
    final actual = ref.watch(ajustesProvider.select((a) => a.temaId));
    final oscuros = temasLino.where((t) => t.esOscuro).toList();
    final claros = temasLino.where((t) => !t.esOscuro).toList();

    Widget cuadricula(List<LinoTema> temas) => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            for (final t in temas)
              _MuestraTema(
                tema: t,
                seleccionado: t.id == actual,
                onTap: () => ref.read(ajustesProvider.notifier).cambiarTema(t.id),
              ),
          ],
        );

    return CupertinoPageScaffold(
      backgroundColor: tema.fondo.first,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Tema'),
        backgroundColor: tema.barra,
        border: null,
      ),
      child: FondoLino(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 32),
            children: [
              const Etiqueta('Oscuros'),
              cuadricula(oscuros),
              const SizedBox(height: 20),
              const Etiqueta('Claros de temporada'),
              cuadricula(claros),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista previa en miniatura de un tema.
class _MuestraTema extends StatelessWidget {
  const _MuestraTema({required this.tema, required this.seleccionado, required this.onTap});

  final LinoTema tema;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actual = context.tema;
    return Presionable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? actual.acento : actual.bordeVidrio,
            width: seleccionado ? 2.5 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tema.manchas[0], tema.fondo[1], tema.manchas[1]],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tema.acento),
                ),
                const Spacer(),
                if (seleccionado)
                  Icon(CupertinoIcons.checkmark_alt_circle_fill, color: tema.texto, size: 22),
              ],
            ),
            const Spacer(),
            Container(
              height: 26,
              decoration: BoxDecoration(
                color: tema.vidrioAlto,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tema.bordeVidrio),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tema.nombre,
              style: TextStyle(color: tema.texto, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
