import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formato.dart';
import '../../../data/modelos/cuenta.dart';
import '../../../estado/ajustes.dart';
import '../../../estado/auth.dart';
import '../../../estado/datos.dart';
import '../../../estado/servicios.dart';
import '../../tema/contexto.dart';
import '../../widgets/campos.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/logo_lino.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';
import '../auth/cambiar_pin_pantalla.dart';
import 'gastos_fijos_pantalla.dart';
import 'temas_pantalla.dart';

const _opcionesBloqueo = {0: 'Inmediato', 30: '30 segundos', 60: '1 minuto', 300: '5 minutos'};

class AjustesPantalla extends ConsumerWidget {
  const AjustesPantalla({super.key});

  Future<void> _cambiarHuella(BuildContext context, WidgetRef ref, bool activar) async {
    if (!activar) {
      await ref.read(ajustesProvider.notifier).cambiarHuella(false);
      return;
    }
    // Se confirma con la huella antes de activarla.
    final ok = await ref.read(servicioAuthProvider).autenticarConBiometria();
    if (ok) {
      await ref.read(ajustesProvider.notifier).cambiarHuella(true);
    } else if (context.mounted) {
      await avisar(context, titulo: 'No se activó', mensaje: 'No se pudo verificar tu huella.');
    }
  }

  Future<void> _cambiarBloqueo(BuildContext context, WidgetRef ref, int actual) async {
    final segundos = await elegirOpcion<int>(
      context,
      titulo: 'Bloquear al salir de la app',
      mensaje: 'Tiempo en segundo plano antes de volver a pedir PIN o huella.',
      opciones: [
        for (final e in _opcionesBloqueo.entries) Opcion(e.key, e.value, seleccionada: e.key == actual),
      ],
    );
    if (segundos != null) await ref.read(ajustesProvider.notifier).cambiarBloqueo(segundos);
  }

  Future<void> _cambiarCuenta(
    BuildContext context,
    WidgetRef ref,
    List<CuentaConSaldo> cuentas,
    int? actual,
  ) async {
    final elegida = await elegirOpcion<int>(
      context,
      titulo: 'Cuenta predeterminada',
      mensaje: 'Es la que se propone al registrar un movimiento.',
      opciones: [
        Opcion(-1, 'Ninguna', seleccionada: actual == null),
        for (final c in cuentas)
          Opcion(c.cuenta.id!, c.cuenta.nombreCompleto, seleccionada: c.cuenta.id == actual),
      ],
    );
    if (elegida == null) return;
    await ref.read(ajustesProvider.notifier).cambiarCuentaPredeterminada(elegida < 0 ? null : elegida);
  }

  Future<void> _cambiarSueldo(BuildContext context, WidgetRef ref, int actual) async {
    final centavos = await pedirMonto(
      context,
      titulo: 'Sueldo habitual',
      mensaje: 'Lo que recibes normalmente cada domingo. Sirve para estimar en el '
          'calendario y el simulador; no cambia tu presupuesto.',
      inicial: actual,
    );
    if (centavos != null) await ref.read(ajustesProvider.notifier).cambiarSueldoHabitual(centavos);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.tema;
    final ajustes = ref.watch(ajustesProvider);
    final biometria = ref.watch(authProvider.select((a) => a.biometriaDisponible));
    final cuentas = ref.watch(cuentasProvider).valueOrNull ?? const <CuentaConSaldo>[];
    final ajustesNotifier = ref.read(ajustesProvider.notifier);

    String nombreCuenta() {
      for (final c in cuentas) {
        if (c.cuenta.id == ajustes.cuentaPredeterminadaId) return c.cuenta.nombreCompleto;
      }
      return 'Ninguna';
    }

    final sueldo = ajustes.sueldoHabitual <= 0
        ? 'Sin definir'
        : (ajustes.privacidad ? '\$ •••••' : formatoDinero(ajustes.sueldoHabitual, conCentavos: false));

    return PaginaPestana(
      titulo: 'Ajustes',
      hijos: [
        const Etiqueta('Apariencia'),
        GrupoFilas(
          filas: [
            FilaSelector(
              etiqueta: 'Tema',
              valor: ajustes.temaAutomatico ? 'Automático' : tema.nombre,
              icono: CupertinoIcons.paintbrush,
              onTap: () => abrirPantalla<void>(context, const TemasPantalla()),
            ),
            FilaInterruptor(
              etiqueta: 'Reducir desenfoque',
              descripcion: 'Quita el efecto de vidrio esmerilado. Ayuda en teléfonos lentos.',
              icono: CupertinoIcons.drop,
              valor: ajustes.reducirDesenfoque,
              onChanged: ajustesNotifier.cambiarReducirDesenfoque,
            ),
            FilaInterruptor(
              etiqueta: 'Vibración al tocar',
              descripcion: 'En el teclado del PIN y las pestañas.',
              icono: CupertinoIcons.dot_radiowaves_left_right,
              valor: ajustes.vibracion,
              onChanged: ajustesNotifier.cambiarVibracion,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Etiqueta('Privacidad'),
        GrupoFilas(
          filas: [
            FilaInterruptor(
              etiqueta: 'Modo privacidad',
              descripcion: 'Oculta los montos en todas las pantallas.',
              icono: CupertinoIcons.eye_slash,
              valor: ajustes.privacidad,
              onChanged: ajustesNotifier.cambiarPrivacidad,
            ),
            FilaInterruptor(
              etiqueta: 'Abrir con montos ocultos',
              descripcion: 'Activa el modo privacidad cada vez que la app se abre o se bloquea.',
              icono: CupertinoIcons.eye_slash_fill,
              valor: ajustes.ocultarAlAbrir,
              onChanged: ajustesNotifier.cambiarOcultarAlAbrir,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Etiqueta('Seguridad'),
        GrupoFilas(
          filas: [
            FilaInterruptor(
              etiqueta: 'Desbloqueo con huella',
              descripcion: biometria
                  ? 'El PIN sigue funcionando como respaldo.'
                  : 'Este teléfono no tiene huella registrada.',
              icono: CupertinoIcons.lock_shield,
              valor: ajustes.huellaActiva && biometria,
              onChanged: biometria ? (v) => _cambiarHuella(context, ref, v) : null,
            ),
            FilaSelector(
              etiqueta: 'Bloqueo automático',
              valor: _opcionesBloqueo[ajustes.bloqueoSegundos] ?? '${ajustes.bloqueoSegundos} s',
              icono: CupertinoIcons.timer,
              onTap: () => _cambiarBloqueo(context, ref, ajustes.bloqueoSegundos),
            ),
            FilaSelector(
              etiqueta: 'Cambiar PIN',
              valor: '',
              icono: CupertinoIcons.lock,
              onTap: () => abrirPantalla<void>(context, const CambiarPinPantalla()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Etiqueta('Finanzas'),
        GrupoFilas(
          filas: [
            FilaSelector(
              etiqueta: 'Gastos fijos',
              valor: '',
              icono: CupertinoIcons.pin,
              onTap: () => abrirPantalla<void>(context, const GastosFijosPantalla()),
            ),
            FilaSelector(
              etiqueta: 'Cuenta predeterminada',
              valor: nombreCuenta(),
              icono: CupertinoIcons.creditcard,
              onTap: () => _cambiarCuenta(context, ref, cuentas, ajustes.cuentaPredeterminadaId),
            ),
            FilaSelector(
              etiqueta: 'Sueldo habitual',
              valor: sueldo,
              icono: CupertinoIcons.briefcase,
              onTap: () => _cambiarSueldo(context, ref, ajustes.sueldoHabitual),
            ),
          ],
        ),
        const SizedBox(height: 28),
        BotonLino(
          texto: 'Bloquear ahora',
          icono: CupertinoIcons.lock_fill,
          estilo: EstiloBoton.secundario,
          onPressed: () => ref.read(authProvider.notifier).bloquear(),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              const LogoLino(tamano: 44),
              const SizedBox(height: 10),
              Text('Lino 0.1.0', style: tema.subtitulo),
              const SizedBox(height: 4),
              Text(
                'Tus datos viven solo en este teléfono, cifrados.',
                style: tema.secundario,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
