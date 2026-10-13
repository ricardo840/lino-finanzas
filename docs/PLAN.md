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
| Respaldos | Android no respalda ni traspasa los datos. Desinstalar la app los borra; la exportación llega en la Fase 2. |
| Diseño | Glassmorfismo, aspecto profesional. **Prohibido usar emojis** en la app y en el código. |
| Navegación | Cinco pestañas en una isla flotante de vidrio. Cada pestaña abre siempre en su pantalla principal. |
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
- Sin respaldos de Android: `allowBackup="false"` y `res/xml/reglas_respaldo.xml`.
  La llave del Keystore no viaja en un respaldo, así que una base restaurada
  no se podría abrir.
- El APK de release no pide permiso de INTERNET.

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
    widgets/                 vidrio, fondo, campos, diálogos, teclado de PIN, isla de pestañas...
    pantallas/               auth, inicio, cuentas, movimientos, simulador, ajustes; shell.dart
test/                        pruebas de dominio, seguridad y widgets (dobles en apoyo.dart)
tool/configurar_android.dart ajustes de Android tras `flutter create` (idempotente)
```

- Estado: `flutter_riverpod` (Notifier / FutureProvider). Cada escritura usa
  `ref.escribir(...)`, que sube `revisionDatosProvider` y refresca las pantallas.
- La capa de seguridad (crear PIN / bloqueo) se dibuja encima del Navigator, así
  que esas pantallas no abren diálogos.
- Pestañas (`ui/pantallas/shell.dart`): un `CupertinoTabView` por pestaña y la
  `BarraIsla` flotando encima; su altura se anuncia como margen inferior en
  `MediaQuery`. No se usa `CupertinoTabScaffold`. Los formularios se abren con
  `abrirPantalla(..., modal: true)` y tapan la isla.
- `android/` se genera con `flutter create`; lo que Lino necesita ahí (huella,
  permisos, respaldos, minSdk) lo aplica `tool/configurar_android.dart`.

## Estado actual (v0.1.0)

Verificado el 12 de octubre de 2026 con Flutter 3.47.1: `flutter analyze`
limpio, 50 pruebas, APK de depuración y de release, y probado en un Redmi
Note 13 Pro+ (Android 13). Repositorio: `github.com/ricardo840/lino-finanzas`.

Hecho:
- [x] Temas glass (9) con selector y modo privacidad.
- [x] Crear PIN, desbloqueo con PIN o huella, bloqueo automático, cambiar PIN.
- [x] Base cifrada con cuentas, movimientos y gastos fijos.
- [x] Cuentas: débito, crédito (corte, pago, límite), efectivo, ahorro (tasa fija).
- [x] Movimientos: gasto, ingreso (sueldo), transferencia; editar y eliminar.
- [x] Inicio: disponible de la semana, pagos fijos pendientes, tarjetas, ahorro.
- [x] Simulador de compras.
- [x] Pruebas unitarias del dominio y de seguridad.
- [x] Plataforma Android generada y configurada (huella, sin respaldos, minSdk 24).
- [x] Barra de pestañas en isla flotante.
- [x] Pruebas de widgets: arranque y bloqueo, formulario de cuenta y pestañas.

## Notas para continuar

- **Probar**: `flutter analyze`, `flutter test` y `flutter run` en teléfono (el
  equipo de desarrollo no tiene emulador). Para uso diario, `flutter run --release`.
- **Cuidado con los datos**: `flutter run` e `install` desinstalan la app si la
  instalación falla (por ejemplo, al cambiar la firma), y eso borra todo. Hasta
  tener el respaldo de la Fase 2, no cambiar la firma del APK.
- **Pruebas de widgets**: los dobles están en `test/apoyo.dart`
  (`sustitutos(almacen)`). El hash del PIN corre en otro isolate, así que hay
  que esperarlo con `tester.runAsync`. La fuente de pruebas es casi el doble de
  ancha que la real: las pantallas con renglones largos se prueban a 800 de ancho.
- **Windows y VS Code**: si Gradle falla con `Couldn't delete ...R.jar`, el
  archivo lo bloquea la extensión de Kotlin; basta recargar la ventana.
- **Editar una cuenta**: el campo "Saldo actual" es el saldo de hoy. Si se
  cambia, se ajusta el saldo inicial; si no se toca, el saldo se conserva.

Pendientes menores detectados (sin corregir):
- "Crea tu PIN" puede desbordarse en pantallas de menos de unos 700 puntos de alto.
- `FilaSelector` no encoge su etiqueta; con la fuente del sistema muy grande
  puede desbordarse.
- El desbloqueo con PIN tarda del orden de 1 a 2 s en teléfono (PBKDF2 en Dart puro).
- No hay pruebas del SQL de `repositorio.dart` (haría falta `sqflite_common_ffi`).
- README y AGENTS mencionan tareas de VS Code, pero el proyecto no trae `.vscode/`.

## Siguientes pasos

Fase 1.5 — mejoras tras la primera prueba. El detalle de cada una (qué se
pidió, instrucción y cómo se comprueba) está en `docs/MEJORAS.md`; léelo solo
al trabajar en ellas. Decidido con el usuario: botón de añadir flotante sobre
la isla, calendario dentro de una pestaña "Planear" que sustituye a Simulador,
y el ícono se elige entre propuestas. Orden sugerido:
- [ ] M3 Comas de miles al escribir montos.
- [ ] M4 Más colores de cuenta y banco "Plata"; M10 tipo de cuenta más claro.
- [ ] M1 Ciclo de tarjeta medido en días (Plata: 30 de facturación y 30 de plazo). Migración a la versión 2 de la base.
- [ ] M5 Botón flotante para registrar en Inicio, Movimientos y Cuentas.
- [ ] M6 Encabezado tipo isla en todas las pantallas.
- [ ] M2 Calendario de cortes, pagos, gastos fijos y sueldos en la pestaña Planear.
- [ ] M8 Simulador con rango de fechas, línea de tiempo y compras planeadas.
- [ ] M9 Ajustes nuevos (cuenta predeterminada, sueldo habitual, tema automático...).
- [ ] M7 Ícono nuevo (independiente; primero se eligen propuestas).

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
