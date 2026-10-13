import '../core/fechas.dart';
import '../data/modelos/cuenta.dart';
import '../data/modelos/gasto_fijo.dart';
import 'ciclo_tarjeta.dart';

/// Qué marca un día en el calendario.
enum TipoEvento { sueldo, corte, limitePago, gastoFijo }

class EventoCalendario {
  const EventoCalendario({
    required this.fecha,
    required this.tipo,
    required this.titulo,
    this.detalle = '',
    this.monto,
    this.cuenta,
  });

  final DateTime fecha;
  final TipoEvento tipo;
  final String titulo;
  final String detalle;

  /// En centavos; null cuando no se conoce (un corte, un sueldo sin monto
  /// habitual...).
  final int? monto;

  /// Tarjeta del corte o del pago.
  final Cuenta? cuenta;
}

/// Días que muestra la cuadrícula de un mes: semanas completas de lunes a
/// domingo, con los días vecinos necesarios de los meses de al lado.
List<DateTime> diasDeCuadricula(int anio, int mes) {
  final primero = DateTime(anio, mes);
  final inicio = lunesDe(primero);
  final ultimo = DateTime(anio, mes, diasEnMes(anio, mes));
  final fin = sumarDias(lunesDe(ultimo), 6);
  return [
    for (var dia = inicio; !dia.isAfter(fin); dia = sumarDias(dia, 1)) dia,
  ];
}

/// Eventos de un mes: domingos de sueldo, cortes y fechas límite de cada
/// tarjeta y gastos fijos activos, ordenados por fecha.
///
/// El pago de una tarjeta lleva monto solo cuando es su próxima fecha límite
/// (con [hoy]) y tiene deuda; el sueldo, cuando se conoce el [sueldoHabitual].
List<EventoCalendario> eventosDelMes({
  required int anio,
  required int mes,
  required List<CuentaConSaldo> cuentas,
  required List<GastoFijo> gastosFijos,
  DateTime? hoy,
  int sueldoHabitual = 0,
}) {
  final primero = DateTime(anio, mes);
  final ultimo = DateTime(anio, mes, diasEnMes(anio, mes));
  bool delMes(DateTime f) => !f.isBefore(primero) && !f.isAfter(ultimo);

  final eventos = <EventoCalendario>[];
  final fijosSemanales = gastosFijos.where((g) => g.activo && g.frecuencia == FrecuenciaFijo.semanal);

  for (var dia = primero; !dia.isAfter(ultimo); dia = sumarDias(dia, 1)) {
    if (dia.weekday != DateTime.sunday) continue;
    eventos.add(EventoCalendario(
      fecha: dia,
      tipo: TipoEvento.sueldo,
      titulo: 'Sueldo',
      detalle: 'Financia la semana que empieza',
      monto: sueldoHabitual > 0 ? sueldoHabitual : null,
    ));
    for (final gasto in fijosSemanales) {
      eventos.add(EventoCalendario(
        fecha: dia,
        tipo: TipoEvento.gastoFijo,
        titulo: gasto.nombre,
        detalle: 'Gasto fijo de cada domingo',
        monto: gasto.monto,
      ));
    }
  }

  for (final gasto in gastosFijos) {
    final dia = gasto.diaMes;
    if (!gasto.activo || gasto.frecuencia != FrecuenciaFijo.mensual || dia == null) continue;
    eventos.add(EventoCalendario(
      fecha: fechaEnMes(anio, mes, dia),
      tipo: TipoEvento.gastoFijo,
      titulo: gasto.nombre,
      detalle: 'Gasto fijo del mes',
      monto: gasto.monto,
    ));
  }

  for (final tarjeta in cuentas) {
    final ciclo = cicloDe(tarjeta.cuenta);
    if (ciclo == null) continue;
    final nombre = tarjeta.cuenta.nombreCompleto;
    final proximoLimite = hoy == null ? null : ciclo.proximaFechaLimite(hoy);
    // Se empieza antes del mes: el pago de un corte anterior puede caer aquí.
    var corte = ciclo.proximoCorte(sumarDias(primero, -92));
    while (!corte.isAfter(ultimo)) {
      if (delMes(corte)) {
        eventos.add(EventoCalendario(
          fecha: corte,
          tipo: TipoEvento.corte,
          titulo: 'Corte de $nombre',
          detalle: 'Lo que compres después entra al siguiente periodo',
          cuenta: tarjeta.cuenta,
        ));
      }
      final limite = ciclo.fechaLimitePago(corte);
      if (delMes(limite)) {
        final esElProximo = proximoLimite != null && mismaFecha(limite, proximoLimite);
        eventos.add(EventoCalendario(
          fecha: limite,
          tipo: TipoEvento.limitePago,
          titulo: 'Pago de $nombre',
          detalle: 'Fecha límite para pagar sin intereses',
          monto: esElProximo && tarjeta.deuda > 0 ? tarjeta.deuda : null,
          cuenta: tarjeta.cuenta,
        ));
      }
      corte = ciclo.proximoCorte(sumarDias(corte, 1));
    }
  }

  eventos.sort((a, b) {
    final porFecha = a.fecha.compareTo(b.fecha);
    return porFecha != 0 ? porFecha : a.tipo.index.compareTo(b.tipo.index);
  });
  return eventos;
}
