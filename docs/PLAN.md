# Lino — planeación

App móvil (Android) para administrar ingresos y egresos en varias cuentas,
tarjetas de crédito, efectivo y ahorro, con un presupuesto semanal y un
simulador que recomienda cuándo y cómo pagar una compra.

## Decisiones tomadas

| Tema | Decisión |
| --- | --- |
| Plataforma | Android, con estilo Cupertino (iOS). Solo widgets Cupertino, nada de Material. |
| Datos | Solo locales en el teléfono. Base SQLite cifrada (SQLCipher). Sin nube. |
| Acceso | Login desde el inicio: PIN de 6 dígitos + huella. Bloqueo automático al salir. |
| Privacidad | Modo privacidad que oculta todos los montos. |
| Diseño | Glassmorfismo, aspecto profesional. **Prohibido usar emojis** en la app y en el código. |
| Temas | Gama personalizable: oscuros (Medianoche, Grafito, Esmeralda, Ámbar, Amatista) y claros de temporada (Primavera, Verano, Otoño, Invierno). |
| Ícono | Una "L" sobre vidrio. Nombre visible: **Lino**. |
| Sueldo | Semanal, cada domingo, monto variable. El sueldo del domingo financia la semana que empieza. |
| Semana | Lunes a domingo. |
| Gastos fijos | Los captura el usuario y marca cuáles son fijos (internet, renta...). Se pagan cada domingo (o un día del mes). |
| Tarjetas | Siempre se paga el total; no se usan meses sin intereses. |
| Bancos | Unos 6 bancos con cuentas de débito y crédito. |
| Ahorro | Con tasa fija del banco (p. ej. Nu al 15 %). |
| Inversiones | CETES y similares quedan para una fase posterior. |

## Reglas de negocio

### Semana presupuestal
- La semana va de lunes a domingo.
- Un movimiento pertenece a la semana de su fecha, **excepto** el sueldo y los
  pagos fijos registrados en domingo: esos cuentan para la semana que empieza al
  día siguiente (`semanaPresupuestal()` en `lib/core/fechas.dart`).
- En domingo la app ya muestra como "esta semana" la que empieza mañana.
- Disponible = ingresos − gastos (fijos + variables) − ahorro apartado.

### Montos
- Todo se guarda en **centavos (int)**. Nunca `double` para dinero.
- En tarjetas de crédito el saldo es negativo cuando hay deuda.
- Saldo de una cuenta = saldo inicial + ingresos − egresos − transferencias que
  salen + transferencias que entran.
- Gastar con tarjeta cuenta como gasto en la semana; pagar la tarjeta es una
  transferencia (no se cuenta dos veces).

### Tarjetas de crédito (`lib/dominio/ciclo_tarjeta.dart`)
- Una compra hecha el día del corte entra en ese corte.
- Fecha límite de pago = siguiente "día de pago" después del corte.
- Días para pagar = fecha límite − fecha de compra. Comprar justo después del
  corte da el máximo de días.

### Simulador (`lib/dominio/simulador_compra.dart`)
1. Evalúa cada tarjeta en la fecha de compra (días para pagar, crédito
   disponible, domingos de sueldo antes de la fecha límite).
2. Si el usuario puede esperar y esperar da 7+ días extra (y hoy hay menos de
   30), recomienda **esperar** al día después del corte.
3. Si la mejor tarjeta da 10+ días y hay al menos un sueldo antes del pago,
   recomienda **crédito** (sin intereses porque se paga el total) y calcula lo
   que el dinero gana mientras tanto en el ahorro.
4. Si no, **débito** con la cuenta de más saldo que alcance.
5. Si nada alcanza, **sin fondos**.
6. Siempre avisa si la compra supera el disponible de la semana y cuánto
   apartar de cada sueldo hasta la fecha límite.

### Seguridad
- PIN: PBKDF2-HMAC-SHA256 (60 000 iteraciones, sal aleatoria) en el Keystore
  (`flutter_secure_storage`). Nunca se guarda en claro.
- PIN obvios rechazados (111111, 123456, 654321).
- Cada 5 intentos fallidos: bloqueo de 30 s, 1 min, 2 min... hasta 30 min.
- Llave de la base: 256 bits aleatorios en el Keystore (no derivada del PIN
  para que funcione la huella y cambiar el PIN no obligue a recifrar).
- Bloqueo automático configurable (inmediato, 30 s, 1 min, 5 min).

## Arquitectura

```
lib/
  main.dart                  arranque: lee ajustes y abre ProviderScope
  app.dart                   CupertinoApp, tema, capa de bloqueo, bloqueo automático
  core/
    fechas.dart              aritmética de fechas y semana presupuestal
    formato.dart             dinero y fechas en español
    seguridad/               PBKDF2, almacén seguro, ServicioAuth (PIN + huella)
  data/
    base_datos.dart          SQLCipher, esquema y migraciones
    repositorio.dart         todo el SQL
    modelos/                 Cuenta, Movimiento, GastoFijo
  dominio/                   lógica pura y probada: resumen semanal, tarjetas, simulador
  estado/                    proveedores Riverpod (servicios, auth, ajustes, datos)
  ui/
    tema/                    LinoTema, catálogo de temas, context.tema
    widgets/                 vidrio, fondo, campos, diálogos, teclado de PIN...
    pantallas/               auth, inicio, cuentas, movimientos, simulador, ajustes
test/                        pruebas de dominio, seguridad y widgets
tool/configurar_android.dart ajustes de Android tras `flutter create`
```

- Estado: `flutter_riverpod` (Notifier / FutureProvider). Cada escritura usa
  `ref.escribir(...)`, que sube `revisionDatosProvider` y refresca las pantallas.
- La capa de seguridad (crear PIN / bloqueo) se dibuja encima del Navigator, así
  que esas pantallas no abren diálogos.

## Estado actual (v0.1.0)

Hecho:
- [x] Temas glass (9) con selector y modo privacidad.
- [x] Crear PIN, desbloqueo con PIN o huella, bloqueo automático, cambiar PIN.
- [x] Base cifrada con cuentas, movimientos y gastos fijos.
- [x] Cuentas: débito, crédito (corte, pago, límite), efectivo, ahorro (tasa fija).
- [x] Movimientos: gasto, ingreso (sueldo), transferencia; editar y eliminar.
- [x] Inicio: disponible de la semana, pagos fijos pendientes, tarjetas, ahorro.
- [x] Simulador de compras.
- [x] Pruebas unitarias del dominio y de seguridad.

## Siguientes pasos

Fase 2
- [ ] Bloquear capturas de pantalla y la vista previa en "apps recientes" (FLAG_SECURE).
- [ ] Recordatorios locales: fecha límite de tarjetas y pagos fijos del domingo.
- [ ] Presupuesto por categoría y gráfica semanal (CustomPaint, sin Material).
- [ ] Respaldo cifrado exportable/importable (archivo protegido con contraseña).
- [ ] Búsqueda y filtros en movimientos.

Fase 3
- [ ] Inversiones (CETES y similares): plazo, tasa, fecha de vencimiento, rendimiento neto.
- [ ] Metas de ahorro.
- [ ] Simulador: comparar comprar hoy vs. ahorrar N semanas.
