import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fechas.dart';
import '../data/modelos/cuenta.dart';
import '../data/modelos/gasto_fijo.dart';
import '../data/modelos/movimiento.dart';
import '../data/repositorio.dart';
import '../dominio/resumen_semanal.dart';
import 'servicios.dart';

/// Contador que sube con cada escritura; los proveedores de datos lo observan
/// para recargarse.
class RevisionDatos extends Notifier<int> {
  @override
  int build() => 0;

  void tocar() => state++;
}

final revisionDatosProvider = NotifierProvider<RevisionDatos, int>(RevisionDatos.new);

final cuentasProvider = FutureProvider<List<CuentaConSaldo>>((ref) async {
  ref.watch(revisionDatosProvider);
  final repo = await ref.watch(repositorioProvider.future);
  return repo.cuentasConSaldo();
});

final gastosFijosProvider = FutureProvider<List<GastoFijo>>((ref) async {
  ref.watch(revisionDatosProvider);
  final repo = await ref.watch(repositorioProvider.future);
  return repo.gastosFijos();
});

final movimientosSemanaProvider =
    FutureProvider.family<List<Movimiento>, DateTime>((ref, lunes) async {
  ref.watch(revisionDatosProvider);
  final repo = await ref.watch(repositorioProvider.future);
  return repo.movimientosDeSemana(lunes);
});

final ultimosMovimientosProvider = FutureProvider<List<Movimiento>>((ref) async {
  ref.watch(revisionDatosProvider);
  final repo = await ref.watch(repositorioProvider.future);
  return repo.ultimosMovimientos(limite: 5);
});

final resumenSemanalProvider =
    FutureProvider.family<ResumenSemanal, DateTime>((ref, lunes) async {
  final movimientos = await ref.watch(movimientosSemanaProvider(lunes).future);
  final cuentas = await ref.watch(cuentasProvider.future);
  final fijos = await ref.watch(gastosFijosProvider.future);
  return calcularResumenSemanal(
    lunes: lunes,
    movimientos: movimientos,
    cuentas: {
      for (final c in cuentas)
        if (c.cuenta.id != null) c.cuenta.id!: c.cuenta,
    },
    gastosFijos: fijos,
  );
});

/// Semana que se está viendo en Inicio y Movimientos.
class SemanaSeleccionada extends Notifier<DateTime> {
  @override
  DateTime build() => semanaActual();

  void anterior() => state = sumarDias(state, -7);

  void siguiente() => state = sumarDias(state, 7);

  void irAActual() => state = semanaActual();
}

final semanaSeleccionadaProvider =
    NotifierProvider<SemanaSeleccionada, DateTime>(SemanaSeleccionada.new);

extension EscrituraDatos on WidgetRef {
  /// Ejecuta una escritura en el repositorio y refresca todas las pantallas.
  Future<T> escribir<T>(Future<T> Function(Repositorio repo) accion) async {
    final repo = await read(repositorioProvider.future);
    final resultado = await accion(repo);
    read(revisionDatosProvider.notifier).tocar();
    return resultado;
  }
}
