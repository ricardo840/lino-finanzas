// Dobles de prueba compartidos por las pruebas de widgets.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lino/core/seguridad/almacen_seguro.dart';
import 'package:lino/core/seguridad/servicio_auth.dart';
import 'package:lino/data/modelos/cuenta.dart';
import 'package:lino/data/modelos/gasto_fijo.dart';
import 'package:lino/data/modelos/movimiento.dart';
import 'package:lino/data/repositorio.dart';
import 'package:lino/estado/servicios.dart';
import 'package:local_auth/local_auth.dart';

/// Teléfono sin huella ni otra biometría.
class SinBiometria implements LocalAuthentication {
  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repositorio de una base recién creada: todo vacío.
class RepositorioVacio implements Repositorio {
  @override
  Future<List<CuentaConSaldo>> cuentasConSaldo({bool incluirArchivadas = false}) async => [];

  @override
  Future<List<Movimiento>> movimientosDeSemana(DateTime lunes) async => [];

  @override
  Future<List<Movimiento>> ultimosMovimientos({int limite = 5}) async => [];

  @override
  Future<List<GastoFijo>> gastosFijos() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Servicio de PIN para pruebas: sin biometría y con pocas iteraciones.
ServicioAuth servicioDePrueba(AlmacenSeguro almacen) =>
    ServicioAuth(almacen, biometria: SinBiometria(), iteraciones: 1000);

/// Sustituye el almacén seguro, la huella y la base de datos por dobles en
/// memoria.
List<Override> sustitutos(AlmacenSeguro almacen) => [
      almacenSeguroProvider.overrideWithValue(almacen),
      servicioAuthProvider.overrideWith((ref) => servicioDePrueba(almacen)),
      repositorioProvider.overrideWith((ref) async => RepositorioVacio()),
    ];
