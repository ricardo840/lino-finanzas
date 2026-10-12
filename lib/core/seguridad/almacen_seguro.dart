import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén de llave-valor protegido. En el teléfono usa el Keystore de Android;
/// en pruebas se sustituye por [AlmacenEnMemoria].
abstract class AlmacenSeguro {
  Future<String?> leer(String clave);
  Future<void> escribir(String clave, String valor);
  Future<void> borrar(String clave);
}

class AlmacenSeguroDispositivo implements AlmacenSeguro {
  AlmacenSeguroDispositivo()
      : _almacen = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leer(String clave) => _almacen.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) =>
      _almacen.write(key: clave, value: valor);

  @override
  Future<void> borrar(String clave) => _almacen.delete(key: clave);
}

class AlmacenEnMemoria implements AlmacenSeguro {
  final Map<String, String> datos = {};

  @override
  Future<String?> leer(String clave) async => datos[clave];

  @override
  Future<void> escribir(String clave, String valor) async {
    datos[clave] = valor;
  }

  @override
  Future<void> borrar(String clave) async {
    datos.remove(clave);
  }
}
