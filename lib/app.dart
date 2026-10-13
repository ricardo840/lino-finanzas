import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'estado/ajustes.dart';
import 'estado/auth.dart';
import 'ui/pantallas/auth/bloqueo_pantalla.dart';
import 'ui/pantallas/auth/carga_pantalla.dart';
import 'ui/pantallas/auth/crear_pin_pantalla.dart';
import 'ui/pantallas/shell.dart';
import 'ui/tema/lino_tema.dart';
import 'ui/widgets/fondo_lino.dart';

class LinoApp extends ConsumerStatefulWidget {
  const LinoApp({super.key});

  @override
  ConsumerState<LinoApp> createState() => _LinoAppState();
}

class _LinoAppState extends ConsumerState<LinoApp> with WidgetsBindingObserver {
  DateTime? _salioEn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Bloqueo automático: si la app estuvo en segundo plano más del tiempo
  /// configurado, al volver se pide PIN o huella.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final auth = ref.read(authProvider.notifier);
    if (auth.autenticandoBiometria) return;
    switch (estado) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _salioEn ??= DateTime.now();
      case AppLifecycleState.resumed:
        final salio = _salioEn;
        _salioEn = null;
        if (salio == null) return;
        final limite = ref.read(ajustesProvider).bloqueoSegundos;
        if (DateTime.now().difference(salio).inSeconds >= limite) auth.bloquear();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// El teléfono cambió entre modo claro y oscuro (para el tema automático).
  @override
  void didChangePlatformBrightness() {
    ref
        .read(brilloSistemaProvider.notifier)
        .fijar(WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(temaProvider);
    final fase = ref.watch(authProvider.select((a) => a.fase));
    final reducirDesenfoque = ref.watch(ajustesProvider.select((a) => a.reducirDesenfoque));
    final vibracion = ref.watch(ajustesProvider.select((a) => a.vibracion));
    // Con "Abrir con montos ocultos", cada bloqueo vuelve a ocultarlos.
    ref.listen<FaseAuth>(authProvider.select((a) => a.fase), (_, nueva) {
      if (nueva == FaseAuth.bloqueada && ref.read(ajustesProvider).ocultarAlAbrir) {
        ref.read(ajustesProvider.notifier).cambiarPrivacidad(true);
      }
    });

    return CupertinoApp(
      title: 'Lino',
      debugShowCheckedModeBanner: false,
      theme: tema.cupertino,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, navegador) => LinoTemaScope(
        tema: tema,
        reducirDesenfoque: reducirDesenfoque,
        vibracion: vibracion,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: (tema.esOscuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
            statusBarColor: const Color(0x00000000),
            systemNavigationBarColor: tema.fondo.last,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              navegador ?? const SizedBox.shrink(),
              // La capa de seguridad tapa todo, incluidas las rutas abiertas.
              if (fase != FaseAuth.desbloqueada) _CapaSeguridad(fase: fase),
            ],
          ),
        ),
      ),
      home: const _Raiz(),
    );
  }
}

/// La interfaz principal se construye hasta que se desbloquea por primera vez.
class _Raiz extends ConsumerWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iniciada = ref.watch(authProvider.select((a) => a.sesionIniciada));
    return iniciada ? const Shell() : const FondoLino(child: SizedBox.expand());
  }
}

class _CapaSeguridad extends StatelessWidget {
  const _CapaSeguridad({required this.fase});

  final FaseAuth fase;

  @override
  Widget build(BuildContext context) => switch (fase) {
        FaseAuth.cargando => const CargaPantalla(),
        FaseAuth.crearPin => const CrearPinPantalla(),
        FaseAuth.bloqueada => const BloqueoPantalla(),
        FaseAuth.desbloqueada => const SizedBox.shrink(),
      };
}
