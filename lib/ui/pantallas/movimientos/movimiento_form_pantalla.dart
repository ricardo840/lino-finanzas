import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fechas.dart';
import '../../../core/formato.dart';
import '../../../data/modelos/cuenta.dart';
import '../../../data/modelos/movimiento.dart';
import '../../../estado/datos.dart';
import '../../categorias.dart';
import '../../tema/contexto.dart';
import '../../widgets/campos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';

/// Alta y edición de ingresos, gastos y transferencias.
class MovimientoFormPantalla extends ConsumerStatefulWidget {
  const MovimientoFormPantalla({
    super.key,
    this.movimiento,
    this.montoInicial,
    this.cuentaInicialId,
    this.descripcionInicial,
    this.fechaInicial,
  });

  /// Movimiento que se edita; null para uno nuevo.
  final Movimiento? movimiento;

  // Valores para abrir un gasto nuevo ya llenado (por ejemplo, desde una
  // compra planeada). No aplican al editar.
  final int? montoInicial;
  final int? cuentaInicialId;
  final String? descripcionInicial;
  final DateTime? fechaInicial;

  @override
  ConsumerState<MovimientoFormPantalla> createState() => _MovimientoFormPantallaState();
}

class _MovimientoFormPantallaState extends ConsumerState<MovimientoFormPantalla> {
  late TipoMovimiento _tipo;
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;
  int? _cuentaId;
  int? _destinoId;
  late String _categoria;
  late DateTime _fecha;
  bool _esSueldo = false;
  bool _esFijo = false;
  bool _guardando = false;

  bool get _editando => widget.movimiento != null;

  @override
  void initState() {
    super.initState();
    final m = widget.movimiento;
    _tipo = m?.tipo ?? TipoMovimiento.egreso;
    final monto = m?.monto ?? widget.montoInicial;
    _monto = TextEditingController(text: monto == null ? '' : montoEditable(monto));
    _descripcion = TextEditingController(text: m?.descripcion ?? widget.descripcionInicial ?? '');
    _cuentaId = m?.cuentaId ?? widget.cuentaInicialId;
    _destinoId = m?.cuentaDestinoId;
    _categoria = m?.categoria ?? categoriasGasto.first.id;
    _fecha = m?.fecha ?? widget.fechaInicial ?? soloFecha(DateTime.now());
    _esSueldo = m?.esSueldo ?? false;
    _esFijo = m?.esFijo ?? false;
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _cambiarTipo(TipoMovimiento tipo) {
    setState(() {
      _tipo = tipo;
      final categorias = categoriasPara(tipo);
      if (!categorias.any((c) => c.id == _categoria)) _categoria = categorias.first.id;
      if (tipo != TipoMovimiento.ingreso) _esSueldo = false;
      if (tipo != TipoMovimiento.egreso) _esFijo = false;
    });
  }

  Future<void> _elegirCuenta(List<CuentaConSaldo> cuentas, {required bool destino}) async {
    final elegida = await elegirOpcion<int>(
      context,
      titulo: destino ? '¿A qué cuenta?' : (_tipo == TipoMovimiento.ingreso ? '¿A qué cuenta entró?' : '¿De qué cuenta?'),
      opciones: [
        for (final c in cuentas)
          Opcion(
            c.cuenta.id!,
            '${c.cuenta.nombreCompleto}  (${c.cuenta.tipo.etiqueta})',
            seleccionada: c.cuenta.id == (destino ? _destinoId : _cuentaId),
          ),
      ],
    );
    if (elegida == null || !mounted) return;
    setState(() {
      if (destino) {
        _destinoId = elegida;
      } else {
        _cuentaId = elegida;
      }
    });
  }

  Future<void> _elegirFecha() async {
    final hoy = soloFecha(DateTime.now());
    final fecha = await elegirFecha(
      context,
      inicial: _fecha,
      minima: DateTime(hoy.year - 5),
      maxima: sumarDias(hoy, 365),
    );
    if (fecha != null && mounted) setState(() => _fecha = soloFecha(fecha));
  }

  Future<void> _guardar() async {
    final monto = parsearDinero(_monto.text);
    if (monto == null || monto <= 0) {
      await avisar(context, titulo: 'Monto inválido', mensaje: 'Escribe un monto mayor a cero, por ejemplo 250.50');
      return;
    }
    final cuentaId = _cuentaId;
    if (cuentaId == null) {
      await avisar(context, titulo: 'Falta la cuenta', mensaje: 'Elige la cuenta del movimiento.');
      return;
    }
    if (_tipo == TipoMovimiento.transferencia) {
      if (_destinoId == null || _destinoId == cuentaId) {
        await avisar(context, titulo: 'Revisa la transferencia', mensaje: 'Elige una cuenta destino distinta a la de origen.');
        return;
      }
    }

    final movimiento = Movimiento(
      id: widget.movimiento?.id,
      tipo: _tipo,
      monto: monto,
      cuentaId: cuentaId,
      cuentaDestinoId: _tipo == TipoMovimiento.transferencia ? _destinoId : null,
      categoria: _tipo == TipoMovimiento.transferencia ? categoriaTransferencia.id : _categoria,
      descripcion: _descripcion.text.trim(),
      fecha: _fecha,
      esSueldo: _tipo == TipoMovimiento.ingreso && _esSueldo,
      esFijo: _tipo == TipoMovimiento.egreso && _esFijo,
      gastoFijoId: widget.movimiento?.gastoFijoId,
      creadoEn: widget.movimiento?.creadoEn ?? DateTime.now(),
    );

    setState(() => _guardando = true);
    await ref.escribir((repo) => repo.guardarMovimiento(movimiento));
    if (!mounted) return;
    // true: el movimiento se guardó (quien abrió el formulario puede necesitarlo).
    Navigator.of(context).pop(true);
  }

  Future<void> _eliminar() async {
    final id = widget.movimiento?.id;
    if (id == null) return;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar movimiento',
      mensaje: 'Se quitará de tus saldos y de la semana. No se puede deshacer.',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!ok) return;
    await ref.escribir((repo) => repo.eliminarMovimiento(id));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _nombreCuenta(List<CuentaConSaldo> cuentas, int? id) {
    for (final c in cuentas) {
      if (c.cuenta.id == id) return c.cuenta.nombreCompleto;
    }
    return 'Elegir';
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final cuentas = ref.watch(cuentasProvider).valueOrNull ?? const <CuentaConSaldo>[];

    // Si es nuevo y no se ha elegido cuenta, se propone la primera de débito.
    if (_cuentaId == null && cuentas.isNotEmpty) {
      final sugerida = cuentas.firstWhere((c) => c.cuenta.esLiquida, orElse: () => cuentas.first);
      _cuentaId = sugerida.cuenta.id;
    }

    final semana = semanaPresupuestal(_fecha, esSueldo: _esSueldo, esFijo: _esFijo);
    final cambiaDeSemana = !mismaFecha(semana, lunesDe(_fecha));

    return PaginaFormulario(
      titulo: _editando ? 'Editar movimiento' : 'Nuevo movimiento',
      guardando: _guardando,
      alGuardar: cuentas.isEmpty ? null : _guardar,
      hijos: [
        if (cuentas.isEmpty) ...[
          const EstadoVacio(
            icono: CupertinoIcons.creditcard,
            titulo: 'Primero agrega una cuenta',
            mensaje: 'Ve a la pestaña Cuentas y da de alta al menos una.',
          ),
          const SizedBox(height: 18),
        ],
        CupertinoSlidingSegmentedControl<TipoMovimiento>(
          groupValue: _tipo,
          backgroundColor: tema.campo,
          thumbColor: tema.vidrioAlto,
          children: {
            for (final t in TipoMovimiento.values)
              t: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(t.etiqueta, style: tema.cuerpo.copyWith(fontSize: 14)),
              ),
          },
          onValueChanged: (t) {
            if (t != null) _cambiarTipo(t);
          },
        ),
        const SizedBox(height: 20),
        CampoVidrio(
          controller: _monto,
          placeholder: '0.00',
          prefijo: '\$',
          autofocus: !_editando && widget.montoInicial == null,
          alineacion: TextAlign.center,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formatos: formatoMonto,
          estilo: tema.montoGrande.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 20),
        GrupoFilas(
          filas: [
            FilaSelector(
              etiqueta: _tipo == TipoMovimiento.transferencia ? 'Desde' : 'Cuenta',
              valor: _nombreCuenta(cuentas, _cuentaId),
              icono: CupertinoIcons.creditcard,
              onTap: cuentas.isEmpty ? null : () => _elegirCuenta(cuentas, destino: false),
            ),
            if (_tipo == TipoMovimiento.transferencia)
              FilaSelector(
                etiqueta: 'Hacia',
                valor: _nombreCuenta(cuentas, _destinoId),
                icono: CupertinoIcons.arrow_right_arrow_left,
                onTap: cuentas.isEmpty ? null : () => _elegirCuenta(cuentas, destino: true),
              ),
            FilaSelector(
              etiqueta: 'Fecha',
              valor: capitalizar(fechaMedia(_fecha)),
              icono: CupertinoIcons.calendar,
              onTap: _elegirFecha,
            ),
          ],
        ),
        if (_tipo != TipoMovimiento.transferencia) ...[
          const SizedBox(height: 20),
          const Etiqueta('Categoría'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categoriasPara(_tipo))
                _ChipCategoria(
                  categoria: c,
                  seleccionada: c.id == _categoria,
                  onTap: () => setState(() => _categoria = c.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const Etiqueta('Descripción'),
        CampoVidrio(
          controller: _descripcion,
          placeholder: _tipo == TipoMovimiento.transferencia ? 'Pago de tarjeta, ahorro...' : 'Opcional',
          maxLength: 80,
        ),
        if (_tipo == TipoMovimiento.ingreso) ...[
          const SizedBox(height: 20),
          GrupoFilas(
            filas: [
              FilaInterruptor(
                etiqueta: 'Es mi sueldo semanal',
                descripcion: 'El sueldo del domingo financia la semana que empieza.',
                icono: CupertinoIcons.briefcase,
                valor: _esSueldo,
                onChanged: (v) => setState(() {
                  _esSueldo = v;
                  if (v) _categoria = 'sueldo';
                }),
              ),
            ],
          ),
        ],
        if (_tipo == TipoMovimiento.egreso) ...[
          const SizedBox(height: 20),
          GrupoFilas(
            filas: [
              FilaInterruptor(
                etiqueta: 'Gasto fijo',
                descripcion: 'Internet, renta, transporte... lo que pagas cada semana o mes.',
                icono: CupertinoIcons.pin,
                valor: _esFijo,
                onChanged: (v) => setState(() => _esFijo = v),
              ),
            ],
          ),
        ],
        if (cambiaDeSemana) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Como es domingo, se contará en la semana del ${rangoSemana(semana)}.',
              style: tema.secundario,
            ),
          ),
        ],
        if (_editando) ...[
          const SizedBox(height: 32),
          BotonLino(
            texto: 'Eliminar movimiento',
            icono: CupertinoIcons.trash,
            estilo: EstiloBoton.destructivo,
            onPressed: _eliminar,
          ),
        ],
      ],
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  const _ChipCategoria({required this.categoria, required this.seleccionada, required this.onTap});

  final Categoria categoria;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final color = seleccionada ? tema.acento : tema.textoSecundario;
    return Presionable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionada ? tema.acento.withValues(alpha: 0.18) : tema.campo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: seleccionada ? tema.acento : tema.bordeVidrio),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categoria.icono, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              categoria.nombre,
              style: tema.secundario.copyWith(color: seleccionada ? tema.texto : tema.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}
