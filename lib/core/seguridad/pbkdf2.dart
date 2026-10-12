import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2 con HMAC-SHA256 (RFC 8018). Se usa para guardar el PIN como hash
/// con sal; nunca se guarda el PIN en claro.
Uint8List pbkdf2Sha256({
  required List<int> clave,
  required List<int> sal,
  required int iteraciones,
  int longitud = 32,
}) {
  if (iteraciones < 1) throw ArgumentError.value(iteraciones, 'iteraciones');
  final hmac = Hmac(sha256, clave);
  final salida = BytesBuilder(copy: false);
  var bloque = 1;
  while (salida.length < longitud) {
    final entrada = Uint8List(sal.length + 4)
      ..setRange(0, sal.length, sal)
      ..[sal.length] = (bloque >> 24) & 0xff
      ..[sal.length + 1] = (bloque >> 16) & 0xff
      ..[sal.length + 2] = (bloque >> 8) & 0xff
      ..[sal.length + 3] = bloque & 0xff;
    var u = hmac.convert(entrada).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iteraciones; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    salida.add(t);
    bloque++;
  }
  return Uint8List.sublistView(salida.toBytes(), 0, longitud);
}

/// Compara dos arreglos sin cortar en la primera diferencia, para no filtrar
/// información por tiempo de respuesta.
bool comparacionConstante(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diferencia = 0;
  for (var i = 0; i < a.length; i++) {
    diferencia |= a[i] ^ b[i];
  }
  return diferencia == 0;
}
