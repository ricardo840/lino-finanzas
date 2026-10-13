# Lino — mejoras tras la primera prueba (Fase 1.5)

Observaciones del usuario del 12 de octubre de 2026 después de probar la app
en su teléfono, reescritas como instrucciones listas para programar.

**Estado: todas hechas el 12 de octubre de 2026** (M1 a M10). Lo que quedó
fuera de cada una está en "Siguientes pasos" de `docs/PLAN.md`. Este archivo
se conserva como registro de qué se pidió y con qué criterio se dio por bueno.

## Cómo escribir una observación

Para que una nota se pueda programar sin preguntas de ida y vuelta:

1. **Dónde**: pantalla y elemento ("Simulador, campo Compraría el").
2. **Qué pasa hoy**: lo que ves.
3. **Qué quieres**: el comportamiento o aspecto esperado, con un ejemplo.
4. **Listo cuando**: cómo se comprueba que quedó.

Ejemplo: "En Nueva cuenta, el campo Saldo no pone comas. Quiero que 1500 se
vea 1,500 mientras escribo. Listo cuando 1234567.5 se ve 1,234,567.5."

---

## M1. Ciclo de tarjeta medido en días (tarjeta Plata)

- **Nota original**: "La tarjeta Plata son 30 días de corte y 30 para el pago"
  (aclarado: 30 días de facturación y 30 días de plazo para pagar).
- **Hoy**: una tarjeta solo acepta día de corte y día de pago del mes.
- **Instrucción**: en cuentas de crédito, ofrecer dos formas de ciclo:
  - *Por día del mes* (la actual): día de corte, y la fecha límite como día del
    mes o como "N días después del corte".
  - *Por días*: fecha del último corte, días de facturación (30) y días de
    plazo para pagar (30).
  `CicloTarjeta` debe resolver próximo corte, fecha límite y días para pagar en
  ambos casos; Inicio, simulador y calendario lo usan sin saber cuál es.
  Columnas nuevas y opcionales en `cuentas`, con `BaseDatos.version = 2` y
  migración que conserve los datos ya capturados.
- **Listo cuando**: una tarjeta por días con último corte el 16 de octubre,
  30 y 30, da para una compra del 17 de octubre: corte 15 de noviembre, límite
  15 de diciembre, 59 días. Las tarjetas existentes no cambian. Con pruebas.
- **Dónde**: `dominio/ciclo_tarjeta.dart`, `data/modelos/cuenta.dart`,
  `data/base_datos.dart`, `cuentas/cuenta_form_pantalla.dart`.
- **Tamaño**: mediano. **Confirmado por el usuario**: Plata maneja periodos
  fijos de 30 días de facturación y 30 días de plazo, así que se captura con
  el ciclo por días.

## M2. Calendario en la pestaña Planear

- **Notas originales**: "En los créditos usar un calendario para tener algo
  visual de los cortes y días de pago" y "Pensar en formas de implementar un
  calendario en donde se muestren los gastos fijos o para hacer planeaciones".
- **Decidido**: la pestaña Simulador pasa a llamarse **Planear**, con dos
  vistas: Calendario y Simulador.
- **Instrucción**: cuadrícula mensual de lunes a domingo, hecha a mano (los
  paquetes de calendario son de Material), con mes anterior y siguiente. Cada
  día marca: corte de tarjeta (con el color de la tarjeta), fecha límite de
  pago, gasto fijo, domingo de sueldo y compra planeada (M8). Al tocar un día
  se listan sus eventos con monto y dos acciones: registrar el pago y simular
  una compra ese día. Los eventos se calculan en una función pura
  (`dominio/calendario.dart`). Desde cada tarjeta, un acceso "Ver en calendario".
- **Listo cuando**: octubre de 2026 muestra el corte del 16 y el pago del 26
  de la tarjeta Nu, los domingos de sueldo y los gastos fijos del mes; tocar el
  16 lista el corte. Con pruebas de la función de eventos.
- **Tamaño**: grande. **Depende de**: M1 y M6. **Primera versión**: solo
  lectura más el salto al simulador; el saldo proyectado queda para después.

## M3. Comas de miles al escribir montos

- **Nota original**: "Darle formatos a los números al escribirlos, falta la
  coma en los 3 ceros automáticamente".
- **Instrucción**: en todos los campos de monto, insertar la coma de miles
  mientras se escribe, con máximo dos decimales y sin que el cursor salte. Al
  editar un monto existente también se muestra con comas.
- **Listo cuando**: teclear 1234567.5 muestra 1,234,567.5; borrar un dígito
  reacomoda las comas; el monto guardado es el mismo que antes. Con pruebas.
- **Dónde**: `ui/widgets/campos.dart` (`formatoMonto`), `core/formato.dart`.
- **Tamaño**: chico.

## M4. Más colores para cuentas y tarjetas

- **Nota original**: "Agregar más colores para las tarjetas".
- **Instrucción**: ampliar la paleta de 8 a unos 18 degradados, **agregando al
  final** (el color se guarda como posición en la lista; reordenar cambiaría
  los colores ya elegidos). Sugerir un color al elegir banco y agregar "Plata"
  a los bancos frecuentes.
- **Listo cuando**: las cuentas existentes conservan su color y hay tonos
  plata, negro, rojo y verde oscuro entre los nuevos.
- **Dónde**: `ui/tema/temas.dart` (`paletaCuentas`), `cuenta_form_pantalla.dart`.
- **Tamaño**: chico.

## M5. Botón flotante para registrar

- **Notas originales**: "En la pantalla de inicio el botón de más no está claro
  lo que hace a simple vista" y "En movimientos dale más protagonismo al botón
  de añadir, tal vez flotando arriba de la isla".
- **Decidido**: cápsula de vidrio flotante sobre la isla.
- **Instrucción**: un botón flotante con icono y texto ("Movimiento") arriba de
  la isla, a la derecha, en Inicio y en Movimientos; se quita el + del
  encabezado en esas dos pantallas. En Cuentas, el mismo componente con el
  texto "Cuenta". Se oculta con el teclado abierto y las listas deben poder
  desplazarse por encima de él.
- **Listo cuando**: se entiende qué hace sin tocarlo y abre el formulario
  correspondiente. Con prueba de widget.
- **Dónde**: widget nuevo en `ui/widgets/`, `shell.dart` o cada pantalla.
- **Tamaño**: chico.

## M6. Encabezado tipo isla

- **Nota original**: "La parte de arriba donde vienen los nombres de la
  pantalla es muy simple. Tal vez un diseño parecido a la isla de los botones".
- **Hoy**: una franja oscura plana con borde duro.
- **Instrucción**: el título grande va directo sobre el fondo, sin franja. Al
  desplazar, se convierte en una cápsula de vidrio flotante con el título al
  centro y las acciones a los lados. Subpantallas y formularios usan la misma
  cápsula con "atrás", "Cancelar" y "Guardar". Sustituye las barras de
  navegación de Cupertino en `ui/widgets/paginas.dart` y en las pantallas que
  las usan directo (Tema, Gastos fijos, Cambiar PIN).
- **Listo cuando**: ninguna pantalla muestra la franja, el gesto y el botón de
  atrás siguen funcionando y el contenido no queda tapado al inicio.
- **Tamaño**: mediano. Conviene hacerlo **antes** del calendario para que las
  pantallas nuevas nazcan con el encabezado definitivo.

## M7. Ícono de la app

- **Nota original**: "El diseño del icono de la app está muy feo. Otras
  opciones o te paso un diseño".
- **Decidido**: se preparan tres o cuatro propuestas en imagen para elegir.
- **Ideas a proponer**: monograma "L" de un solo trazo sobre degradado; "L"
  formada por barras que suben como gráfica; tallo de lino estilizado;
  cápsula de vidrio con la "L" recortada.
- **Instrucción**: con la elegida, regenerar el ícono adaptable de Android
  (`flutter_launcher_icons`) y actualizar `LogoLino` para que coincida dentro
  de la app.
- **Hecho**: se eligió la flor de lino. El dibujo fuente es
  `assets/icono/lino.svg`; `LogoLino` la pinta con los colores del tema.

## M8. Simulador más claro y más útil

- **Notas originales**: "Cómo podemos mejorar el simulador", "Mejorar
  visualmente la parte de 'Te digo cuándo y con qué conviene...'", "¿A qué se
  refiere la pregunta de cuánto puedo esperar?" y "Sería mejor poner un rango
  de fechas para el Compraría el".
- **Hoy**: "¿Puedo esperar?" significa cuántos días se puede aplazar la compra;
  el simulador busca dentro de ese margen el día que da más plazo. No se
  entiende.
- **Instrucción**:
  - Sustituir "Compraría el" y "¿Puedo esperar?" por un rango: "Podría comprar
    entre [desde] y [hasta]", con atajos Hoy, Esta semana y Este mes. El motor
    ya lo soporta (`fecha = desde`, `diasEspera = días entre ambas`).
  - Cambiar el párrafo inicial por un encabezado corto y claro.
  - Mostrar el resultado como línea de tiempo: compra, corte y fecha límite,
    con los domingos de sueldo marcados, y resaltar el mejor día del rango.
  - Dos acciones al final: "Guardar como compra planeada" (aparece en el
    calendario) y "Registrar compra" (crea el movimiento ya llenado).
- **Mejora de fondo, opcional**: avisar si alcanza para pagarla contando los
  gastos fijos y los pagos de otras tarjetas antes de la fecha límite, usando
  el sueldo habitual de M9.
- **Listo cuando**: una persona que no conoce la app entiende qué pedir y qué
  le recomiendan; las reglas de `PLAN.md` siguen dando el mismo resultado.
- **Tamaño**: grande. **Depende de**: M1, M2 y M6. Las compras planeadas
  necesitan una tabla nueva (migración).

## M9. Ajustes nuevos

- **Nota original**: "Qué otros ajustes o configuración podemos añadir para
  experiencia de usuario".
- **Propuesta, en orden de utilidad**:
  1. Cuenta predeterminada para gastos.
  2. Sueldo habitual, para las proyecciones del simulador y el calendario.
  3. Tema automático: un tema claro y uno oscuro que siguen al sistema.
  4. Reducir desenfoque, para teléfonos lentos o mejor legibilidad.
  5. Vibración al tocar, encendida o apagada.
  6. Abrir con los montos ocultos.
- **Más adelante**: categorías personalizadas y borrar todos los datos.
- **Tamaño**: mediano; se puede entregar por partes.

## M10. Tipo de cuenta más claro (sugerencia del asistente)

- **Observado en la prueba**: la cuenta "Nu · Ahorro" quedó dada de alta como
  Débito, así que no cuenta como ahorro ni admite tasa.
- **Instrucción**: una línea de ayuda bajo el selector de tipo que explique
  cada uno, y sugerir "Ahorro" cuando el nombre diga ahorro, cajita o apartado.
- **Tamaño**: chico. Va junto con M4.
