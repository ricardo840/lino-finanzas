import 'package:flutter/cupertino.dart';

/// Paleta y tipografía de un tema de Lino (estilo glassmorfismo sobre
/// componentes Cupertino).
class LinoTema {
  const LinoTema({
    required this.id,
    required this.nombre,
    required this.brillo,
    required this.fondo,
    required this.manchas,
    required this.acento,
    required this.sobreAcento,
    required this.texto,
    required this.textoSecundario,
    required this.vidrio,
    required this.vidrioAlto,
    required this.bordeVidrio,
    required this.campo,
    required this.barra,
    required this.hoja,
    required this.positivo,
    required this.negativo,
    required this.advertencia,
  });

  final String id;
  final String nombre;
  final Brightness brillo;

  /// Degradado del fondo (3 colores).
  final List<Color> fondo;

  /// Manchas difuminadas detrás del vidrio (3 colores).
  final List<Color> manchas;
  final Color acento;

  /// Texto sobre el color de acento.
  final Color sobreAcento;
  final Color texto;
  final Color textoSecundario;

  /// Relleno de los paneles de vidrio.
  final Color vidrio;

  /// Relleno más opaco (brillo superior del vidrio).
  final Color vidrioAlto;
  final Color bordeVidrio;

  /// Relleno de campos de texto.
  final Color campo;

  /// Fondo translúcido de barras de navegación y pestañas.
  final Color barra;

  /// Fondo de hojas modales (selectores de fecha, etc.).
  final Color hoja;
  final Color positivo;
  final Color negativo;
  final Color advertencia;

  bool get esOscuro => brillo == Brightness.dark;

  TextStyle get titulo => TextStyle(
        color: texto,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      );

  TextStyle get subtitulo => TextStyle(
        color: texto,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  TextStyle get cuerpo => TextStyle(color: texto, fontSize: 15, letterSpacing: -0.2);

  TextStyle get secundario =>
      TextStyle(color: textoSecundario, fontSize: 13, letterSpacing: -0.1);

  /// Etiquetas en mayúsculas sobre secciones y campos.
  TextStyle get etiqueta => TextStyle(
        color: textoSecundario,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      );

  TextStyle get monto => TextStyle(
        color: texto,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  TextStyle get montoGrande => TextStyle(
        color: texto,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      );

  CupertinoThemeData get cupertino => CupertinoThemeData(
        brightness: brillo,
        primaryColor: acento,
        primaryContrastingColor: sobreAcento,
        scaffoldBackgroundColor: fondo.first,
        barBackgroundColor: barra,
        textTheme: CupertinoTextThemeData(
          primaryColor: acento,
          textStyle: TextStyle(color: texto, fontSize: 16, letterSpacing: -0.3),
          actionTextStyle: TextStyle(color: acento, fontSize: 17, letterSpacing: -0.4),
          navActionTextStyle: TextStyle(color: acento, fontSize: 17, letterSpacing: -0.4),
          navTitleTextStyle: TextStyle(
            color: texto,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: texto,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
          pickerTextStyle: TextStyle(color: texto, fontSize: 21, letterSpacing: -0.6),
          dateTimePickerTextStyle: TextStyle(color: texto, fontSize: 21, letterSpacing: -0.6),
        ),
      );
}

/// Pone el tema activo al alcance de cualquier widget con `context.tema`,
/// junto con las preferencias de interfaz que los widgets necesitan sin
/// depender de Riverpod.
class LinoTemaScope extends InheritedWidget {
  const LinoTemaScope({
    super.key,
    required this.tema,
    this.reducirDesenfoque = false,
    this.vibracion = true,
    required super.child,
  });

  final LinoTema tema;

  /// Los paneles de vidrio se dibujan sin desenfoque.
  final bool reducirDesenfoque;

  /// Respuesta háptica al tocar.
  final bool vibracion;

  static LinoTemaScope? alcanceDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LinoTemaScope>();

  static LinoTema? maybeOf(BuildContext context) => alcanceDe(context)?.tema;

  @override
  bool updateShouldNotify(LinoTemaScope oldWidget) =>
      oldWidget.tema != tema ||
      oldWidget.reducirDesenfoque != reducirDesenfoque ||
      oldWidget.vibracion != vibracion;
}
