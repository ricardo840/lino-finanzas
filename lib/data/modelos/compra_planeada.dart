import '../../core/fechas.dart';

/// Compra que se piensa hacer. Sale del simulador y se ve en el calendario
/// hasta que se registra como movimiento o se descarta.
class CompraPlaneada {
  const CompraPlaneada({
    this.id,
    this.descripcion = '',
    required this.monto,
    required this.fecha,
    this.cuentaId,
    required this.creadaEn,
  });

  final int? id;
  final String descripcion;

  /// En centavos.
  final int monto;

  /// Día en que conviene hacerla (sin hora).
  final DateTime fecha;

  /// Cuenta o tarjeta recomendada para pagarla.
  final int? cuentaId;
  final DateTime creadaEn;

  String get titulo => descripcion.isEmpty ? 'Compra planeada' : descripcion;

  Map<String, Object?> aMapa() => {
        'id': id,
        'descripcion': descripcion,
        'monto': monto,
        'fecha': fechaIso(fecha),
        'cuenta_id': cuentaId,
        'creada_en': creadaEn.toIso8601String(),
      };

  factory CompraPlaneada.desdeMapa(Map<String, Object?> m) => CompraPlaneada(
        id: m['id'] as int?,
        descripcion: (m['descripcion'] as String?) ?? '',
        monto: m['monto'] as int,
        fecha: DateTime.parse(m['fecha'] as String),
        cuentaId: m['cuenta_id'] as int?,
        creadaEn: DateTime.tryParse((m['creada_en'] as String?) ?? '') ?? DateTime.now(),
      );
}
