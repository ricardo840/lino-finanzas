import '../../core/fechas.dart';

enum FrecuenciaFijo {
  semanal('Cada domingo'),
  mensual('Una vez al mes');

  const FrecuenciaFijo(this.etiqueta);

  final String etiqueta;

  static FrecuenciaFijo desdeNombre(String nombre) => FrecuenciaFijo.values.firstWhere(
        (f) => f.name == nombre,
        orElse: () => FrecuenciaFijo.semanal,
      );
}

/// Plantilla de un pago fijo (internet, renta, transporte...). Cada semana la
/// app muestra los que faltan por registrar.
class GastoFijo {
  const GastoFijo({
    this.id,
    required this.nombre,
    required this.monto,
    this.cuentaId,
    this.categoria = 'servicios',
    this.frecuencia = FrecuenciaFijo.semanal,
    this.diaMes,
    this.activo = true,
  });

  final int? id;
  final String nombre;

  /// Monto estimado en centavos.
  final int monto;

  /// Cuenta con la que se paga normalmente (opcional).
  final int? cuentaId;
  final String categoria;
  final FrecuenciaFijo frecuencia;

  /// Solo mensual: día del mes en que se paga.
  final int? diaMes;
  final bool activo;

  /// Fecha en la que toca pagarlo dentro de la semana presupuestal que empieza
  /// en [lunes], o null si no toca esa semana.
  ///
  /// Los semanales se pagan el domingo previo (día de sueldo). Los mensuales,
  /// el día que les toque entre ese domingo y el sábado.
  DateTime? fechaEnSemana(DateTime lunes) {
    if (frecuencia == FrecuenciaFijo.semanal) return sumarDias(lunes, -1);
    final dia = diaMes;
    if (dia == null) return null;
    for (var i = -1; i <= 5; i++) {
      final fecha = sumarDias(lunes, i);
      if (mismaFecha(fecha, fechaEnMes(fecha.year, fecha.month, dia))) return fecha;
    }
    return null;
  }

  Map<String, Object?> aMapa() => {
        'id': id,
        'nombre': nombre,
        'monto': monto,
        'cuenta_id': cuentaId,
        'categoria': categoria,
        'frecuencia': frecuencia.name,
        'dia_mes': diaMes,
        'activo': activo ? 1 : 0,
      };

  factory GastoFijo.desdeMapa(Map<String, Object?> m) => GastoFijo(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        monto: m['monto'] as int,
        cuentaId: m['cuenta_id'] as int?,
        categoria: (m['categoria'] as String?) ?? 'servicios',
        frecuencia: FrecuenciaFijo.desdeNombre((m['frecuencia'] as String?) ?? 'semanal'),
        diaMes: m['dia_mes'] as int?,
        activo: ((m['activo'] as int?) ?? 1) == 1,
      );
}
