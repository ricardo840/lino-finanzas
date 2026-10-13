import 'package:flutter/cupertino.dart';

import 'lino_tema.dart';

// Colores compartidos ------------------------------------------------------

const _textoOscuro = Color(0xFFF4F6FB);
const _secundarioOscuro = Color(0xA6E6E9F2);
const _textoClaro = Color(0xFF15171E);
const _secundarioClaro = Color(0x9915171E);

LinoTema _oscuro({
  required String id,
  required String nombre,
  required List<Color> fondo,
  required List<Color> manchas,
  required Color acento,
}) =>
    LinoTema(
      id: id,
      nombre: nombre,
      brillo: Brightness.dark,
      fondo: fondo,
      manchas: manchas,
      acento: acento,
      sobreAcento: const Color(0xFF0B0D12),
      texto: _textoOscuro,
      textoSecundario: _secundarioOscuro,
      vidrio: const Color(0x12FFFFFF),
      vidrioAlto: const Color(0x24FFFFFF),
      bordeVidrio: const Color(0x2EFFFFFF),
      campo: const Color(0x14FFFFFF),
      barra: fondo.first.withValues(alpha: 0.72),
      hoja: Color.alphaBlend(const Color(0x1AFFFFFF), fondo[1]),
      positivo: const Color(0xFF4ADE80),
      negativo: const Color(0xFFF87171),
      advertencia: const Color(0xFFFBBF24),
    );

LinoTema _claro({
  required String id,
  required String nombre,
  required List<Color> fondo,
  required List<Color> manchas,
  required Color acento,
}) =>
    LinoTema(
      id: id,
      nombre: nombre,
      brillo: Brightness.light,
      fondo: fondo,
      manchas: manchas,
      acento: acento,
      sobreAcento: const Color(0xFFFFFFFF),
      texto: _textoClaro,
      textoSecundario: _secundarioClaro,
      vidrio: const Color(0x73FFFFFF),
      vidrioAlto: const Color(0xB3FFFFFF),
      bordeVidrio: const Color(0xD9FFFFFF),
      campo: const Color(0x99FFFFFF),
      barra: fondo.first.withValues(alpha: 0.78),
      hoja: Color.alphaBlend(const Color(0xCCFFFFFF), fondo[1]),
      positivo: const Color(0xFF15803D),
      negativo: const Color(0xFFDC2626),
      advertencia: const Color(0xFFB45309),
    );

// Catálogo -----------------------------------------------------------------

final List<LinoTema> temasLino = [
  _oscuro(
    id: 'medianoche',
    nombre: 'Medianoche',
    fondo: const [Color(0xFF070B1E), Color(0xFF0F1736), Color(0xFF050816)],
    manchas: const [Color(0xFF1E3A8A), Color(0xFF4338CA), Color(0xFF0E7490)],
    acento: const Color(0xFF8DA2FF),
  ),
  _oscuro(
    id: 'grafito',
    nombre: 'Grafito',
    fondo: const [Color(0xFF0E1015), Color(0xFF171A21), Color(0xFF0A0B0F)],
    manchas: const [Color(0xFF2B3A55), Color(0xFF3B3355), Color(0xFF1F4545)],
    acento: const Color(0xFF9DB7FF),
  ),
  _oscuro(
    id: 'esmeralda',
    nombre: 'Esmeralda',
    fondo: const [Color(0xFF06140F), Color(0xFF0B231C), Color(0xFF04100C)],
    manchas: const [Color(0xFF065F46), Color(0xFF0F766E), Color(0xFF3F6212)],
    acento: const Color(0xFF34D399),
  ),
  _oscuro(
    id: 'ambar',
    nombre: 'Ámbar',
    fondo: const [Color(0xFF140D06), Color(0xFF22160B), Color(0xFF0F0904)],
    manchas: const [Color(0xFF92400E), Color(0xFF7C2D12), Color(0xFF78350F)],
    acento: const Color(0xFFFBBF24),
  ),
  _oscuro(
    id: 'amatista',
    nombre: 'Amatista',
    fondo: const [Color(0xFF120A1C), Color(0xFF1D1030), Color(0xFF0C0614)],
    manchas: const [Color(0xFF6D28D9), Color(0xFFBE185D), Color(0xFF4C1D95)],
    acento: const Color(0xFFC4A1FF),
  ),
  _claro(
    id: 'primavera',
    nombre: 'Primavera',
    fondo: const [Color(0xFFF3FBF5), Color(0xFFFDF2F6), Color(0xFFEFF8F1)],
    manchas: const [Color(0xFFA7F3D0), Color(0xFFFBCFE8), Color(0xFFD9F99D)],
    acento: const Color(0xFF059669),
  ),
  _claro(
    id: 'verano',
    nombre: 'Verano',
    fondo: const [Color(0xFFFFF8EC), Color(0xFFFFF1E6), Color(0xFFEFF8FF)],
    manchas: const [Color(0xFFFDE68A), Color(0xFFFDBA74), Color(0xFF7DD3FC)],
    acento: const Color(0xFFEA580C),
  ),
  _claro(
    id: 'otono',
    nombre: 'Otoño',
    fondo: const [Color(0xFFFBF4EC), Color(0xFFF6EBDD), Color(0xFFFAF1E8)],
    manchas: const [Color(0xFFFDBA74), Color(0xFFD6A77A), Color(0xFFF59E0B)],
    acento: const Color(0xFFB45309),
  ),
  _claro(
    id: 'invierno',
    nombre: 'Invierno',
    fondo: const [Color(0xFFF4F8FC), Color(0xFFEAF2FA), Color(0xFFF7FAFD)],
    manchas: const [Color(0xFFBFDBFE), Color(0xFFC7D2FE), Color(0xFFA5F3FC)],
    acento: const Color(0xFF2563EB),
  ),
];

const String temaPorDefectoId = 'medianoche';

/// Tema claro que se usa de día cuando se sigue al sistema.
const String temaClaroPorDefectoId = 'invierno';

LinoTema temaPorId(String id) =>
    temasLino.firstWhere((t) => t.id == id, orElse: () => temasLino.first);

/// Degradados para distinguir cuentas y tarjetas.
const List<List<Color>> paletaCuentas = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
  [Color(0xFF10B981), Color(0xFF84CC16)],
  [Color(0xFFF59E0B), Color(0xFFEF4444)],
  [Color(0xFFEC4899), Color(0xFFF43F5E)],
  [Color(0xFF64748B), Color(0xFF94A3B8)],
  [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
  // El color se guarda como posición en esta lista: los nuevos van al final.
  [Color(0xFF111827), Color(0xFF374151)], // 8 negro
  [Color(0xFF71717A), Color(0xFFA1A1AA)], // 9 plata
  [Color(0xFFB91C1C), Color(0xFFEF4444)], // 10 rojo
  [Color(0xFF7F1D1D), Color(0xFFBE123C)], // 11 vino
  [Color(0xFFC2410C), Color(0xFFFB923C)], // 12 naranja
  [Color(0xFF065F46), Color(0xFF10B981)], // 13 verde oscuro
  [Color(0xFF1E3A8A), Color(0xFF2563EB)], // 14 azul marino
  [Color(0xFF0F766E), Color(0xFF2DD4BF)], // 15 turquesa
  [Color(0xFF4C1D95), Color(0xFF7C3AED)], // 16 morado
  [Color(0xFF92400E), Color(0xFFD97706)], // 17 dorado
];

/// Color que se propone al elegir un banco conocido, o null si no hay uno.
int? colorDeBanco(String banco) => switch (banco.trim().toLowerCase()) {
      'nu' => 16,
      'bbva' => 14,
      'banorte' => 10,
      'santander' => 11,
      'banamex' => 1,
      'hsbc' => 10,
      'mercado pago' => 1,
      'hey banco' => 8,
      'stori' => 15,
      'klar' => 13,
      'spin' => 6,
      'didi' => 12,
      'plata' => 9,
      _ => null,
    };

List<Color> coloresCuenta(int indice) =>
    paletaCuentas[indice.abs() % paletaCuentas.length];
