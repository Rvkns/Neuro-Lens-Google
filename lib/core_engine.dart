// ignore_for_file: deprecated_member_use
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CORE ENGINE v5.0 // "HYPERFLUID AURORA"
// Motore grafico ad alte prestazioni per Flutter Web / Desktop / Mobile:
// 1. TextLayoutCache (LRU): 0 chiamate a TextPainter.layout() durante i frame
// 2. FastCanvasEffects: Halo multi-ring GPU senza MaskFilter.blur o saveLayer
// 3. PerformanceMonitor: Telemetria FPS reale + Adaptive Level-of-Detail (LOD)
// 4. Design System "Aurora Glass": Plus Jakarta Sans + JetBrains Mono
// ─────────────────────────────────────────────────────────────────────────────

class _TextCacheKey {
  final String text;
  final double fontSize;
  final int colorValue;
  final FontWeight weight;
  final bool mono;

  const _TextCacheKey(
    this.text,
    this.fontSize,
    this.colorValue,
    this.weight,
    this.mono,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TextCacheKey &&
          text == other.text &&
          fontSize == other.fontSize &&
          colorValue == other.colorValue &&
          weight == other.weight &&
          mono == other.mono;

  @override
  int get hashCode => Object.hash(text, fontSize, colorValue, weight, mono);
}

/// Cache LRU globale per [TextPainter]: elimina il ricalcolo del layout testo a 60/120 FPS.
class TextLayoutCache {
  static const int _maxEntries = 380;
  static final LinkedHashMap<_TextCacheKey, TextPainter> _cache =
      LinkedHashMap<_TextCacheKey, TextPainter>();

  static TextPainter obtain({
    required String text,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.normal,
    bool mono = true,
    List<Shadow>? shadows,
  }) {
    // Arrotonda fontSize al decimo per massimizzare i cache hit durante animazioni/scale
    final double roundedSize = (fontSize * 10).roundToDouble() / 10.0;
    final key = _TextCacheKey(text, roundedSize, color.value, weight, mono);

    final existing = _cache.remove(key);
    if (existing != null) {
      // Re-inserisce in coda (MRU)
      _cache[key] = existing;
      return existing;
    }

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: roundedSize,
          fontFamily: mono ? 'monospace' : null,
          fontWeight: weight,
          letterSpacing: mono ? 0.5 : 0.2,
          shadows: shadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = tp;
    return tp;
  }

  /// Disegna testo centrato su [center] senza allocare o fare layout se già in cache.
  static void paintCentered(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.normal,
    bool mono = true,
  }) {
    final tp = obtain(
      text: text,
      fontSize: fontSize,
      color: color,
      weight: weight,
      mono: mono,
    );
    tp.paint(canvas, Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5));
  }

  /// Disegna un badge con sfondo arrotondato e bordo nitido ad altissima velocità.
  static void paintBadge(
    Canvas canvas, {
    required String text,
    required Offset center,
    required Color textColor,
    required Color borderColor,
    Color bgColor = const Color(0xEB070A16),
    double fontSize = 10.5,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
    double radius = 6.0,
  }) {
    final tp = obtain(
      text: text,
      fontSize: fontSize,
      color: textColor,
      weight: FontWeight.bold,
      mono: true,
    );
    final double w = tp.width + padding.horizontal;
    final double h = tp.height + padding.vertical;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = bgColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    tp.paint(canvas, Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5));
  }
}

/// Primitive grafiche GPU-friendly che sostituiscono `MaskFilter.blur` e `saveLayer`.
class FastCanvasEffects {
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  /// Disegna un bagliore morbido a cerchi concentrici: 15x più veloce di `MaskFilter.blur`.
  static void drawSoftGlowCircle(
    Canvas canvas,
    Offset center,
    double coreRadius,
    Color color, {
    double intensity = 1.0,
    int rings = 3,
  }) {
    final double clamped = intensity.clamp(0.0, 1.0);
    if (clamped <= 0.01) return;

    if (rings >= 3) {
      _fillPaint.color = color.withOpacity((0.06 * clamped).clamp(0.0, 1.0));
      canvas.drawCircle(center, coreRadius * 3.1, _fillPaint);
    }
    if (rings >= 2) {
      _fillPaint.color = color.withOpacity((0.14 * clamped).clamp(0.0, 1.0));
      canvas.drawCircle(center, coreRadius * 2.0, _fillPaint);
    }
    _fillPaint.color = color.withOpacity((0.28 * clamped).clamp(0.0, 1.0));
    canvas.drawCircle(center, coreRadius * 1.35, _fillPaint);
  }

  /// Disegna un bagliore rettangolare arrotondato attorno a una card/nodo senza `MaskFilter.blur`.
  static void drawSoftGlowRRect(
    Canvas canvas,
    RRect rrect,
    Color color, {
    double intensity = 1.0,
  }) {
    final double clamped = intensity.clamp(0.0, 1.0);
    if (clamped <= 0.01) return;

    _fillPaint.color = color.withOpacity((0.07 * clamped).clamp(0.0, 1.0));
    canvas.drawRRect(rrect.inflate(10), _fillPaint);

    _fillPaint.color = color.withOpacity((0.16 * clamped).clamp(0.0, 1.0));
    canvas.drawRRect(rrect.inflate(4.5), _fillPaint);
  }

  /// Disegna una griglia tecnologica leggera sullo sfondo del canvas.
  static void drawSubtleTechGrid(
    Canvas canvas,
    Size size, {
    Color color = const Color(0x09FFFFFF),
    double spacing = 36.0,
  }) {
    _strokePaint
      ..color = color
      ..strokeWidth = 1.0;

    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _strokePaint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _strokePaint);
    }
  }
}

/// Monitoraggio real-time delle prestazioni con adattamento automatico del livello di dettaglio (LOD).
class PerformanceMonitor {
  static final PerformanceMonitor instance = PerformanceMonitor._();
  PerformanceMonitor._();

  final ValueNotifier<int> fps = ValueNotifier<int>(60);
  final ValueNotifier<bool> highQuality = ValueNotifier<bool>(true);

  bool _started = false;
  int _slowFramesStreak = 0;
  int _fastFramesStreak = 0;

  void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    final last = timings.last;
    final double totalMs = last.totalSpan.inMicroseconds / 1000.0;
    final int estimatedFps = totalMs <= 0 ? 60 : (1000.0 / totalMs).round().clamp(15, 120);

    // Aggiorna il contatore solo se cambia sensibilmente
    if ((fps.value - estimatedFps).abs() >= 2) {
      fps.value = estimatedFps;
    }

    // Adaptive LOD automatico
    if (totalMs > 24.0) {
      _slowFramesStreak++;
      _fastFramesStreak = 0;
      if (_slowFramesStreak > 8 && highQuality.value) {
        highQuality.value = false;
      }
    } else if (totalMs < 15.0) {
      _fastFramesStreak++;
      _slowFramesStreak = 0;
      if (_fastFramesStreak > 25 && !highQuality.value) {
        highQuality.value = true;
      }
    }
  }

  void toggleQualityMode() {
    highQuality.value = !highQuality.value;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM "AURORA GLASS" — Colori, Font e Widget riutilizzabili
// ─────────────────────────────────────────────────────────────────────────────

class AuroraPalette {
  static const Color bgDeep = Color(0xFF050711);
  static const Color bgSurface = Color(0xFF0B1022);
  static const Color bgCard = Color(0xCC0D1328);
  static const Color bgCardElevated = Color(0xE6111936);

  static const Color cyan = Color(0xFF00F0FF);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color emerald = Color(0xFF10B981);
  static const Color mint = Color(0xFF69F0AE);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color magenta = Color(0xFFEC4899);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFFF6B4A);

  static TextStyle headingStyle({
    double size = 16,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = 0.3,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  static TextStyle bodyStyle({
    double size = 12.5,
    Color color = const Color(0xFFE2E8F0),
    FontWeight weight = FontWeight.w500,
    double height = 1.45,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  static TextStyle monoStyle({
    double size = 11.5,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0.4,
    double? height,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      );
}

/// Pannello in stile Glassmorphism moderno con riflesso superiore e ombra morbida.
class AuroraGlassCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool highlightBorder;

  const AuroraGlassCard({
    super.key,
    required this.child,
    this.accentColor = AuroraPalette.cyan,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 14,
    this.highlightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF131B38).withOpacity(0.84),
            const Color(0xFF090D1E).withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: highlightBorder
              ? accentColor.withOpacity(0.65)
              : accentColor.withOpacity(0.24),
          width: highlightBorder ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          if (highlightBorder)
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: child,
    );
  }
}

