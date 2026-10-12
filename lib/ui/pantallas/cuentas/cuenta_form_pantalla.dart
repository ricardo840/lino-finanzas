import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  'Nu', 'BBVA', 'Banorte', 'Santander', 'Banamex', 'HSBC', //
  'Mercado Pago', 'Hey Banco', 'Stori', 'Klar', 'Spin', 'Didi',
];

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
  int? _diaCorte;
  int? _diaPago;
  late int _color;
  bool _guardando = false;

  /// true cuando el usuario modificó el campo de saldo. Si no lo toca, al
  /// guardar se conserva el saldo que ya tenía la cuenta.
  bool _saldoEditado = false;

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
    _diaCorte = c?.diaCorte;
    _diaPago = c?.diaPago;
    _color = c?.color ?? 0;
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
    int? limite;
    if (esCredito) {
      if (_diaCorte == null || _diaPago == null) {
        await avisar(
          context,
          titulo: 'Faltan fechas',
          mensaje: 'Indica el día de corte y el día límite de pago; el simulador los necesita.',
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
      diaCorte: esCredito ? _diaCorte : null,
      diaPago: esCredito ? _diaPago : null,
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

  Future<void> _elegirDia({required bool corte}) async {
    final actual = corte ? _diaCorte : _diaPago;
    final dia = await elegirNumero(
      context,
      inicial: actual ?? (corte ? 1 : 20),
      minimo: 1,
      maximo: 31,
      etiqueta: (n) => 'Día $n',
    );
    if (dia == null || !mounted) return;
    setState(() {
      if (corte) {
        _diaCorte = dia;
      } else {
        _diaPago = dia;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final esCredito = _tipo == TipoCuenta.credito;
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
        const SizedBox(height: 18),
        const Etiqueta('Banco'),
        CampoVidrio(
          controller: _banco,
          placeholder: 'Nu, BBVA, Banorte...',
          mayusculas: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in _bancosFrecuentes)
              Presionable(
                onTap: () => setState(() => _banco.text = b),
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
          const SizedBox(height: 18),
          const Etiqueta('Fechas'),
          GrupoFilas(
            filas: [
              FilaSelector(
                etiqueta: 'Día de corte',
                valor: _diaCorte == null ? 'Elegir' : 'Día $_diaCorte',
                icono: CupertinoIcons.scissors,
                onTap: () => _elegirDia(corte: true),
              ),
              FilaSelector(
                etiqueta: 'Fecha límite de pago',
                valor: _diaPago == null ? 'Elegir' : 'Día $_diaPago',
                icono: CupertinoIcons.calendar,
                onTap: () => _elegirDia(corte: false),
              ),
            ],
          ),
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
                onTap: () => setState(() => _color = i),
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
