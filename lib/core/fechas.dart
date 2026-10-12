// Aritmética de fechas sin horas.
//
// Todas las funciones trabajan con fechas "puras" (medianoche local) y usan el
// constructor de DateTime para sumar días, así no se rompen con el horario de
// verano (Matamoros sí lo aplica).

/// Quita la hora y deja solo año, mes y día.
DateTime soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

/// Suma (o resta) días respetando el calendario.
DateTime sumarDias(DateTime fecha, int dias) =>
    DateTime(fecha.year, fecha.month, fecha.day + dias);

/// Días naturales entre dos fechas (puede ser negativo).
int diasEntre(DateTime desde, DateTime hasta) {
  final a = DateTime.utc(desde.year, desde.month, desde.day);
  final b = DateTime.utc(hasta.year, hasta.month, hasta.day);
  return b.difference(a).inDays;
}

bool mismaFecha(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Cantidad de días del mes (el mes puede venir "desbordado", p. ej. 13).
int diasEnMes(int anio, int mes) => DateTime(anio, mes + 1, 0).day;

/// Fecha con el día pedido dentro del mes; si el mes es más corto se usa su
/// último día (un corte el 31 cae el 28/29 en febrero).
DateTime fechaEnMes(int anio, int mes, int dia) {
  final base = DateTime(anio, mes);
  final ultimo = diasEnMes(base.year, base.month);
  return DateTime(base.year, base.month, dia.clamp(1, ultimo));
}

/// Lunes de la semana (lunes a domingo) que contiene la fecha.
DateTime lunesDe(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day - (fecha.weekday - DateTime.monday));

/// Semana presupuestal a la que pertenece un movimiento.
///
/// La semana va de lunes a domingo, pero el sueldo llega en domingo y financia
/// la semana que empieza al día siguiente. Por eso el sueldo y los pagos fijos
/// registrados en domingo se cuentan en la semana siguiente; cualquier otro
/// movimiento se queda en su semana natural.
DateTime semanaPresupuestal(
  DateTime fecha, {
  required bool esSueldo,
  required bool esFijo,
}) {
  final lunes = lunesDe(fecha);
  if (fecha.weekday == DateTime.sunday && (esSueldo || esFijo)) {
    return sumarDias(lunes, 7);
  }
  return lunes;
}

/// Semana que la app muestra como "actual": en domingo ya es la que empieza
/// mañana, porque el sueldo de hoy la financia.
DateTime semanaActual([DateTime? hoy]) =>
    semanaPresupuestal(hoy ?? DateTime.now(), esSueldo: true, esFijo: false);

/// Domingos (días de sueldo) después de [desdeExclusivo] y hasta
/// [hastaInclusivo].
int domingosEntre(DateTime desdeExclusivo, DateTime hastaInclusivo) {
  var cuenta = 0;
  var dia = sumarDias(soloFecha(desdeExclusivo), 1);
  final fin = soloFecha(hastaInclusivo);
  while (!dia.isAfter(fin)) {
    if (dia.weekday == DateTime.sunday) cuenta++;
    dia = sumarDias(dia, 1);
  }
  return cuenta;
}

/// Formato ISO yyyy-MM-dd, el que se guarda en la base de datos.
String fechaIso(DateTime fecha) {
  final a = fecha.year.toString().padLeft(4, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  final d = fecha.day.toString().padLeft(2, '0');
  return '$a-$m-$d';
}
