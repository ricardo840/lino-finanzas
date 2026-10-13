import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/ui/widgets/campos.dart';

/// Aplica el formateador a un texto con el cursor en [cursor] (al final si no
/// se indica).
TextEditingValue _escribir(String texto, {int? cursor}) => const FormateadorMonto().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: texto,
        selection: TextSelection.collapsed(offset: cursor ?? texto.length),
      ),
    );

void main() {
  group('FormateadorMonto', () {
    test('agrega las comas y deja el cursor al final al escribir', () {
      final r = _escribir('1500');
      expect(r.text, '1,500');
      expect(r.selection.baseOffset, 5);
    });

    test('conserva el cursor al escribir en medio', () {
      // "1,234" y se teclea un 9 después del 1: llega "19,234" con el cursor en 2.
      final r = _escribir('19,234', cursor: 2);
      expect(r.text, '19,234');
      expect(r.selection.baseOffset, 2);
    });

    test('reacomoda las comas al borrar', () {
      // De "1,234" se borra el 4: llega "1,23".
      final r = _escribir('1,23');
      expect(r.text, '123');
      expect(r.selection.baseOffset, 3);
    });

    test('el cursor salta la coma nueva', () {
      // De "123" se teclea un 4 al final.
      final r = _escribir('1234');
      expect(r.text, '1,234');
      expect(r.selection.baseOffset, 5);
    });
  });
}
