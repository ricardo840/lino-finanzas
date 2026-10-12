import '../../core/fechas.dart';

enum TipoMovimiento {
  egreso('Gasto'),
  ingreso('Ingreso'),
  transferencia('Transferencia');

  const TipoMovimiento(this.etiqueta);

  final String etiqueta;

  static TipoMovimiento desdeNombre(String nombre) => TipoMovimiento.values.firstWhere(
        (t) => t.name == nombre,
        orElse: () => TipoMovimiento.egreso,
      );
}

/// Ingreso, gasto o transferencia entre cuentas (incluye pagos de tarjeta y
/// apartados al ahorro).
class Movimiento {
  const Movimiento({
    this.id,
    required this.tipo,
    required this.monto,
    required this.cuentaId,
    this.cuentaDestinoId,
    required this.categoria,
    this.descripcion = '',
    required this.fecha,
    this.esSueldo = false,
    this.esFijo = false,
    this.gastoFijoId,
    required this.creadoEn,
  });

  final int? id;
  final TipoMovimiento tipo;

  /// Siempre positivo, en centavos. El tipo define si suma o resta.
  final int monto;
  final int cuentaId;

  /// Solo transferencias.
  final int? cuentaDestinoId;
  final String categoria;
  final String descripcion;

  /// Fecha sin hora.
  final DateTime fecha;

  /// Ingreso marcado como el sueldo semanal.
  final bool esSueldo;

  /// Gasto marcado como fijo (internet, renta...).
  final bool esFijo;

  /// Plantilla de gasto fijo que lo generó, si aplica.
  final int? gastoFijoId;
  final DateTime creadoEn;

  /// Lunes de la semana presupuestal a la que pertenece.
  DateTime get semana => semanaPresupuestal(fecha, esSueldo: esSueldo, esFijo: esFijo);

  Map<String, Object?> aMapa() => {
        'id': id,
        'tipo': tipo.name,
        'monto': monto,
        'cuenta_id': cuentaId,
        'cuenta_destino_id': cuentaDestinoId,
        'categoria': categoria,
        'descripcion': descripcion,
        'fecha': fechaIso(fecha),
        'es_sueldo': esSueldo ? 1 : 0,
        'es_fijo': esFijo ? 1 : 0,
        'gasto_fijo_id': gastoFijoId,
        'creado_en': creadoEn.toIso8601String(),
      };

  factory Movimiento.desdeMapa(Map<String, Object?> m) => Movimiento(
        id: m['id'] as int?,
        tipo: TipoMovimiento.desdeNombre(m['tipo'] as String),
        monto: m['monto'] as int,
        cuentaId: m['cuenta_id'] as int,
        cuentaDestinoId: m['cuenta_destino_id'] as int?,
        categoria: (m['categoria'] as String?) ?? 'otros',
        descripcion: (m['descripcion'] as String?) ?? '',
        fecha: DateTime.parse(m['fecha'] as String),
        esSueldo: ((m['es_sueldo'] as int?) ?? 0) == 1,
        esFijo: ((m['es_fijo'] as int?) ?? 0) == 1,
        gastoFijoId: m['gasto_fijo_id'] as int?,
        creadoEn: DateTime.tryParse((m['creado_en'] as String?) ?? '') ?? DateTime.now(),
      );
}
