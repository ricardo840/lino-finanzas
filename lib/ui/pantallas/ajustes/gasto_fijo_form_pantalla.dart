import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formato.dart';
import '../../../data/modelos/gasto_fijo.dart';
import '../../../estado/datos.dart';
import '../../categorias.dart';
import '../../tema/contexto.dart';
import '../../widgets/campos.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';

class GastoFijoFormPantalla extends ConsumerStatefulWidget {
  const GastoFijoFormPantalla({super.key, this.existente});

  final GastoFijo? existente;

  @override
  ConsumerState<GastoFijoFormPantalla> createState() => _GastoFijoFormPantallaState();
}

class _GastoFijoFormPantallaState extends ConsumerState<GastoFijoFormPantalla> {
  late final TextEditingController _nombre;
  late final TextEditingController _monto;
  int? _cuentaId;
  late String _categoria;
  late FrecuenciaFijo _frecuencia;
  int? _diaMes;
  late bool _activo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existente;
    _nombre = TextEditingController(text: g?.nombre ?? '');
    _monto = TextEditingController(text: g == null ? '' : montoEditable(g.monto));
    _cuentaId = g?.cuentaId;
    _categoria = g?.categoria ?? 'servicios';
    _frecuencia = g?.frecuencia ?? FrecuenciaFijo.semanal;
    _diaMes = g?.diaMes;
    _activo = g?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final monto = parsearDinero(_monto.text);
    if (nombre.isEmpty) {
      await avisar(context, titulo: 'Falta el nombre', mensaje: 'Por ejemplo: Internet, Renta, Gasolina.');
      return;
    }
    if (monto == null || monto <= 0) {
      await avisar(context, titulo: 'Monto inválido', mensaje: 'Escribe cuánto pagas normalmente.');
      return;
    }
    if (_frecuencia == FrecuenciaFijo.mensual && _diaMes == null) {
      await avisar(context, titulo: 'Falta el día', mensaje: 'Elige el día del mes en que se paga.');
      return;
    }
    final gasto = GastoFijo(
      id: widget.existente?.id,
      nombre: nombre,
      monto: monto,
      cuentaId: _cuentaId,
      categoria: _categoria,
      frecuencia: _frecuencia,
      diaMes: _frecuencia == FrecuenciaFijo.mensual ? _diaMes : null,
      activo: _activo,
    );
    setState(() => _guardando = true);
    await ref.escribir((repo) => repo.guardarGastoFijo(gasto));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _eliminar() async {
    final id = widget.existente?.id;
    if (id == null) return;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar gasto fijo',
      mensaje: 'Los pagos que ya registraste se conservan.',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!ok) return;
    await ref.escribir((repo) => repo.eliminarGastoFijo(id));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final cuentas = ref.watch(cuentasProvider).valueOrNull ?? const [];
    String nombreCuenta() {
      for (final c in cuentas) {
        if (c.cuenta.id == _cuentaId) return c.cuenta.nombreCompleto;
      }
      return 'Preguntar al pagar';
    }

    return PaginaFormulario(
      titulo: widget.existente == null ? 'Nuevo gasto fijo' : 'Editar gasto fijo',
      guardando: _guardando,
      alGuardar: _guardar,
      hijos: [
        const Etiqueta('Nombre'),
        CampoVidrio(controller: _nombre, placeholder: 'Internet, renta, gasolina...'),
        const SizedBox(height: 18),
        const Etiqueta('Monto'),
        CampoVidrio(
          controller: _monto,
          placeholder: '0.00',
          prefijo: '\$',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formatos: formatoMonto,
        ),
        const SizedBox(height: 18),
        const Etiqueta('¿Cada cuándo?'),
        CupertinoSlidingSegmentedControl<FrecuenciaFijo>(
          groupValue: _frecuencia,
          backgroundColor: tema.campo,
          thumbColor: tema.vidrioAlto,
          children: {
            for (final f in FrecuenciaFijo.values)
              f: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(f.etiqueta, style: tema.cuerpo.copyWith(fontSize: 14)),
              ),
          },
          onValueChanged: (f) {
            if (f != null) setState(() => _frecuencia = f);
          },
        ),
        const SizedBox(height: 18),
        GrupoFilas(
          filas: [
            if (_frecuencia == FrecuenciaFijo.mensual)
              FilaSelector(
                etiqueta: 'Día del mes',
                valor: _diaMes == null ? 'Elegir' : 'Día $_diaMes',
                icono: CupertinoIcons.calendar,
                onTap: () async {
                  final dia = await elegirNumero(
                    context,
                    inicial: _diaMes ?? 1,
                    minimo: 1,
                    maximo: 31,
                    etiqueta: (n) => 'Día $n',
                  );
                  if (dia != null && mounted) setState(() => _diaMes = dia);
                },
              ),
            FilaSelector(
              etiqueta: 'Se paga con',
              valor: nombreCuenta(),
              icono: CupertinoIcons.creditcard,
              onTap: () async {
                final elegida = await elegirOpcion<int>(
                  context,
                  titulo: 'Cuenta habitual',
                  opciones: [
                    const Opcion(-1, 'Preguntar al pagar'),
                    for (final c in cuentas)
                      Opcion(c.cuenta.id!, c.cuenta.nombreCompleto, seleccionada: c.cuenta.id == _cuentaId),
                  ],
                );
                if (elegida != null && mounted) setState(() => _cuentaId = elegida < 0 ? null : elegida);
              },
            ),
            FilaInterruptor(
              etiqueta: 'Activo',
              descripcion: 'Si lo pausas, deja de aparecer en tus pendientes.',
              valor: _activo,
              onChanged: (v) => setState(() => _activo = v),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Etiqueta('Categoría'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categoriasGasto)
              Presionable(
                onTap: () => setState(() => _categoria = c.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.id == _categoria ? tema.acento.withValues(alpha: 0.18) : tema.campo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.id == _categoria ? tema.acento : tema.bordeVidrio),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icono, size: 16, color: c.id == _categoria ? tema.acento : tema.textoSecundario),
                      const SizedBox(width: 6),
                      Text(c.nombre, style: tema.secundario.copyWith(color: tema.texto)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (widget.existente != null) ...[
          const SizedBox(height: 32),
          BotonLino(
            texto: 'Eliminar gasto fijo',
            icono: CupertinoIcons.trash,
            estilo: EstiloBoton.destructivo,
            onPressed: _eliminar,
          ),
        ],
      ],
    );
  }
}
