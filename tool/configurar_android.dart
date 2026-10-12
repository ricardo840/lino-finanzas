// Ajustes de Android que Lino necesita después de `flutter create`.
//
// Uso (desde la raíz del proyecto):  dart run tool/configurar_android.dart
// Es idempotente: se puede correr varias veces.
import 'dart:io';

/// Reglas de Android 12 o posterior: nada se copia a la nube ni se traspasa a
/// otro teléfono.
const _reglasRespaldo = '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Lino guarda todo solo en el teléfono: nada se copia a la nube ni se
     traspasa a otro dispositivo. -->
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
        <exclude domain="external" path="." />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
        <exclude domain="external" path="." />
    </device-transfer>
</data-extraction-rules>
''';

void main() {
  final manifiesto = File('android/app/src/main/AndroidManifest.xml');
  if (!manifiesto.existsSync()) {
    stderr.writeln('No existe la carpeta android/. Ejecuta primero la tarea '
        '"Lino: 1. Crear plataforma Android".');
    exitCode = 1;
    return;
  }

  var cambios = 0;

  // 1. local_auth necesita FlutterFragmentActivity.
  for (final ruta in ['android/app/src/main/kotlin', 'android/app/src/main/java']) {
    final carpeta = Directory(ruta);
    if (!carpeta.existsSync()) continue;
    for (final archivo in carpeta.listSync(recursive: true).whereType<File>()) {
      final nombre = archivo.uri.pathSegments.last;
      if (nombre != 'MainActivity.kt' && nombre != 'MainActivity.java') continue;
      final texto = archivo.readAsStringSync();
      if (texto.contains('FlutterFragmentActivity')) continue;
      archivo.writeAsStringSync(texto.replaceAll('FlutterActivity', 'FlutterFragmentActivity'));
      stdout.writeln('MainActivity ahora usa FlutterFragmentActivity.');
      cambios++;
    }
  }

  // 2. Permiso de biometría, nombre visible de la app y datos sin respaldo.
  var texto = manifiesto.readAsStringSync();
  final original = texto;
  if (!texto.contains('android.permission.USE_BIOMETRIC')) {
    texto = texto.replaceFirst(
      RegExp(r'\s*<application'),
      '\n    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n\n    <application',
    );
  }
  texto = texto.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Lino"');
  // Los datos son solo locales: sin copia en la nube de Android ni traspaso a
  // otro teléfono. Además la llave de la base vive en el Keystore y no viaja
  // en los respaldos, así que una base restaurada no se podría abrir.
  texto = _atributoDeAplicacion(texto, 'android:allowBackup', 'false');
  texto = _atributoDeAplicacion(texto, 'android:dataExtractionRules', '@xml/reglas_respaldo');
  if (texto != original) {
    manifiesto.writeAsStringSync(texto);
    stdout.writeln('AndroidManifest: permiso USE_BIOMETRIC, nombre "Lino" y sin respaldos.');
    cambios++;
  }
  final reglas = File('android/app/src/main/res/xml/reglas_respaldo.xml');
  if (!reglas.existsSync() || reglas.readAsStringSync() != _reglasRespaldo) {
    reglas.parent.createSync(recursive: true);
    reglas.writeAsStringSync(_reglasRespaldo);
    stdout.writeln('${reglas.path}: datos excluidos de la nube y del traspaso.');
    cambios++;
  }

  // 3. minSdk 24 (Android 7.0+), requerido por las librerías de seguridad.
  for (final ruta in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final archivo = File(ruta);
    if (!archivo.existsSync()) continue;
    final actual = archivo.readAsStringSync();
    final nuevo = actual
        .replaceAll(RegExp(r'minSdk\s*=\s*flutter\.minSdkVersion'), 'minSdk = 24')
        .replaceAll(RegExp(r'minSdkVersion\s+flutter\.minSdkVersion'), 'minSdkVersion 24');
    if (nuevo != actual) {
      archivo.writeAsStringSync(nuevo);
      stdout.writeln('$ruta: minSdk = 24.');
      cambios++;
    }
  }

  // 4. local_auth: en Android 8 y anteriores el diálogo de huella se cierra con
  //    error si el tema de arranque no hereda de Theme.AppCompat.
  for (final ruta in [
    'android/app/src/main/res/values/styles.xml',
    'android/app/src/main/res/values-night/styles.xml',
  ]) {
    final archivo = File(ruta);
    if (!archivo.existsSync()) continue;
    final actual = archivo.readAsStringSync();
    final nuevo = actual.replaceFirst(
      RegExp(r'<style name="LaunchTheme" parent="[^"]*">'),
      '<style name="LaunchTheme" parent="Theme.AppCompat.DayNight">',
    );
    if (nuevo != actual) {
      archivo.writeAsStringSync(nuevo);
      stdout.writeln('$ruta: LaunchTheme hereda de Theme.AppCompat.DayNight.');
      cambios++;
    }
  }

  stdout.writeln(cambios == 0
      ? 'Android ya estaba configurado.'
      : 'Android configurado ($cambios cambios).');
}

/// Pone (o corrige) un atributo en la etiqueta `<application>` del manifiesto.
String _atributoDeAplicacion(String manifiesto, String nombre, String valor) {
  final existente = RegExp('$nombre="[^"]*"');
  if (existente.hasMatch(manifiesto)) {
    return manifiesto.replaceFirst(existente, '$nombre="$valor"');
  }
  return manifiesto.replaceFirst(
    RegExp(r'<application(?=\s)'),
    '<application\n        $nombre="$valor"',
  );
}
