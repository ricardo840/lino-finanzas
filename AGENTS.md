# Instrucciones para asistentes de código (Lino)

Antes de cambiar algo, lee `docs/PLAN.md`: ahí están las decisiones del
proyecto, las reglas de negocio y el estado actual.

## Reglas del proyecto
- App Flutter para Android con estilo **Cupertino**. No uses widgets de Material
  (`MaterialApp`, `Scaffold`, `ElevatedButton`, `Icons`...). Usa
  `CupertinoIcons` y los widgets de `lib/ui/widgets/`.
- **Nunca uses emojis**, ni en la interfaz ni en comentarios o textos.
- Dinero siempre en **centavos (int)**. Formatea con `formatoDinero()` y muestra
  montos con `MontoTexto` (respeta el modo privacidad).
- Fechas sin hora y aritmética con `lib/core/fechas.dart` (`sumarDias`,
  `lunesDe`, `semanaPresupuestal`). No sumes `Duration(days: n)` a fechas.
- Colores y tipografía solo desde el tema: `context.tema` (`LinoTema`). No
  pongas colores fijos en pantallas salvo sobre tarjetas con degradado.
- Paneles con `PanelVidrio`, botones con `BotonLino`, campos con `CampoVidrio`.
- Pestañas con `Shell` y `BarraIsla` (`lib/ui/widgets/barra_isla.dart`); no uses
  `CupertinoTabScaffold` ni `CupertinoTabBar`.
- No edites `android/` a mano: los ajustes van en `tool/configurar_android.dart`.
- En pruebas de widgets usa los dobles de `test/apoyo.dart`.
- Todo el SQL vive en `lib/data/repositorio.dart`. Cambios de esquema: sube
  `BaseDatos.version` y agrega la migración en `_migrar`.
- Escrituras desde la UI: `await ref.escribir((repo) => ...)`.
- La lógica de negocio va en `lib/dominio/` como funciones puras con pruebas en
  `test/`.
- Comentarios y nombres en español.
- Datos solo locales; no agregues servicios en la nube ni analíticas.

## Comandos (también están como tareas de VS Code)
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- Primera vez: tarea **Lino: preparar proyecto** (crea `android/`, instala
  dependencias, configura Android y genera el ícono).
