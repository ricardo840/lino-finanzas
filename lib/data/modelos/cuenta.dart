import '../../core/fechas.dart';

/// true si el nombre sugiere dinero apartado ("Ahorro", "Cajita",
/// "Apartado"...), para proponer el tipo Ahorro al dar de alta la cuenta.
bool pareceCuentaDeAhorro(String nombre) =>
    RegExp('ahorr|cajita|apartado|inversi', caseSensitive: false).hasMatch(nombre);

/// Tipos de cuenta que maneja Lino.
enum TipoCuenta {
  debito('Débito'),
  credito('Crédito'),
  efectivo('Efectivo'),
  ahorro('Ahorro');

  const TipoCuenta(this.etiqueta);

  final String etiqueta;

  static TipoCuenta desdeNombre(String nombre) => TipoCuenta.values.firstWhere(
        (t) => t.name == nombre,
        orElse: () => TipoCuenta.debito,
      );
}

/// Cuenta bancaria, tarjeta de crédito, efectivo o ahorro.
///
/// Todos los montos van en centavos (int) para no arrastrar errores de
/// redondeo. En crédito el saldo es negativo cuando hay deuda.
class Cuenta {
  const Cuenta({
    this.id,
    required this.nombre,
    this.banco = '',
    required this.tipo,
    this.saldoInicial = 0,
    this.limiteCredito,
    this.diaCorte,
    this.diaPago,
    this.periodoDias,
    this.ultimoCorte,
    this.plazoPagoDias,
    this.tasaAnual,
    this.color = 0,
    this.archivada = false,
    required this.creadaEn,
  });

  final int? id;
  final String nombre;
  final String banco;
  final TipoCuenta tipo;

  /// Saldo con el que se dio de alta (en crédito: menos la deuda inicial).
  final int saldoInicial;

  /// Solo crédito.
  final int? limiteCredito;

  /// Solo crédito: día del mes del corte.
  final int? diaCorte;

  /// Solo crédito: día del mes de la fecha límite de pago.
  final int? diaPago;

  /// Solo crédito con ciclo por días: días que dura cada periodo de
  /// facturación (30 en la tarjeta Plata).
  final int? periodoDias;

  /// Solo crédito con ciclo por días: fecha de un corte conocido.
  final DateTime? ultimoCorte;

  /// Solo crédito: días para pagar después del corte. Si es null, la fecha
  /// límite es [diaPago].
  final int? plazoPagoDias;

  /// Solo ahorro: tasa fija anual en porcentaje (15.0 = 15 %).
  final double? tasaAnual;

  /// Índice en la paleta de colores de tarjetas.
  final int color;
  final bool archivada;
  final DateTime creadaEn;

  bool get esCredito => tipo == TipoCuenta.credito;

  /// Cuentas de las que sale dinero propio al pagar (débito o efectivo).
  bool get esLiquida => tipo == TipoCuenta.debito || tipo == TipoCuenta.efectivo;

  /// "Nu · Débito" o solo el nombre si no hay banco.
  String get nombreCompleto => banco.trim().isEmpty ? nombre : '$banco · $nombre';

  Map<String, Object?> aMapa() => {
        'id': id,
        'nombre': nombre,
        'banco': banco,
        'tipo': tipo.name,
        'saldo_inicial': saldoInicial,
        'limite_credito': limiteCredito,
        'dia_corte': diaCorte,
        'dia_pago': diaPago,
        'periodo_dias': periodoDias,
        'ultimo_corte': ultimoCorte == null ? null : fechaIso(ultimoCorte!),
        'plazo_pago_dias': plazoPagoDias,
        'tasa_anual': tasaAnual,
        'color': color,
        'archivada': archivada ? 1 : 0,
        'creada_en': creadaEn.toIso8601String(),
      };

  factory Cuenta.desdeMapa(Map<String, Object?> m) => Cuenta(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        banco: (m['banco'] as String?) ?? '',
        tipo: TipoCuenta.desdeNombre(m['tipo'] as String),
        saldoInicial: (m['saldo_inicial'] as int?) ?? 0,
        limiteCredito: m['limite_credito'] as int?,
        diaCorte: m['dia_corte'] as int?,
        diaPago: m['dia_pago'] as int?,
        periodoDias: m['periodo_dias'] as int?,
        ultimoCorte: DateTime.tryParse((m['ultimo_corte'] as String?) ?? ''),
        plazoPagoDias: m['plazo_pago_dias'] as int?,
        tasaAnual: (m['tasa_anual'] as num?)?.toDouble(),
        color: (m['color'] as int?) ?? 0,
        archivada: ((m['archivada'] as int?) ?? 0) == 1,
        creadaEn: DateTime.tryParse((m['creada_en'] as String?) ?? '') ?? DateTime.now(),
      );
}

/// Cuenta junto con su saldo calculado a partir de los movimientos.
class CuentaConSaldo {
  const CuentaConSaldo(this.cuenta, this.saldo);

  final Cuenta cuenta;

  /// Saldo actual en centavos. En crédito, negativo = deuda.
  final int saldo;

  int get deuda => cuenta.esCredito && saldo < 0 ? -saldo : 0;

  /// Crédito que todavía se puede usar (null si no se capturó el límite).
  int? get creditoDisponible {
    final limite = cuenta.limiteCredito;
    if (!cuenta.esCredito || limite == null) return null;
    return limite + saldo;
  }

  /// Rendimiento estimado en [dias] con la tasa fija de la cuenta de ahorro.
  int rendimientoEstimado(int dias) {
    final tasa = cuenta.tasaAnual;
    if (cuenta.tipo != TipoCuenta.ahorro || tasa == null || saldo <= 0) return 0;
    return (saldo * tasa / 100 * dias / 365).round();
  }
}
