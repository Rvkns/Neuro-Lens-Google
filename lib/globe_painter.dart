import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'particle_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GLOBE PAINTER v3.0 — Rendering 3D con z-sort, sinapsi e Attention Heatmap
// ─────────────────────────────────────────────────────────────────────────────

class GlobePainter extends CustomPainter {
  final List<Particle> particles;
  final double connectionDistance;
  final bool isActive;

  // Lista di particelle già ordinata per profondità (z-sort) — calcolata fuori dal paint
  final List<Particle> sortedParticles;

  GlobePainter({
    required this.particles,
    this.connectionDistance = 180.0,
    this.isActive = false,
  }) : sortedParticles = List<Particle>.from(particles)
          ..sort((a, b) => a.z3d.compareTo(b.z3d)); // z piccolo = dietro = prima

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    // ── Paint per le sinapsi ──
    final Paint synapsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // ── Paint per il bagliore (blurred glow) ──
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill;

    // ── Paint per il nucleo solido ──
    final Paint corePaint = Paint()..style = PaintingStyle.fill;

    // 1. ── DISEGNO SINAPSI (iterazione N^2 su 150 nodi = 11.250 coppie, veloce) ──
    for (int i = 0; i < sortedParticles.length; i++) {
      final p1 = sortedParticles[i];
      for (int j = i + 1; j < sortedParticles.length; j++) {
        final p2 = sortedParticles[j];

        // OTTIMIZZAZIONE BROWSER: disegna linee solo tra nodi in cui almeno uno è attivato
        if (p1.activation < 0.02 && p1.attentionWeight < 0.02 &&
            p2.activation < 0.02 && p2.attentionWeight < 0.02) {
          continue;
        }

        // Distanza 2D proiettata sullo schermo
        final double dist = (p1.screenPos - p2.screenPos).distance;
        if (dist > connectionDistance) continue;

        // Opacità dipende da distanza e profondità media (z lontano = più trasparente)
        double distAlpha = 1.0 - (dist / connectionDistance);
        double depthAlpha = ((p1.perspectiveScale + p2.perspectiveScale) / 2).clamp(0.3, 1.0);
        double combinedActivation = (p1.activation + p2.activation) / 2.0;
        double combinedAttention = (p1.attentionWeight + p2.attentionWeight) / 2.0;

        // Colore sinapsi: blu strutturale → ciano (attivazione) → arancio (attention)
        Color synapseColor;
        if (combinedAttention > 0.2) {
          synapseColor = Color.lerp(
            const Color(0xFF1565C0).withOpacity(0.12 * distAlpha * depthAlpha),
            const Color(0xFFFF6B35).withOpacity(0.85 * distAlpha * depthAlpha),
            combinedAttention,
          )!;
        } else {
          synapseColor = Color.lerp(
            const Color(0xFF0D47A1).withOpacity(0.10 * distAlpha * depthAlpha),
            Colors.cyanAccent.withOpacity(0.9 * distAlpha * depthAlpha),
            combinedActivation,
          )!;
        }

        synapsePaint.color = synapseColor;
        synapsePaint.strokeWidth = (0.4 + combinedActivation * 1.8) * depthAlpha;

        // Disegno la sinapsi come curva organica spinta verso il centro
        final Path path = Path();
        path.moveTo(p1.screenPos.dx, p1.screenPos.dy);
        
        final Offset midPoint = Offset(
          (p1.screenPos.dx + p2.screenPos.dx) / 2,
          (p1.screenPos.dy + p2.screenPos.dy) / 2,
        );
        // Spingiamo il punto di controllo del 20% verso l'origine (0,0)
        final Offset controlPoint = Offset(
          midPoint.dx * 0.8,
          midPoint.dy * 0.8,
        );
        
        path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, p2.screenPos.dx, p2.screenPos.dy);
        canvas.drawPath(path, synapsePaint);
      }
    }

    // 2. ── DISEGNO NODI (dal più lontano al più vicino — z-sort garantisce l'ordine) ──
    for (final p in sortedParticles) {
      final double depth = p.perspectiveScale;
      final Color pColor = p.currentColor;
      final double pSize = p.size * depth * (1.0 + p.activation * 0.5);

      // Bagliore esterno sfocato (più intenso con l'attivazione)
      if (p.activation > 0.05 || p.attentionWeight > 0.05) {
        double glowRadius = pSize * (3.5 + p.activation * 3.0 + p.attentionWeight * 2.0);
        glowPaint.color = pColor.withOpacity((0.15 + p.activation * 0.4) * depth);
        glowPaint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          (4.0 + p.activation * 4.0) * depth,
        );
        canvas.drawCircle(p.screenPos, glowRadius, glowPaint);
        glowPaint.maskFilter = null;
      }

      // Nucleo solido con opacità modulata dalla profondità
      corePaint.color = pColor.withOpacity((0.6 + depth * 0.4).clamp(0.0, 1.0));
      canvas.drawCircle(p.screenPos, pSize, corePaint);

      // Riflesso speculare (piccolo punto bianco in alto a sinistra — effetto 3D)
      if (depth > 0.7 && pSize > 1.5) {
        final Paint specularPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withOpacity(0.35 * depth);
        canvas.drawCircle(
          p.screenPos + Offset(-pSize * 0.25, -pSize * 0.25),
          pSize * 0.28,
          specularPaint,
        );
      }


      // ── ETICHETTA SEMANTICA OLOGRAFICA FLUTTUANTE ──
      if (p.labelPainter != null && p.activation > 0.05) {
        // Opacità basata su attivazione e profondità
        double labelAlpha = (p.activation * 2.5).clamp(0.0, 1.0) * depth;
        if (depth < 0.6) labelAlpha *= 0.3;

        if (labelAlpha > 0.05) {
          canvas.save();
          // Posizioniamo, scaliamo e facciamo "fluttuare" leggermente il testo col ripple
          double floatY = -p.ripplePhase * 5.0;
          canvas.translate(p.screenPos.dx + pSize + 8.0, p.screenPos.dy - (p.labelPainter!.height * depth) / 2 + floatY);
          canvas.scale(depth * (1.0 + p.ripplePhase * 0.15)); // Piccolo bump di scala iniziale
          
          canvas.saveLayer(
            Rect.fromLTWH(-30, -30, p.labelPainter!.width + 60, p.labelPainter!.height + 60),
            Paint()..color = Colors.white.withOpacity(labelAlpha),
          );
          
          // L'ombra al neon intensa è già definita nel TextStyle in ParticleEngine!
          p.labelPainter!.paint(canvas, Offset.zero);
          
          canvas.restore(); // Chiude il saveLayer
          canvas.restore(); // Chiude il translate/scale
        }
      }
    }

    // 3. ── ALONE NEBULARE DEL GLOBO (fondo) ──
    if (isActive) {
      final Rect rect = Rect.fromCircle(center: Offset.zero, radius: 500); // Aumentato da 220 a 500
      final Paint nebulaPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          500, // Aumentato a 500
          [
            Colors.cyanAccent.withOpacity(0.04),
            Colors.transparent,
          ],
          [0.3, 1.0],
        );
      canvas.drawRect(rect, nebulaPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) => true;
}
