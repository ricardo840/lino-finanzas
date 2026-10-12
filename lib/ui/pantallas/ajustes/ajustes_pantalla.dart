import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../estado/ajustes.dart';
import '../../../estado/auth.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.tema;
    final ajustes = ref.watch(ajustesProvider);
    final biometria = ref.watch(authProvider.select((a) => a.biometriaDisponible));

    return PaginaPestana(
      titulo: 'Ajustes',
      hijos: [
        const Etiqueta('Apariencia'),
        GrupoFilas(
          filas: [
            FilaSelector(
              etiqueta: 'Tema',
              valor: tema.nombre,
              icono: CupertinoIcons.paintbrush,
              onTap: () => abrirPantalla<void>(context, const TemasPantalla()),
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
              onChanged: (v) => ref.read(ajustesProvider.notifier).cambiarPrivacidad(v),
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
