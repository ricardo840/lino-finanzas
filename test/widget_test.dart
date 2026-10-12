import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/ui/tema/lino_tema.dart';
import 'package:lino/ui/tema/temas.dart';
import 'package:lino/ui/widgets/fondo_lino.dart';
import 'package:lino/ui/widgets/logo_lino.dart';
import 'package:lino/ui/widgets/teclado_pin.dart';

void main() {
  for (final tema in temasLino) {
    testWidgets('el teclado del PIN se dibuja con el tema ${tema.nombre}', (tester) async {
      final digitos = <String>[];
      await tester.pumpWidget(
        CupertinoApp(
          home: LinoTemaScope(
            tema: tema,
            child: FondoLino(
              child: Column(
                children: [
                  const LogoLino(),
                  const IndicadorPin(llenos: 2),
                  TecladoPin(alDigito: digitos.add, alBorrar: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('7'));
      await tester.tap(find.text('0'));
      expect(digitos, ['7', '0']);
    });
  }
}
