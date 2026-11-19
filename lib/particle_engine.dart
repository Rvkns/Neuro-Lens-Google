// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'core_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE ENGINE v5.0 // "HYPERFLUID 3D NEURAL CORE"
// - Zero allocazioni per frame (z-sort in-place, Random condiviso, TextLayoutCache)
// - Campo magnetico interattivo: il cursore sposta ed eccita fisicamente i neuroni
// - Orbita 3D interattiva con inerzia fluida (trascina con mouse o touch)
// - Impulsi sinaptici luminosi che viaggiano lungo i collegamenti attivi
// ─────────────────────────────────────────────────────────────────────────────

class SynapticImpulse {
  int fromIdx;
  int toIdx;
  double progress; // 0.0 -> 1.0
  double speed;
  Color color;

  SynapticImpulse({
    required this.fromIdx,
    required this.toIdx,
    this.progress = 0.0,
    this.speed = 0.045,
    this.color = AuroraPalette.cyan,
  });
}

class Particle {
  static final Random _sharedRnd = Random();

  final int id;
  final double phi;    // Angolo polare (0..π)
  final double theta;  // Angolo azimutale (0..2π)
  final double radius; // Raggio sferico base
  final int layer;     // 0 = Core profondo, 1 = Corteccia media, 2 = Corteccia esterna

  double x3d = 0;
  double y3d = 0;
  double z3d = 0;

  Offset screenPos = Offset.zero;
  double perspectiveScale = 1.0;

  // Fisica elastica 2D per interazione col cursore/touch
  Offset springOffset = Offset.zero;
  Offset velocity = Offset.zero;
  final double baseMaxSpeed;
  final double size;

  // Attivazione & Attention Heatmap
  double activation = 0.0;
  double attentionWeight = 0.0;
  double ripplePhase = 0.0;
  String? currentConcept;

  Particle({
    required this.id,
    required this.phi,
    required this.theta,
    required this.radius,
    required this.layer,
    this.baseMaxSpeed = 0.8,
    this.size = 2.6,
  });

  void excite(double amount, {String? concept}) {
    activation = min(1.0, activation + amount);
    attentionWeight = min(1.0, attentionWeight + amount * 0.42);
    if (amount > 0.35) {
      ripplePhase = 1.0;
    }
    if (concept != null && concept.isNotEmpty) {
      currentConcept = concept;
    }
  }

  /// Proiezione 3D -> 2D + fisica elastica locale in un unico passaggio cache-friendly.
  void stepAndProject({
    required double sinX,
    required double cosX,
    required double sinY,
    required double cosY,
    required double breathScale,
    required Offset mouseOffset,
    required bool hasMouse,
  }) {
    // 1. Decadimento fisiologico
    activation = max(0.0, activation - 0.015);
    attentionWeight = max(0.0, attentionWeight - 0.0028);
    ripplePhase = max(0.0, ripplePhase - 0.038);

    if (activation < 0.05) {
      currentConcept = null;
    }

    // 2. Coordinate cartesiane sulla sfera con pulsazione armonica
    final double r = radius * breathScale * (1.0 + activation * 0.06);
    final double sinPhi = sin(phi);
    final double sx = r * sinPhi * cos(theta);
    final double sy = r * cos(phi);
    final double sz = r * sinPhi * sin(theta);

    // Rotazione asse Y (orizzontale)
    final double x1 = sx * cosY + sz * sinY;
    final double z1 = -sx * sinY + sz * cosY;

    // Rotazione asse X (verticale)
    final double y2 = sy * cosX - z1 * sinX;
    final double z2 = sy * sinX + z1 * cosX;

    x3d = x1;
    y3d = y2;
    z3d = z2;

    const double fov = 820.0;
    perspectiveScale = fov / (fov + z3d + radius);
    final Offset idealPos = Offset(x3d * perspectiveScale, y3d * perspectiveScale);

    // 3. Fisica elastica reattiva al cursore (repulsione magnetica + eccitazione)
    Offset force = -springOffset * 0.14; // Molla di richiamo verso la posizione sferica

    if (hasMouse) {
      final Offset currentPos = idealPos + springOffset;
      final double dx = currentPos.dx - mouseOffset.dx;
      final double dy = currentPos.dy - mouseOffset.dy;
      final double distSq = dx * dx + dy * dy;
      const double interactionRadius = 105.0;
      if (distSq < interactionRadius * interactionRadius && distSq > 1.0) {
        final double dist = sqrt(distSq);
        final double factor = (interactionRadius - dist) / interactionRadius;
        force += Offset((dx / dist) * factor * 3.2, (dy / dist) * factor * 3.2);
        // Il passaggio del mouse risveglia dolcemente i neuroni vicini
        if (activation < 0.35) {
          activation = min(0.45, activation + factor * 0.045);
        }
      }
    }

    if (activation > 0.18) {
      force += Offset(
        (_sharedRnd.nextDouble() - 0.5) * activation * 1.4,
        (_sharedRnd.nextDouble() - 0.5) * activation * 1.4,
      );
    }

    velocity = (velocity + force) * 0.82; // Smorzamento fluido
    springOffset += velocity;
    screenPos = idealPos + springOffset;
  }

  Color get currentColor {
    final Color base = layer == 0
        ? const Color(0xFF312E81) // Indigo profondo per il core
        : const Color(0xFF1E3A8A); // Blu reale per la corteccia
    const Color activated = AuroraPalette.cyan;
    const Color hotspot = Color(0xFFF43F5E); // Rosa/Corallo bioluminescente per Attention

    final Color mid = Color.lerp(base, activated, activation) ?? base;
    return Color.lerp(mid, hotspot, attentionWeight * 0.78) ?? mid;
  }
}

/// Motore di simulazione autonomo basato su [ChangeNotifier] per ridipingere solo il Canvas
/// senza mai ricostruire i widget dell'interfaccia (0 chiamate a `setState` durante il loop).
class NeuralSimulationEngine extends ChangeNotifier {
  final List<Particle> particles = [];
  final List<Particle> sortedParticles = [];
  final List<SynapticImpulse> impulses = [];
  final Random _rnd = Random();

  double rotX = 0.32;
  double rotY = 0.0;
  double _velRotX = 0.0;
  double _velRotY = 0.0;
  bool isDragging = false;

  Offset mouseOffset = Offset.zero;
  bool hasMouse = false;
  double _timePhase = 0.0;

  NeuralSimulationEngine({int count = 148}) {
    final double golden = pi * (3.0 - sqrt(5.0));
    for (int i = 0; i < count; i++) {
      final double y = 1.0 - (i / (count - 1)) * 2.0;
      final double theta = golden * i;
      final int layer = i % 5 == 0 ? 0 : (i % 2 == 0 ? 1 : 2);
      final double baseR = layer == 0
          ? 155.0 + _rnd.nextDouble() * 45.0
          : (layer == 1
              ? 245.0 + _rnd.nextDouble() * 45.0
              : 305.0 + _rnd.nextDouble() * 55.0);

      final p = Particle(
        id: i,
        phi: acos(y.clamp(-1.0, 1.0)),
        theta: theta,
        radius: baseR,
        layer: layer,
        baseMaxSpeed: 0.7 + _rnd.nextDouble() * 0.6,
        size: layer == 0 ? 3.4 : (2.4 + _rnd.nextDouble() * 2.6),
      );
      particles.add(p);
      sortedParticles.add(p);
    }
  }

  void onPointerHover(Offset localCentered) {
    mouseOffset = localCentered;
    hasMouse = true;
  }

  void onPointerExit() {
    hasMouse = false;
    isDragging = false;
  }

  void onPanUpdate(Offset delta) {
    isDragging = true;
    _velRotY = delta.dx * 0.0065;
    _velRotX = (-delta.dy * 0.0065).clamp(-0.08, 0.08);
    rotY += _velRotY;
    rotX = (rotX + _velRotX).clamp(-1.1, 1.1);
  }

  void onPanEnd() {
    isDragging = false;
  }

  /// Avanza di un frame la fisica 3D, ordina in-place per profondità e notifica solo il CustomPainter.
  void tick() {
    _timePhase += 0.022;

    if (!isDragging) {
      rotY += 0.0032 + _velRotY;
      rotX = (rotX + _velRotX).clamp(-1.1, 1.1);
      _velRotX *= 0.92;
      _velRotY *= 0.92;
    }

    final double breath = 1.0 + sin(_timePhase) * 0.045;
    final double sinX = sin(rotX), cosX = cos(rotX);
    final double sinY = sin(rotY), cosY = cos(rotY);

    for (int i = 0; i < particles.length; i++) {
      particles[i].stepAndProject(
        sinX: sinX,
        cosX: cosX,
        sinY: sinY,
        cosY: cosY,
        breathScale: breath,
        mouseOffset: mouseOffset,
        hasMouse: hasMouse,
      );
    }

    // Z-sort in-place (nessuna allocazione di memoria)
    sortedParticles.sort((a, b) => a.z3d.compareTo(b.z3d));

    // Aggiorna impulsi sinaptici viaggianti
    for (int i = impulses.length - 1; i >= 0; i--) {
      final imp = impulses[i];
      imp.progress += imp.speed;
      if (imp.progress >= 1.0) {
        impulses.removeAt(i);
      }
    }

    notifyListeners();
  }

  /// Eccita un cluster di neuroni e genera impulsi luminosi tra i nodi attivati.
  void exciteBurst(int intensity, {List<String>? concepts}) {
    final int count = min(intensity * 5 + 4, particles.length ~/ 3);
    final List<int> excitedIndices = [];

    // Limita il numero di etichette visibili contemporaneamente per massima leggibilità
    int activeLabels = particles.where((p) => p.currentConcept != null).length;

    for (int i = 0; i < count; i++) {
      final int idx = _rnd.nextInt(particles.length);
      excitedIndices.add(idx);

      String? conceptToAssign;
      if (concepts != null && concepts.isNotEmpty && activeLabels < 9 && i < 3) {
        conceptToAssign = concepts[i % concepts.length];
        activeLabels++;
      }

      particles[idx].excite(
        0.5 + _rnd.nextDouble() * 0.5,
        concept: conceptToAssign,
      );
    }

    // Crea impulsi sinaptici luminosi tra i nodi appena eccitati
    for (int i = 0; i + 1 < excitedIndices.length && impulses.length < 28; i++) {
      impulses.add(
        SynapticImpulse(
          fromIdx: excitedIndices[i],
          toIdx: excitedIndices[i + 1],
          speed: 0.035 + _rnd.nextDouble() * 0.035,
          color: i.isEven ? AuroraPalette.cyan : const Color(0xFFF43F5E),
        ),
      );
    }
  }
}
