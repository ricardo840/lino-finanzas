import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../../data/modelos/cuenta.dart';
import '../../data/modelos/movimiento.dart';
import '../../estado/datos.dart';
import '../categorias.dart';
import '../tema/contexto.dart';
import 'monto_texto.dart';
import 'vidrio.dart';

/// Encabezado de sección con acción opcional a la derecha.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion, this.alAccion});

  final String texto;
  final String? accion;
  final VoidCallback? alAccion;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Expanded(child: Text(texto, style: tema.subtitulo)),
          if (accion != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: alAccion,
              child: Text(accion!, style: tema.cuerpo.copyWith(color: tema.acento)),
            ),
        ],
      ),
    );
  }
}

/// Mensaje cuando una lista está vacía.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
    this.alAccion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? accion;
  final VoidCallback? alAccion;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return PanelVidrio(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      child: Column(
        children: [
          Icon(icono, size: 34, color: tema.acento),
          const SizedBox(height: 12),
          Text(titulo, style: tema.subtitulo, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(mensaje, style: tema.secundario, textAlign: TextAlign.center),
          if (accion != null) ...[
            const SizedBox(height: 18),
            BotonLino(texto: accion!, onPressed: alAccion),
          ],
        ],
      ),
    );
  }
}

class Cargando extends StatelessWidget {
  const Cargando({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CupertinoActivityIndicator()),
      );
}

class ErrorDatos extends StatelessWidget {
  const ErrorDatos(this.error, {super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return PanelVidrio(
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, color: tema.negativo),
          const SizedBox(width: 12),
          Expanded(
            child: Text('No se pudieron cargar los datos: $error', style: tema.secundario),
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso de vidrio.
class BarraProgreso extends StatelessWidget {
  const BarraProgreso({super.key, required this.valor, this.color, this.altura = 8});

  /// De 0 a 1 (se recorta).
  final double valor;
  final Color? color;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return ClipRRect(
      borderRadius: BorderRadius.circular(altura),
      child: Container(
        height: altura,
        color: tema.campo,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: valor.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(altura),
              color: color ?? tema.acento,
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de semana presupuestal (lunes a domingo).
class SelectorSemana extends ConsumerWidget {
  const SelectorSemana({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.tema;
    final lunes = ref.watch(semanaSeleccionadaProvider);
    final notificador = ref.read(semanaSeleccionadaProvider.notifier);
    final esActual = mismaFecha(lunes, semanaActual());
    return PanelVidrio(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      radio: 18,
      child: Row(
        children: [
          BotonIcono(icono: CupertinoIcons.chevron_left, tamano: 20, onPressed: notificador.anterior),
          Expanded(
            child: Presionable(
              onTap: esActual ? null : notificador.irAActual,
              child: Column(
                children: [
                  Text(
                    esActual ? 'ESTA SEMANA' : 'VOLVER A ESTA SEMANA',
                    style: tema.etiqueta.copyWith(
                      fontSize: 10,
                      color: esActual ? tema.textoSecundario : tema.acento,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(rangoSemana(lunes), style: tema.subtitulo),
                ],
              ),
            ),
          ),
          BotonIcono(icono: CupertinoIcons.chevron_right, tamano: 20, onPressed: notificador.siguiente),
        ],
      ),
    );
  }
}

/// Círculo con el icono de una categoría o cuenta.
class IconoCirculo extends StatelessWidget {
  const IconoCirculo({super.key, required this.icono, this.color, this.tamano = 38});

  final IconData icono;
  final Color? color;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final c = color ?? tema.acento;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withValues(alpha: 0.16),
        border: Border.all(color: c.withValues(alpha: 0.30)),
      ),
      child: Icon(icono, size: tamano * 0.5, color: c),
    );
  }
}

/// Renglón de un movimiento.
class FilaMovimiento extends StatelessWidget {
  const FilaMovimiento({
    super.key,
    required this.movimiento,
    required this.cuentas,
    this.onTap,
  });

  final Movimiento movimiento;
  final Map<int, Cuenta> cuentas;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final m = movimiento;
    final categoria = categoriaPorId(m.categoria);
    final origen = cuentas[m.cuentaId]?.nombreCompleto ?? 'Cuenta eliminada';

    final String titulo;
    final String detalle;
    final int montoConSigno;
    final Color colorIcono;
    switch (m.tipo) {
      case TipoMovimiento.ingreso:
        titulo = m.descripcion.isEmpty ? categoria.nombre : m.descripcion;
        detalle = m.esSueldo ? '$origen · Sueldo' : origen;
        montoConSigno = m.monto;
        colorIcono = tema.positivo;
      case TipoMovimiento.egreso:
        titulo = m.descripcion.isEmpty ? categoria.nombre : m.descripcion;
        detalle = m.esFijo ? '$origen · Fijo' : origen;
        montoConSigno = -m.monto;
        colorIcono = tema.acento;
      case TipoMovimiento.transferencia:
        final destino = cuentas[m.cuentaDestinoId]?.nombreCompleto ?? 'Cuenta eliminada';
        titulo = m.descripcion.isEmpty ? 'Transferencia' : m.descripcion;
        detalle = '$origen → $destino';
        montoConSigno = m.monto;
        colorIcono = tema.textoSecundario;
    }

    return Presionable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconoCirculo(icono: categoria.icono, color: colorIcono),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tema.cuerpo, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(detalle, style: tema.secundario, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MontoTexto(
              montoConSigno,
              estilo: tema.monto.copyWith(fontSize: 15),
              colorear: m.tipo == TipoMovimiento.ingreso,
              signo: m.tipo == TipoMovimiento.ingreso,
              color: m.tipo == TipoMovimiento.transferencia ? tema.textoSecundario : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de día en listas de movimientos: "Domingo 12 de octubre".
class EncabezadoDia extends StatelessWidget {
  const EncabezadoDia(this.fecha, {super.key});

  final DateTime fecha;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(capitalizar(fechaMedia(fecha)), style: context.tema.etiqueta),
      );
}
