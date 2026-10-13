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

/// Vistas de la pestaña Planear.
enum VistaPlanear { calendario, simulador }

class VistaPlanearActual extends Notifier<VistaPlanear> {
  @override
  VistaPlanear build() => VistaPlanear.calendario;

  void ver(VistaPlanear vista) => state = vista;
}

final vistaPlanearProvider =
    NotifierProvider<VistaPlanearActual, VistaPlanear>(VistaPlanearActual.new);

/// Día que se pidió simular desde el calendario. El simulador lo toma como
/// fecha de compra y lo limpia.
class DiaPorSimular extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void pedir(DateTime dia) => state = dia;

  void atender() => state = null;
}

final diaPorSimularProvider = NotifierProvider<DiaPorSimular, DateTime?>(DiaPorSimular.new);
