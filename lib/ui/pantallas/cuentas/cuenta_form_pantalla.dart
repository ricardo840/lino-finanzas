import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fechas.dart';
import '../../../core/formato.dart';
import '../../../data/modelos/cuenta.dart';
import '../../../estado/datos.dart';
import '../../tema/contexto.dart';
import '../../tema/temas.dart';
import '../../widgets/campos.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';

const _bancosFrecuentes = [
  'Nu', 'BBVA', 'Banorte', 'Santander', 'Banamex', 'HSBC', 'Plata', //
  'Mercado Pago', 'Hey Banco', 'Stori', 'Klar', 'Spin', 'Didi',
];

String _ayudaTipo(TipoCuenta tipo) => switch (tipo) {
      TipoCuenta.debito => 'Cuenta de banco de la que pagas con tarjeta de débito o transferencia.',
      TipoCuenta.credito => 'Tarjeta de crédito. Lleva la deuda y sus fechas de corte y de pago.',
      TipoCuenta.efectivo => 'Dinero que traes en la cartera o guardas en casa.',
      TipoCuenta.ahorro =>
        'Dinero apartado que gana una tasa. Lo que pases aquí cuenta como ahorro de la semana.',
    };

/// Alta y edición de una cuenta.
class CuentaFormPantalla extends ConsumerStatefulWidget {
  const CuentaFormPantalla({super.key, this.existente});

  final CuentaConSaldo? existente;

  @override
  ConsumerState<CuentaFormPantalla> createState() => _CuentaFormPantallaState();
}

class _CuentaFormPantallaState extends ConsumerState<CuentaFormPantalla> {
  late TipoCuenta _tipo;
  late final TextEditingController _banco;
  late final TextEditingController _nombre;
  late final TextEditingController _saldo;
  late final TextEditingController _limite;
  late final TextEditingController _tasa;
  late int _color;
  bool _guardando = false;

  // Ciclo de la tarjeta de crédito.
  late bool _cicloPorDias;
  int? _diaCorte;
  int? _diaPago;
  int? _plazoDias;
  late int _periodoDias;
  DateTime? _ultimoCorte;

  /// true cuando el usuario modificó el campo de saldo. Si no lo toca, al
  /// guardar se conserva el saldo que ya tenía la cuenta.
  bool _saldoEditado = false;

  /// true cuando el usuario eligió un color a mano; ya no se le propone el
  /// del banco.
  bool _colorElegido = false;

  bool get _editando => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    final c = e?.cuenta;
    _tipo = c?.tipo ?? TipoCuenta.debito;
    _banco = TextEditingController(text: c?.banco ?? '');
    _nombre = TextEditingController(text: c?.nombre ?? '');
    final saldoVisible = e == null ? 0 : (c!.esCredito ? e.deuda : e.saldo);
    _saldo = TextEditingController(text: e == null ? '' : montoEditable(saldoVisible.abs()));
    _limite = TextEditingController(
      text: c?.limiteCredito == null ? '' : montoEditable(c!.limiteCredito!),
    );
    _tasa = TextEditingController(text: c?.tasaAnual == null ? '' : '${c!.tasaAnual}');
    _color = c?.color ?? 0;
    _cicloPorDias = c?.periodoDias != null;
    _diaCorte = c?.diaCorte;
    _diaPago = c?.diaPago;
    _plazoDias = c?.plazoPagoDias;
    _periodoDias = c?.periodoDias ?? 30;
    _ultimoCorte = c?.ultimoCorte;
  }

  @override
  void dispose() {
    _banco.dispose();
    _nombre.dispose();
    _saldo.dispose();
    _limite.dispose();
    _tasa.dispose();
    super.dispose();
  }

  /// Al elegir o escribir un banco conocido se propone su color, salvo que ya
  /// se haya elegido uno a mano o se esté editando una cuenta existente.
  void _proponerColor(String banco) {
    if (_colorElegido || _editando) return;
    final sugerido = colorDeBanco(banco);
    if (sugerido != null) _color = sugerido;
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final banco = _banco.text.trim();
    if (nombre.isEmpty && banco.isEmpty) {
      await avisar(context, titulo: 'Falta el nombre', mensaje: 'Escribe el banco o un nombre para la cuenta.');
      return;
    }
    final saldoTexto = _saldo.text.trim();
    final saldo = saldoTexto.isEmpty ? 0 : parsearDinero(saldoTexto);
    if (saldo == null) {
      await avisar(context, titulo: 'Monto inválido', mensaje: 'Revisa el saldo. Ejemplo: 1250.50');
      return;
    }
    final esCredito = _tipo == TipoCuenta.credito;
    final porDias = esCredito && _cicloPorDias;
    int? limite;
    if (esCredito) {
      final faltanFechas = porDias
          ? _ultimoCorte == null
          : _diaCorte == null || (_diaPago == null && _plazoDias == null);
      if (faltanFechas) {
        await avisar(
          context,
          titulo: 'Faltan fechas',
          mensaje: porDias
              ? 'Indica la fecha del último corte; el simulador la necesita.'
              : 'Indica el día de corte y la fecha límite de pago; el simulador los necesita.',
        );
        return;
      }
      if (_limite.text.trim().isNotEmpty) {
        limite = parsearDinero(_limite.text);
        if (limite == null) {
          await avisar(context, titulo: 'Límite inválido', mensaje: 'Revisa el límite de crédito.');
          return;
        }
      }
    }
    double? tasa;
    if (_tipo == TipoCuenta.ahorro && _tasa.text.trim().isNotEmpty) {
      tasa = double.tryParse(_tasa.text.trim().replaceAll('%', '').replaceAll(',', '.'));
      if (tasa == null || tasa < 0 || tasa > 100) {
        await avisar(context, titulo: 'Tasa inválida', mensaje: 'Escribe la tasa anual, por ejemplo 15.');
        return;
      }
    }

    // El saldo capturado es el saldo de HOY. Si la cuenta ya tiene
    // movimientos, se ajusta el saldo inicial para que el actual cuadre.
    final saldoObjetivo = esCredito ? -saldo : saldo;
    final existente = widget.existente;
    // El campo muestra el saldo sin signo. Si no se tocó (ni cambió el tipo)
    // se deja como estaba, para no invertir un saldo negativo ni borrar un
    // saldo a favor en una tarjeta.
    final conservarSaldo =
        existente != null && !_saldoEditado && _tipo == existente.cuenta.tipo;
    final saldoInicial = existente == null
        ? saldoObjetivo
        : conservarSaldo
            ? existente.cuenta.saldoInicial
            : existente.cuenta.saldoInicial + (saldoObjetivo - existente.saldo);

    final cuenta = Cuenta(
      id: existente?.cuenta.id,
      nombre: nombre.isEmpty ? _tipo.etiqueta : nombre,
      banco: banco,
      tipo: _tipo,
      saldoInicial: saldoInicial,
      limiteCredito: esCredito ? limite : null,
      diaCorte: esCredito && !porDias ? _diaCorte : null,
      diaPago: esCredito && !porDias && _plazoDias == null ? _diaPago : null,
      periodoDias: porDias ? _periodoDias : null,
      ultimoCorte: porDias ? _ultimoCorte : null,
      plazoPagoDias: !esCredito ? null : (porDias ? _plazoDias ?? 30 : _plazoDias),
      tasaAnual: _tipo == TipoCuenta.ahorro ? tasa : null,
      color: _color,
      creadaEn: existente?.cuenta.creadaEn ?? DateTime.now(),
    );

    setState(() => _guardando = true);
    await ref.escribir((repo) => repo.guardarCuenta(cuenta));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _eliminar() async {
    final id = widget.existente?.cuenta.id;
    if (id == null) return;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar cuenta',
      mensaje: 'Si ya tiene movimientos se archivará para conservar tu historial.',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!ok) return;
    await ref.escribir((repo) => repo.eliminarOArchivarCuenta(id));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _elegirDiaCorte() async {
    final dia = await elegirNumero(
      context,
      inicial: _diaCorte ?? 1,
      minimo: 1,
      maximo: 31,
      etiqueta: (n) => 'Día $n',
    );
    if (dia != null && mounted) setState(() => _diaCorte = dia);
  }

  /// Fecha límite en el ciclo por día del mes: un día fijo o un plazo en días.
  Future<void> _elegirLimite() async {
    final forma = await elegirOpcion<bool>(
      context,
      titulo: 'Fecha límite de pago',
      mensaje: 'Revisa tu estado de cuenta: unas tarjetas dan un día fijo y otras un número de días después del corte.',
      opciones: [
        Opcion(false, 'Un día fijo del mes', seleccionada: _plazoDias == null && _diaPago != null),
        Opcion(true, 'Días después del corte', seleccionada: _plazoDias != null),
      ],
    );
    if (forma == null || !mounted) return;
    if (forma) {
      final dias = await _elegirDias(inicial: _plazoDias ?? 20, maximo: 60);
      if (dias != null && mounted) setState(() => _plazoDias = dias);
    } else {
      final dia = await elegirNumero(
        context,
        inicial: _diaPago ?? 20,
        minimo: 1,
        maximo: 31,
        etiqueta: (n) => 'Día $n',
      );
      if (dia == null || !mounted) return;
      setState(() {
        _diaPago = dia;
        _plazoDias = null;
      });
    }
  }

  Future<int?> _elegirDias({required int inicial, required int maximo, int minimo = 1}) =>
      elegirNumero(
        context,
        inicial: inicial,
        minimo: minimo,
        maximo: maximo,
        etiqueta: (n) => plural(n, 'día', 'días'),
      );

  Future<void> _elegirUltimoCorte() async {
    final hoy = soloFecha(DateTime.now());
    final fecha = await elegirFecha(
      context,
      inicial: _ultimoCorte ?? hoy,
      minima: sumarDias(hoy, -92),
      maxima: hoy,
    );
    if (fecha != null && mounted) setState(() => _ultimoCorte = soloFecha(fecha));
  }

  List<Widget> _camposCiclo() {
    final tema = context.tema;
    return [
      const SizedBox(height: 18),
      const Etiqueta('Ciclo de la tarjeta'),
      CupertinoSlidingSegmentedControl<bool>(
        groupValue: _cicloPorDias,
        backgroundColor: tema.campo,
        thumbColor: tema.vidrioAlto,
        children: {
          for (final porDias in const [false, true])
            porDias: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                porDias ? 'Por días' : 'Por día del mes',
                style: tema.cuerpo.copyWith(fontSize: 14),
              ),
            ),
        },
        onValueChanged: (porDias) {
          if (porDias == null) return;
          setState(() {
            _cicloPorDias = porDias;
            if (porDias) _plazoDias ??= 30;
          });
        },
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: Text(
          _cicloPorDias
              ? 'Cada periodo dura un número fijo de días, como en la tarjeta Plata (30 y 30).'
              : 'El corte cae el mismo día cada mes.',
          style: tema.secundario,
        ),
      ),
      GrupoFilas(
        filas: _cicloPorDias
            ? [
                FilaSelector(
                  etiqueta: 'Último corte',
                  valor: _ultimoCorte == null ? 'Elegir' : fechaConAnio(_ultimoCorte!),
                  icono: CupertinoIcons.scissors,
                  onTap: _elegirUltimoCorte,
                ),
                FilaSelector(
                  etiqueta: 'Días de facturación',
                  valor: plural(_periodoDias, 'día', 'días'),
                  icono: CupertinoIcons.arrow_2_circlepath,
                  onTap: () async {
                    final dias = await _elegirDias(inicial: _periodoDias, minimo: 7, maximo: 62);
                    if (dias != null && mounted) setState(() => _periodoDias = dias);
                  },
                ),
                FilaSelector(
                  etiqueta: 'Días para pagar',
                  valor: plural(_plazoDias ?? 30, 'día', 'días'),
                  icono: CupertinoIcons.calendar,
                  onTap: () async {
                    final dias = await _elegirDias(inicial: _plazoDias ?? 30, maximo: 60);
                    if (dias != null && mounted) setState(() => _plazoDias = dias);
                  },
                ),
              ]
            : [
                FilaSelector(
                  etiqueta: 'Día de corte',
                  valor: _diaCorte == null ? 'Elegir' : 'Día $_diaCorte',
                  icono: CupertinoIcons.scissors,
                  onTap: _elegirDiaCorte,
                ),
                FilaSelector(
                  etiqueta: 'Fecha límite de pago',
                  valor: _plazoDias != null
                      ? '$_plazoDias días después'
                      : (_diaPago == null ? 'Elegir' : 'Día $_diaPago'),
                  icono: CupertinoIcons.calendar,
                  onTap: _elegirLimite,
                ),
              ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final esCredito = _tipo == TipoCuenta.credito;
    final sugerirAhorro = !_editando &&
        (_tipo == TipoCuenta.debito || _tipo == TipoCuenta.efectivo) &&
        pareceCuentaDeAhorro(_nombre.text);
    return PaginaFormulario(
      titulo: _editando ? 'Editar cuenta' : 'Nueva cuenta',
      guardando: _guardando,
      alGuardar: _guardar,
      hijos: [
        CupertinoSlidingSegmentedControl<TipoCuenta>(
          groupValue: _tipo,
          backgroundColor: tema.campo,
          thumbColor: tema.vidrioAlto,
          children: {
            for (final t in TipoCuenta.values)
              t: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(t.etiqueta, style: tema.cuerpo.copyWith(fontSize: 14)),
              ),
          },
          onValueChanged: (t) {
            if (t != null) setState(() => _tipo = t);
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(_ayudaTipo(_tipo), style: tema.secundario),
        ),
        const SizedBox(height: 18),
        const Etiqueta('Banco'),
        CampoVidrio(
          controller: _banco,
          placeholder: 'Nu, BBVA, Banorte...',
          mayusculas: TextCapitalization.words,
          onChanged: (texto) => setState(() => _proponerColor(texto)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in _bancosFrecuentes)
              Presionable(
                onTap: () => setState(() {
                  _banco.text = b;
                  _proponerColor(b);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _banco.text == b ? tema.acento.withValues(alpha: 0.22) : tema.campo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _banco.text == b ? tema.acento : tema.bordeVidrio),
                  ),
                  child: Text(b, style: tema.secundario.copyWith(color: tema.texto)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const Etiqueta('Nombre de la cuenta'),
        CampoVidrio(
          controller: _nombre,
          placeholder: switch (_tipo) {
            TipoCuenta.debito => 'Nómina, Cuenta Nu...',
            TipoCuenta.credito => 'Oro, Azul, Clásica...',
            TipoCuenta.efectivo => 'Cartera',
            TipoCuenta.ahorro => 'Cajita, Apartado...',
          },
          onChanged: (_) => setState(() {}),
        ),
        if (sugerirAhorro)
          Presionable(
            onTap: () => setState(() => _tipo = TipoCuenta.ahorro),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Row(
                children: [
                  Icon(CupertinoIcons.percent, size: 16, color: tema.acento),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Es dinero que tienes apartado? Cambiar a tipo Ahorro',
                      style: tema.secundario.copyWith(color: tema.acento),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        Etiqueta(esCredito ? 'Deuda actual' : 'Saldo actual'),
        CampoVidrio(
          controller: _saldo,
          placeholder: '0.00',
          prefijo: '\$',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formatos: formatoMonto,
          onChanged: (_) => _saldoEditado = true,
        ),
        if (esCredito) ...[
          const SizedBox(height: 18),
          const Etiqueta('Límite de crédito (opcional)'),
          CampoVidrio(
            controller: _limite,
            placeholder: '0.00',
            prefijo: '\$',
            teclado: const TextInputType.numberWithOptions(decimal: true),
            formatos: formatoMonto,
          ),
          ..._camposCiclo(),
        ],
        if (_tipo == TipoCuenta.ahorro) ...[
          const SizedBox(height: 18),
          const Etiqueta('Tasa fija anual'),
          CampoVidrio(
            controller: _tasa,
            placeholder: '15',
            prefijo: '%',
            teclado: const TextInputType.numberWithOptions(decimal: true),
            formatos: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          ),
        ],
        const SizedBox(height: 18),
        const Etiqueta('Color'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < paletaCuentas.length; i++)
              Presionable(
                onTap: () => setState(() {
                  _color = i;
                  _colorElegido = true;
                }),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: paletaCuentas[i]),
                    border: Border.all(
                      color: _color == i ? tema.texto : const Color(0x00000000),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_editando) ...[
          const SizedBox(height: 32),
          BotonLino(
            texto: 'Eliminar cuenta',
            icono: CupertinoIcons.trash,
            estilo: EstiloBoton.destructivo,
            onPressed: _eliminar,
          ),
        ],
      ],
    );
  }
}
