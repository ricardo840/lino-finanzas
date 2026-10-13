// Formato de dinero y fechas en español de México, sin depender de intl.

const List<String> mesesLargos = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', //
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

const List<String> mesesCortos = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const List<String> diasSemana = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

/// Convierte centavos a texto: 123456 -> "$1,234.56".
String formatoDinero(
  int centavos, {
  bool conCentavos = true,
  bool signoMas = false,
}) {
  final negativo = centavos < 0;
  final absoluto = centavos.abs();
  final pesos = absoluto ~/ 100;
  final resto = absoluto % 100;

  final miles = _agruparMiles(pesos.toString());

  final base = conCentavos
      ? '\$$miles.${resto.toString().padLeft(2, '0')}'
      : '\$$miles';
  if (negativo) return '-$base';
  if (signoMas && centavos > 0) return '+$base';
  return base;
}

/// Lee un monto escrito por el usuario ("1,234.5", "$80") y lo regresa en
/// centavos. Regresa null si el texto no es un monto válido.
int? parsearDinero(String texto) {
  final limpio = texto.replaceAll(RegExp(r'[\s,$]'), '');
  if (limpio.isEmpty) return null;
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(limpio)) return null;
  final partes = limpio.split('.');
  final pesos = int.parse(partes[0]);
  var centavos = 0;
  if (partes.length > 1 && partes[1].isNotEmpty) {
    centavos = int.parse(partes[1].padRight(2, '0'));
  }
  return pesos * 100 + centavos;
}

/// Centavos a texto editable sin símbolo: 123450 -> "1,234.50".
String montoEditable(int centavos) {
  final pesos = _agruparMiles('${centavos ~/ 100}');
  final resto = centavos % 100;
  return resto == 0 ? pesos : '$pesos.${resto.toString().padLeft(2, '0')}';
}

/// Da formato a un monto mientras se escribe: deja solo dígitos y un punto,
/// máximo dos decimales, y agrupa los miles con coma
/// ("1234567.5" -> "1,234,567.5").
String formatearMontoEscrito(String texto) {
  final limpio = texto.replaceAll(RegExp(r'[^0-9.]'), '');
  if (limpio.isEmpty) return '';
  final punto = limpio.indexOf('.');
  var enteros = punto < 0 ? limpio : limpio.substring(0, punto);
  // Sin ceros a la izquierda; ".5" se completa como "0.5".
  enteros = enteros.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (enteros.isEmpty) enteros = '0';
  final miles = _agruparMiles(enteros);
  if (punto < 0) return miles;
  var decimales = limpio.substring(punto + 1).replaceAll('.', '');
  if (decimales.length > 2) decimales = decimales.substring(0, 2);
  return '$miles.$decimales';
}

/// "1234567" -> "1,234,567".
String _agruparMiles(String digitos) {
  final miles = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    miles.write(digitos[i]);
    final restantes = digitos.length - i - 1;
    if (restantes > 0 && restantes % 3 == 0) miles.write(',');
  }
  return miles.toString();
}

/// "12 oct"
String fechaCorta(DateTime f) => '${f.day} ${mesesCortos[f.month - 1]}';

/// "domingo 12 de octubre"
String fechaMedia(DateTime f) =>
    '${diasSemana[f.weekday - 1]} ${f.day} de ${mesesLargos[f.month - 1]}';

/// "12 oct 2026"
String fechaConAnio(DateTime f) => '${fechaCorta(f)} ${f.year}';

/// "6 – 12 oct" o "29 sep – 5 oct"
String rangoSemana(DateTime lunes) {
  final domingo = DateTime(lunes.year, lunes.month, lunes.day + 6);
  if (lunes.month == domingo.month) {
    return '${lunes.day} – ${domingo.day} ${mesesCortos[domingo.month - 1]}';
  }
  return '${fechaCorta(lunes)} – ${fechaCorta(domingo)}';
}

String capitalizar(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

/// "1 sueldo", "3 sueldos"
String plural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';

/// 15.0 -> "15%", 10.5 -> "10.5%"
String porcentaje(double valor) {
  final entero = valor == valor.roundToDouble();
  return '${valor.toStringAsFixed(entero ? 0 : 1)}%';
}
