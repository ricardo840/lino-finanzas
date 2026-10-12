import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/fechas.dart';
import 'modelos/cuenta.dart';
import 'modelos/gasto_fijo.dart';
import 'modelos/movimiento.dart';

/// Acceso a la base de datos. Las pantallas no escriben SQL directamente.
class Repositorio {
  Repositorio(this._db);

  final Database _db;

  // ---------------------------------------------------------------- Cuentas

  /// Cuentas con su saldo actual calculado a partir de los movimientos.
  Future<List<CuentaConSaldo>> cuentasConSaldo({bool incluirArchivadas = false}) async {
    final filas = await _db.rawQuery('''
      SELECT c.*,
        c.saldo_inicial
        + COALESCE((SELECT SUM(CASE m.tipo WHEN 'ingreso' THEN m.monto ELSE -m.monto END)
                    FROM movimientos m WHERE m.cuenta_id = c.id), 0)
        + COALESCE((SELECT SUM(m.monto) FROM movimientos m
                    WHERE m.tipo = 'transferencia' AND m.cuenta_destino_id = c.id), 0)
        AS saldo_actual
      FROM cuentas c
      ${incluirArchivadas ? '' : 'WHERE c.archivada = 0'}
    ''');
    final lista = filas
        .map((f) => CuentaConSaldo(Cuenta.desdeMapa(f), (f['saldo_actual'] as int?) ?? 0))
        .toList();
    lista.sort((a, b) {
      final porTipo = a.cuenta.tipo.index.compareTo(b.cuenta.tipo.index);
      if (porTipo != 0) return porTipo;
      return a.cuenta.nombreCompleto
          .toLowerCase()
          .compareTo(b.cuenta.nombreCompleto.toLowerCase());
    });
    return lista;
  }

  Future<int> guardarCuenta(Cuenta cuenta) async {
    final mapa = cuenta.aMapa();
    final id = cuenta.id;
    if (id == null) {
      mapa.remove('id');
      return _db.insert('cuentas', mapa);
    }
    await _db.update('cuentas', mapa, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<bool> cuentaTieneMovimientos(int id) async {
    final r = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM movimientos WHERE cuenta_id = ? OR cuenta_destino_id = ?',
      [id, id],
    );
    return ((r.first['n'] as int?) ?? 0) > 0;
  }

  /// Si la cuenta ya tiene movimientos se archiva (para no perder historial);
  /// si no, se borra.
  Future<void> eliminarOArchivarCuenta(int id) async {
    if (await cuentaTieneMovimientos(id)) {
      await _db.update('cuentas', {'archivada': 1}, where: 'id = ?', whereArgs: [id]);
    } else {
      await _db.delete('cuentas', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ------------------------------------------------------------ Movimientos

  /// Movimientos que pertenecen a la semana presupuestal que empieza en
  /// [lunes] (incluye el sueldo y los fijos del domingo previo).
  Future<List<Movimiento>> movimientosDeSemana(DateTime lunes) async {
    final filas = await _db.query(
      'movimientos',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [fechaIso(sumarDias(lunes, -1)), fechaIso(sumarDias(lunes, 6))],
      orderBy: 'fecha DESC, id DESC',
    );
    return filas
        .map(Movimiento.desdeMapa)
        .where((m) => mismaFecha(m.semana, lunes))
        .toList();
  }

  Future<List<Movimiento>> ultimosMovimientos({int limite = 5}) async {
    final filas = await _db.query(
      'movimientos',
      orderBy: 'fecha DESC, id DESC',
      limit: limite,
    );
    return filas.map(Movimiento.desdeMapa).toList();
  }

  Future<int> guardarMovimiento(Movimiento movimiento) async {
    final mapa = movimiento.aMapa();
    final id = movimiento.id;
    if (id == null) {
      mapa.remove('id');
      return _db.insert('movimientos', mapa);
    }
    await _db.update('movimientos', mapa, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<void> eliminarMovimiento(int id) async {
    await _db.delete('movimientos', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------------- Gastos fijos

  Future<List<GastoFijo>> gastosFijos() async {
    final filas = await _db.query('gastos_fijos', orderBy: 'activo DESC, nombre COLLATE NOCASE');
    return filas.map(GastoFijo.desdeMapa).toList();
  }

  Future<int> guardarGastoFijo(GastoFijo gasto) async {
    final mapa = gasto.aMapa();
    final id = gasto.id;
    if (id == null) {
      mapa.remove('id');
      return _db.insert('gastos_fijos', mapa);
    }
    await _db.update('gastos_fijos', mapa, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<void> eliminarGastoFijo(int id) async {
    await _db.delete('gastos_fijos', where: 'id = ?', whereArgs: [id]);
  }
}
