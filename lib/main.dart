import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/seguridad/almacen_seguro.dart';
import 'estado/ajustes.dart';
import 'estado/servicios.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Se leen los ajustes antes de arrancar para pintar el tema correcto desde
  // el primer cuadro.
  final almacen = AlmacenSeguroDispositivo();
  final ajustes = await AlmacenAjustes(almacen).cargar();

  runApp(
    ProviderScope(
      overrides: [
        almacenSeguroProvider.overrideWithValue(almacen),
        ajustesInicialesProvider.overrideWithValue(ajustes),
      ],
      child: const LinoApp(),
    ),
  );
}
