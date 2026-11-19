// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'core_engine.dart';
import 'particle_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GLOBE PAINTER v5.0 // "HYPERFLUID BIOLUMINESCENT RENDERER"
// - Ascolta direttamente [NeuralSimulationEngine] via `super(repaint: engine)`
// - 0 allocazioni `MaskFilter.blur` e 0 `canvas.saveLayer` (Fast-Path GPU)
// - Supporta Level-of-Detail (LOD) adattivo automatico su qualsiasi dispositivo
// - Renderizza anelli orbitali, sinapsi, impulsi viaggianti e pillole olografiche
// ─────────────────────────────────────────────────────────────────────────────

class GlobePainter extends CustomPainter {
  final NeuralSimulationEngine engine;
  final double connectionDistance;
  final bool isActive;

  GlobePainter({
    required this.engine,
    this.connectionDistance = 175.0,
    this.isActive = false,
  }) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final bool highQuality = PerformanceMonitor.instance.highQuality.value;
    final List<Particle> sorted = engine.sortedParticles;

    // 1. ── NUCLEO BIO-LUMINESCENTE CENTRALE & ORBITE ──
    final double coreRadius = size.shortestSide * 0.36;
    final Paint nebulaPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        coreRadius * 1.35,
        [
          isActive
              ? AuroraPalette.cyan.withOpacity(0.11)
              : const Color(0xFF3B82F6).withOpacity(0.06),
          const Color(0xFF8B5CF6).withOpacity(isActive ? 0.05 : 0.025),
          Colors.transparent,
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(Offset.zero, coreRadius * 1.35, nebulaPaint);

    // Anelli orbitali sottili di riferimento spaziale
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.045);
    canvas.drawCircle(Offset.zero, coreRadius * 0.58, ringPaint);
    canvas.drawCircle(Offset.zero, coreRadius * 0.92, ringPaint);

    // 2. ── RETE SINAPTICA AD ALTA EFFICIENZA (Fast-Line Batching) ──
    final Paint synapsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double maxDistSq = connectionDistance * connectionDistance;
    final int len = sorted.length;

    for (int i = 0; i < len; i++) {
      final p1 = sorted[i];
      // Salta nodi completamente a riposo se non in modalità alta densità
      final bool p1Excited = p1.activation > 0.04 || p1.attentionWeight > 0.05;
      if (!p1Excited && (!highQuality || i % 3 != 0)) continue;

      for (int j = i + 1; j < len; j++) {
        final p2 = sorted[j];
        final bool p2Excited = p2.activation > 0.04 || p2.attentionWeight > 0.05;
        if (!p1Excited && !p2Excited) continue;

        final double dx = p1.screenPos.dx - p2.screenPos.dx;
        final double dy = p1.screenPos.dy - p2.screenPos.dy;
        final double distSq = dx * dx + dy * dy;
        if (distSq > maxDistSq) continue;

        final double distRatio = 1.0 - (distSq / maxDistSq);
        final double depthAlpha =
            ((p1.perspectiveScale + p2.perspectiveScale) * 0.5).clamp(0.25, 1.0);
        final double combinedAct = (p1.activation + p2.activation) * 0.5;
        final double combinedAtt = (p1.attentionWeight + p2.attentionWeight) * 0.5;

        Color lineColor;
        if (combinedAtt > 0.22) {
          lineColor = Color.lerp(
            const Color(0xFF3B82F6).withOpacity(0.14 * distRatio * depthAlpha),
            const Color(0xFFF43F5E).withOpacity(0.78 * distRatio * depthAlpha),
            combinedAtt,
          )!;
        } else {
          lineColor = Color.lerp(
            const Color(0xFF1D4ED8).withOpacity(0.12 * distRatio * depthAlpha),
            AuroraPalette.cyan.withOpacity(0.82 * distRatio * depthAlpha),
            combinedAct,
          )!;
        }

        synapsePaint.color = lineColor;
        synapsePaint.strokeWidth = (0.55 + combinedAct * 1.65) * depthAlpha;
        canvas.drawLine(p1.screenPos, p2.screenPos, synapsePaint);
      }
    }

    // 3. ── IMPULSI SINAPTICI LUMINOSI IN VIAGGIO ──
    for (final imp in engine.impulses) {
      if (imp.fromIdx >= engine.particles.length ||
          imp.toIdx >= engine.particles.length) {
        continue;
      }
      final pFrom = engine.particles[imp.fromIdx];
      final pTo = engine.particles[imp.toIdx];
      final Offset pos = Offset.lerp(pFrom.screenPos, pTo.screenPos, imp.progress)!;

      // Linea guida sottile dell'impulso
      canvas.drawLine(
        pFrom.screenPos,
        pTo.screenPos,
        Paint()
          ..color = imp.color.withOpacity(0.22 * (1.0 - imp.progress))
          ..strokeWidth = 1.1,
      );

      FastCanvasEffects.drawSoftGlowCircle(
        canvas,
        pos,
        3.2,
        imp.color,
        intensity: 0.9,
        rings: highQuality ? 3 : 2,
      );
      canvas.drawCircle(pos, 2.4, Paint()..color = Colors.white);
    }

    // 4. ── DISEGNO NODI NEURALI (Z-Ordered) + PILLOLE SEMANTICHE ──
    final Paint corePaint = Paint()..style = PaintingStyle.fill;
    final Paint specPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < len; i++) {
      final p = sorted[i];
      final double depth = p.perspectiveScale;
      final Color pColor = p.currentColor;
      final double pSize = p.size * depth * (1.0 + p.activation * 0.55);

      // Onda d'urto (Ripple) quando il neurone riceve un impulso forte
      if (p.ripplePhase > 0.05) {
        final double rippleR = pSize + (1.0 - p.ripplePhase) * 22.0 * depth;
        canvas.drawCircle(
          p.screenPos,
          rippleR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = AuroraPalette.cyan.withOpacity(p.ripplePhase * 0.55 * depth),
        );
      }

      // Halo multi-ring ad alte prestazioni (0 MaskFilter.blur!)
      if (p.activation > 0.05 || p.attentionWeight > 0.06) {
        final double intensity =
            ((p.activation * 0.85 + p.attentionWeight * 0.55) * depth).clamp(0.0, 1.0);
        FastCanvasEffects.drawSoftGlowCircle(
          canvas,
          p.screenPos,
          pSize * 1.4,
          pColor,
          intensity: intensity,
          rings: highQuality ? 3 : 2,
        );
      }

      // Nucleo solido del neurone
      corePaint.color = pColor.withOpacity((0.55 + depth * 0.45).clamp(0.0, 1.0));
      canvas.drawCircle(p.screenPos, pSize, corePaint);

      // Punto di luce speculare 3D sui nodi in primo piano
      if (depth > 0.68 && pSize > 1.8) {
        specPaint.color = Colors.white.withOpacity((0.45 + p.activation * 0.4) * depth);
        canvas.drawCircle(
          p.screenPos + Offset(-pSize * 0.26, -pSize * 0.26),
          pSize * 0.32,
          specPaint,
        );
      }

      // Etichetta semantica olografica pre-renderizzata via TextLayoutCache (0 saveLayer!)
      if (p.currentConcept != null && p.activation > 0.08 && depth > 0.58) {
        final double alpha = ((p.activation * 2.2).clamp(0.0, 1.0) * depth).clamp(0.15, 0.98);
        final Offset badgeCenter = p.screenPos + Offset(0, -pSize - 14.0 - p.ripplePhase * 4.0);
        TextLayoutCache.paintBadge(
          canvas,
          text: p.currentConcept!,
          center: badgeCenter,
          textColor: Colors.white.withOpacity(alpha),
          borderColor: AuroraPalette.cyan.withOpacity(alpha * 0.75),
          bgColor: const Color(0xFF070B19).withOpacity(alpha * 0.88),
          fontSize: 11.5 * depth.clamp(0.85, 1.15),
        );
      }
    }

    // 5. ── CURSORE CAMPO MAGNETICO (quando l'utente esplora la sfera) ──
    if (engine.hasMouse) {
      canvas.drawCircle(
        engine.mouseOffset,
        24,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = AuroraPalette.cyan.withOpacity(0.22),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) =>
      oldDelegate.isActive != isActive ||
      oldDelegate.connectionDistance != connectionDistance;
}
