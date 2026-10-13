import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Posición de cada pestaña en la isla.
abstract final class Pestana {
  static const int inicio = 0;
  static const int cuentas = 1;
  static const int movimientos = 2;
  static const int planear = 3;
  static const int ajustes = 4;
}

/// Pestaña abierta en la pantalla principal. Vive en un proveedor para que
/// cualquier pantalla pueda mandar a otra pestaña.
class PestanaActual extends Notifier<int> {
  @override
  int build() => Pestana.inicio;

  void ir(int pestana) => state = pestana;
}

final pestanaProvider = NotifierProvider<PestanaActual, int>(PestanaActual.new);
