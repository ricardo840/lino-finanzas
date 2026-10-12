import 'package:flutter/cupertino.dart';

import '../data/modelos/cuenta.dart';
import '../data/modelos/movimiento.dart';

/// Categoría de un movimiento. El id es lo que se guarda en la base.
class Categoria {
  const Categoria(this.id, this.nombre, this.icono);

  final String id;
  final String nombre;
  final IconData icono;
}

const List<Categoria> categoriasGasto = [
  Categoria('super', 'Súper', CupertinoIcons.cart),
  Categoria('comida', 'Comida fuera', CupertinoIcons.flame),
  Categoria('transporte', 'Transporte', CupertinoIcons.car_detailed),
  Categoria('servicios', 'Servicios', CupertinoIcons.bolt),
  Categoria('internet', 'Internet y celular', CupertinoIcons.wifi),
  Categoria('hogar', 'Hogar', CupertinoIcons.house),
  Categoria('salud', 'Salud', CupertinoIcons.heart),
  Categoria('suscripciones', 'Suscripciones', CupertinoIcons.tv),
  Categoria('entretenimiento', 'Entretenimiento', CupertinoIcons.gamecontroller),
  Categoria('ropa', 'Ropa', CupertinoIcons.bag),
  Categoria('educacion', 'Educación', CupertinoIcons.book),
  Categoria('regalos', 'Regalos', CupertinoIcons.gift),
  Categoria('otros', 'Otros', CupertinoIcons.ellipsis_circle),
];

const List<Categoria> categoriasIngreso = [
  Categoria('sueldo', 'Sueldo', CupertinoIcons.briefcase),
  Categoria('extra', 'Ingreso extra', CupertinoIcons.plus_circle),
  Categoria('reembolso', 'Reembolso', CupertinoIcons.arrow_counterclockwise),
  Categoria('rendimientos', 'Rendimientos', CupertinoIcons.chart_bar),
  Categoria('otros_ingresos', 'Otros', CupertinoIcons.ellipsis_circle),
];

const Categoria categoriaTransferencia =
    Categoria('transferencia', 'Transferencia', CupertinoIcons.arrow_right_arrow_left);

List<Categoria> categoriasPara(TipoMovimiento tipo) => switch (tipo) {
      TipoMovimiento.egreso => categoriasGasto,
      TipoMovimiento.ingreso => categoriasIngreso,
      TipoMovimiento.transferencia => const [categoriaTransferencia],
    };

Categoria categoriaPorId(String id) {
  for (final c in [...categoriasGasto, ...categoriasIngreso, categoriaTransferencia]) {
    if (c.id == id) return c;
  }
  return categoriasGasto.last;
}

IconData iconoTipoCuenta(TipoCuenta tipo) => switch (tipo) {
      TipoCuenta.debito => CupertinoIcons.creditcard,
      TipoCuenta.credito => CupertinoIcons.creditcard_fill,
      TipoCuenta.efectivo => CupertinoIcons.money_dollar_circle,
      TipoCuenta.ahorro => CupertinoIcons.percent,
    };
