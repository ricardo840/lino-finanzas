import 'dart:convert';
import 'dart:math';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/seguridad/almacen_seguro.dart';

/// Abre la base SQLite cifrada con SQLCipher.
///
/// La llave es aleatoria (256 bits) y vive en el Keystore de Android. No se
/// deriva del PIN para que el desbloqueo con huella funcione y cambiar el PIN
/// no obligue a recifrar la base.
class BaseDatos {
  static const int version = 3;

  static const String _tablaComprasPlaneadas = '''
    CREATE TABLE compras_planeadas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      descripcion TEXT NOT NULL DEFAULT '',
      monto INTEGER NOT NULL CHECK (monto > 0),
      fecha TEXT NOT NULL,
      cuenta_id INTEGER REFERENCES cuentas(id) ON DELETE SET NULL,
      creada_en TEXT NOT NULL
    )
  ''';
  static const String _kLlave = 'bd_llave';
  static const String _archivo = 'lino.db';

  static Future<Database> abrir(AlmacenSeguro almacen) async {
    final llave = await _obtenerLlave(almacen);
    final directorio = await getDatabasesPath();
    return openDatabase(
      '$directorio/$_archivo',
      password: llave,
      version: version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) => _crearEsquema(db),
      onUpgrade: _migrar,
    );
  }

  static Future<String> _obtenerLlave(AlmacenSeguro almacen) async {
    final existente = await almacen.leer(_kLlave);
    if (existente != null) return existente;
    final azar = Random.secure();
    final bytes = List<int>.generate(32, (_) => azar.nextInt(256));
    final llave = base64UrlEncode(bytes);
    await almacen.escribir(_kLlave, llave);
    return llave;
  }

  static Future<void> _crearEsquema(Database db) async {
    final lote = db.batch();
    lote.execute('''
      CREATE TABLE cuentas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        banco TEXT NOT NULL DEFAULT '',
        tipo TEXT NOT NULL,
        saldo_inicial INTEGER NOT NULL DEFAULT 0,
        limite_credito INTEGER,
        dia_corte INTEGER,
        dia_pago INTEGER,
        periodo_dias INTEGER,
        ultimo_corte TEXT,
        plazo_pago_dias INTEGER,
        tasa_anual REAL,
        color INTEGER NOT NULL DEFAULT 0,
        archivada INTEGER NOT NULL DEFAULT 0,
        creada_en TEXT NOT NULL
      )
    ''');
    lote.execute('''
      CREATE TABLE gastos_fijos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto INTEGER NOT NULL CHECK (monto > 0),
        cuenta_id INTEGER REFERENCES cuentas(id) ON DELETE SET NULL,
        categoria TEXT NOT NULL,
        frecuencia TEXT NOT NULL DEFAULT 'semanal',
        dia_mes INTEGER,
        activo INTEGER NOT NULL DEFAULT 1
      )
    ''');
    lote.execute('''
      CREATE TABLE movimientos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        monto INTEGER NOT NULL CHECK (monto > 0),
        cuenta_id INTEGER NOT NULL REFERENCES cuentas(id) ON DELETE RESTRICT,
        cuenta_destino_id INTEGER REFERENCES cuentas(id) ON DELETE RESTRICT,
        categoria TEXT NOT NULL,
        descripcion TEXT NOT NULL DEFAULT '',
        fecha TEXT NOT NULL,
        es_sueldo INTEGER NOT NULL DEFAULT 0,
        es_fijo INTEGER NOT NULL DEFAULT 0,
        gasto_fijo_id INTEGER REFERENCES gastos_fijos(id) ON DELETE SET NULL,
        creado_en TEXT NOT NULL
      )
    ''');
    lote.execute(_tablaComprasPlaneadas);
    lote.execute('CREATE INDEX idx_movimientos_fecha ON movimientos(fecha)');
    lote.execute('CREATE INDEX idx_movimientos_cuenta ON movimientos(cuenta_id)');
    lote.execute('CREATE INDEX idx_movimientos_destino ON movimientos(cuenta_destino_id)');
    await lote.commit(noResult: true);
  }

  /// Migraciones: un `if (anterior < N)` por versión, en orden.
  static Future<void> _migrar(Database db, int anterior, int nueva) async {
    if (anterior < 2) {
      // Versión 2: ciclo de tarjeta medido en días y plazo de pago en días.
      await db.execute('ALTER TABLE cuentas ADD COLUMN periodo_dias INTEGER');
      await db.execute('ALTER TABLE cuentas ADD COLUMN ultimo_corte TEXT');
      await db.execute('ALTER TABLE cuentas ADD COLUMN plazo_pago_dias INTEGER');
    }
    if (anterior < 3) {
      // Versión 3: compras planeadas desde el simulador.
      await db.execute(_tablaComprasPlaneadas);
    }
  }
}
