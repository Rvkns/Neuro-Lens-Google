import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE ENGINE v3.0 — Nodi neurali su sfera 3D con sistema di Attenzione
// ─────────────────────────────────────────────────────────────────────────────

/// Un singolo nodo neurale posizionato su una sfera in 3 dimensioni.
class Particle {
  // ── Coordinate sferiche native (immutabili) ──
  final double phi;    // Angolo polare (da 0 a π)
  final double theta;  // Angolo azimutale (da 0 a 2π)
  final double radius; // Raggio nella sfera

  // ── Posizione 3D calcolata dalla rotazione del globo ──
  double x3d = 0;
  double y3d = 0;
  double z3d = 0;

  // ── Posizione 2D proiettata su schermo ──
  Offset screenPos = Offset.zero;
  double perspectiveScale = 1.0;

  // ── Fisica di perturbazione locale (scostamento dalla sfera ideale) ──
  Offset velocity = Offset.zero;
  Offset acceleration = Offset.zero;
  final double baseMaxSpeed;
  final double maxForce;

  // ── Sistema di Attenzione ──
  double activation = 0.0;      // Eccitazione immediata (decade veloce)
  double attentionWeight = 0.0;  // Peso accumulato (decade lento — Heatmap)
  String? currentConcept;        // Etichetta semantica assegnata temporaneamente
  TextPainter? labelPainter;     // OTTIMIZZAZIONE 2: Painter pre-compilato

  // ── Visuale ──
  final double size;

  Particle({
    required this.phi,
    required this.theta,
    required this.radius,
    this.baseMaxSpeed = 0.8,
    this.maxForce = 0.04,
    this.size = 2.0,
  });

  /// Applica una forza al vettore di accelerazione 2D (perturbazione schermo).
  void applyForce(Offset force) {
    acceleration += force;
  }

  /// Eccita il nodo: aumenta sia l'attivazione immediata che il peso storico.
  void excite(double amount, {String? concept}) {
    activation = min(1.0, activation + amount);
    attentionWeight = min(1.0, attentionWeight + amount * 0.4);
    if (concept != null && concept != currentConcept) {
      currentConcept = concept;
      // OTTIMIZZAZIONE 2: Pre-calcoliamo il testo una volta sola,
      // anziché ricalcolarlo 60 volte al secondo nel Paint.
      labelPainter = TextPainter(
        text: TextSpan(
          text: '[$concept]',
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 16.0, // Font aumentato dell'80% per massima visibilità
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
  }

  /// Aggiorna la proiezione 3D in base alla rotazione globale corrente.
  /// [rotX] e [rotY] sono gli angoli di rotazione del globo in radianti.
  void updateProjection(double rotX, double rotY, double breathScale) {
    // Coordinate cartesiane della posizione sull'anello sferico
    double r = radius * breathScale;
    double sx = r * sin(phi) * cos(theta);
    double sy = r * cos(phi);
    double sz = r * sin(phi) * sin(theta);

    // Rotazione attorno all'asse Y (rotazione orizzontale del globo)
    double cosY = cos(rotY), sinY = sin(rotY);
    double x1 = sx * cosY + sz * sinY;
    double z1 = -sx * sinY + sz * cosY;
    double y1 = sy;

    // Rotazione attorno all'asse X (lieve inclinazione verticale statica)
    double cosX = cos(rotX), sinX = sin(rotX);
    double y2 = y1 * cosX - z1 * sinX;
    double z2 = y1 * sinX + z1 * cosX;

    x3d = x1;
    y3d = y2;
    z3d = z2;

    // Proiezione prospettica: z più lontano → particella più piccola e buia
    double fov = 800.0; // Aumentato il campo visivo per la sfera allargata
    perspectiveScale = fov / (fov + z3d + radius);
    screenPos = Offset(x3d * perspectiveScale, y3d * perspectiveScale);
  }

  /// Aggiorna la fisica di perturbazione 2D e i valori di attivazione.
  void update(Offset mouseOffset) {
    // Decadimento fisiologico dell'attivazione
    activation = max(0.0, activation - 0.018);
    // L'attention weight decade molto più lentamente (memoria storica)
    attentionWeight = max(0.0, attentionWeight - 0.003);

    // Se l'attivazione scende sotto una soglia, dimentica il concetto
    if (activation < 0.05) {
      currentConcept = null;
      labelPainter = null;
    }

    // Forza di repulsione dal cursore del mouse
    double mouseDist = (screenPos - mouseOffset).distance;
    if (mouseDist < 80 && mouseDist > 0) {
      Offset repulsion = (screenPos - mouseOffset) / mouseDist;
      double strength = (80 - mouseDist) / 80 * 2.5;
      applyForce(repulsion * strength);
    }

    // Forza di ritorno al centro 2D (elastico leggero)
    if (screenPos.distance > 2) {
      Offset toCenter = -screenPos;
      double d = toCenter.distance;
      Offset desired = (toCenter / d) * (baseMaxSpeed + activation * 3.0);
      Offset steer = desired - velocity;
      if (steer.distance > maxForce) {
        steer = (steer / steer.distance) * maxForce;
      }
      applyForce(steer);
    }

    // Vibrazione caotica durante alta attivazione
    if (activation > 0.1) {
      final r = Random();
      applyForce(Offset(
        (r.nextDouble() - 0.5) * activation * 4.0,
        (r.nextDouble() - 0.5) * activation * 4.0,
      ));
    }

    velocity += acceleration;
    // Limita velocità massima
    if (velocity.distance > baseMaxSpeed + activation * 4) {
      velocity = (velocity / velocity.distance) * (baseMaxSpeed + activation * 4);
    }
    // NON aggiorniamo screenPos dalla fisica — viene calcolata dall'updateProjection
    // La velocità si usa solo per perturbazioni interne
    acceleration = Offset.zero;
  }

  /// Calcola il colore finale basandosi su attivazione immediata e peso attention.
  Color get currentColor {
    // Base blu scuro → ciano (attivazione) → arancio/rosso (attention cumulativa)
    Color base = const Color(0xFF0D2B6B);
    Color activated = Colors.cyanAccent;
    Color hotspot = const Color(0xFFFF6B35); // Arancio "caldo"

    // Prima miscela attivazione immediata
    Color mid = Color.lerp(base, activated, activation) ?? base;
    // Poi sovrapponi il peso storico (heatmap attention)
    return Color.lerp(mid, hotspot, attentionWeight * 0.7) ?? mid;
  }
}
