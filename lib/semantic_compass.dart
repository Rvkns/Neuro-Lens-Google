// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'core_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEMANTIC COMPASS v5.0 // "AURORA VECTOR RADAR"
// - 0 TextPainter.layout() per frame (usa TextLayoutCache)
// - 0 MaskFilter.blur (usa FastCanvasEffects GPU Fast-Path)
// - RepaintBoundary + CustomPainter(repaint: _rotController) senza rebuild widget
// ─────────────────────────────────────────────────────────────────────────────

class SemanticWord {
  final String word;
  final double distance; // 0.0 (identica) -> 1.0 (lontana)
  final SemanticRelation relation;
  final double orbitAngle;

  SemanticWord({
    required this.word,
    required this.distance,
    required this.relation,
    required this.orbitAngle,
  });
}

enum SemanticRelation {
  synonym,
  hypernym,
  hyponym,
  antonym,
  related,
}

extension SemanticRelationStyle on SemanticRelation {
  Color get color {
    switch (this) {
      case SemanticRelation.synonym:
        return AuroraPalette.mint;
      case SemanticRelation.hypernym:
        return AuroraPalette.cyan;
      case SemanticRelation.hyponym:
        return const Color(0xFF38BDF8);
      case SemanticRelation.antonym:
        return const Color(0xFFF43F5E);
      case SemanticRelation.related:
        return const Color(0xFFA78BFA);
    }
  }

  String get label {
    switch (this) {
      case SemanticRelation.synonym:
        return 'Sinonimi';
      case SemanticRelation.hypernym:
        return 'Categorie';
      case SemanticRelation.hyponym:
        return 'Sottotipi';
      case SemanticRelation.antonym:
        return 'Opposti';
      case SemanticRelation.related:
        return 'Correlati';
    }
  }
}

class SemanticCompass extends StatefulWidget {
  final String currentToken;
  final List<SemanticWord> neighbors;
  final bool isActive;
  final bool isBeginnerMode;

  const SemanticCompass({
    super.key,
    required this.currentToken,
    required this.neighbors,
    this.isActive = false,
    this.isBeginnerMode = true,
  });

  @override
  State<SemanticCompass> createState() => _SemanticCompassState();
}

class _SemanticCompassState extends State<SemanticCompass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotController;

  @override
  void initState() {
    super.initState();
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _rotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraGlassCard(
      accentColor: AuroraPalette.violet,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AuroraPalette.violet.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  size: 15,
                  color: Color(0xFFC4B5FD),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBeginnerMode
                          ? '③b. MAPPA PAROLE AMICHE'
                          : '③b. EMBEDDING SPACE (t-SNE)',
                      style: AuroraPalette.headingStyle(
                        size: 12,
                        color: const Color(0xFFC4B5FD),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.isBeginnerMode
                          ? 'Più sono vicine al centro, più il significato è simile'
                          : 'Proiezione coseno-vettoriale in tempo reale',
                      style: AuroraPalette.bodyStyle(
                        size: 10.5,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CompassPainter(
                  rotationAnim: _rotController,
                  currentToken: widget.currentToken,
                  neighbors: widget.neighbors,
                  isActive: widget.isActive,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.0,
            runSpacing: 4.0,
            children: SemanticRelation.values
                .map(
                  (r) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: r.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        r.label,
                        style: AuroraPalette.bodyStyle(
                          size: 10,
                          color: r.color,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final Animation<double> rotationAnim;
  final String currentToken;
  final List<SemanticWord> neighbors;
  final bool isActive;

  _CompassPainter({
    required this.rotationAnim,
    required this.currentToken,
    required this.neighbors,
    required this.isActive,
  }) : super(repaint: rotationAnim);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    final double maxRadius = max(24.0, min(size.width, size.height) * 0.5 - 26.0);
    final double slowRotation = rotationAnim.value * 2 * pi;

    // Cerchi concentrici radar
    final Paint orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFA78BFA).withOpacity(0.11)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3.0), orbitPaint);
    }

    // Assi cartesiani sottili
    final Paint axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(10, center.dy), Offset(size.width - 10, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 8), Offset(center.dx, size.height - 8), axisPaint);

    TextLayoutCache.paintCentered(
      canvas,
      text: 'dim₁',
      center: Offset(size.width - 22, center.dy - 10),
      fontSize: 9.5,
      color: Colors.white38,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: 'dim₂',
      center: Offset(center.dx + 18, 12),
      fontSize: 9.5,
      color: Colors.white38,
    );

    if (currentToken.isEmpty) {
      TextLayoutCache.paintCentered(
        canvas,
        text: 'Clicca una domanda per esplorare i vettori...',
        center: center,
        fontSize: 11,
        color: Colors.white54,
        mono: false,
      );
      return;
    }

    // Satelliti semantici
    for (final neighbor in neighbors) {
      final double angle = neighbor.orbitAngle + slowRotation * 0.15;
      final double r = maxRadius * (0.28 + neighbor.distance * 0.65);
      final Offset pos = Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);

      canvas.drawLine(
        center,
        pos,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = neighbor.relation.color.withOpacity(0.45)
          ..strokeWidth = 1.4,
      );

      FastCanvasEffects.drawSoftGlowCircle(
        canvas,
        pos,
        5.0,
        neighbor.relation.color,
        intensity: 0.75,
        rings: 2,
      );
      canvas.drawCircle(pos, 4.5, Paint()..color = neighbor.relation.color);

      final int simPct = ((1.0 - neighbor.distance * 0.6) * 100).round().clamp(45, 98);
      TextLayoutCache.paintBadge(
        canvas,
        text: '${neighbor.word} $simPct%',
        center: pos + const Offset(0, -14),
        textColor: neighbor.relation.color,
        borderColor: neighbor.relation.color.withOpacity(0.55),
        fontSize: 10.0,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      );
    }

    // Stella centrale (Token attivo)
    FastCanvasEffects.drawSoftGlowCircle(
      canvas,
      center,
      8.0,
      AuroraPalette.cyan,
      intensity: 0.95,
      rings: 3,
    );
    canvas.drawCircle(center, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4.5, Paint()..color = AuroraPalette.cyan);

    TextLayoutCache.paintBadge(
      canvas,
      text: currentToken,
      center: center + const Offset(0, 19),
      textColor: AuroraPalette.cyan,
      borderColor: AuroraPalette.cyan.withOpacity(0.8),
      fontSize: 11.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.currentToken != currentToken ||
      oldDelegate.neighbors != neighbors ||
      oldDelegate.isActive != isActive;
}

const Map<String, List<String>> _semanticGroups = {
  'tempo': ['tempo', 'ora', 'momento', 'istante', 'attimo', 'periodo', 'durata', 'era', 'epoca'],
  'mente': ['mente', 'cervello', 'pensiero', 'idea', 'coscienza', 'intelligenza', 'ragione', 'intuizione'],
  'dati': ['dato', 'informazione', 'valore', 'numero', 'cifra', 'risultato', 'output', 'input'],
  'rete': ['rete', 'nodo', 'connessione', 'sinapsi', 'neurone', 'link', 'sistema', 'struttura'],
  'linguaggio': ['parola', 'frase', 'testo', 'lingua', 'token', 'semantica', 'significato', 'concetto'],
  'azione': ['fare', 'creare', 'generare', 'produrre', 'costruire', 'sviluppare', 'elaborare'],
  'qualità': ['bello', 'ottimo', 'perfetto', 'eccellente', 'grande', 'potente', 'efficace', 'preciso'],
  'relazione': ['tra', 'con', 'verso', 'dentro', 'oltre', 'attraverso', 'insieme', 'contro'],
};

List<SemanticWord> generateSemanticNeighbors(String token) {
  if (token.isEmpty || token.length < 2) return [];
  final rnd = Random(token.hashCode);

  String? matchGroup;
  for (final entry in _semanticGroups.entries) {
    if (entry.value.any((w) => token.toLowerCase().startsWith(w.substring(0, min(3, w.length))))) {
      matchGroup = entry.key;
      break;
    }
  }

  List<String> candidateWords = matchGroup != null
      ? (List<String>.from(_semanticGroups[matchGroup]!)..remove(token.toLowerCase()))
      : ['concetto', 'valore', 'struttura', 'sistema', 'elemento', 'processo', 'stato'];

  candidateWords.shuffle(rnd);
  candidateWords = candidateWords.take(4).toList();

  final relations = [
    SemanticRelation.synonym,
    SemanticRelation.hypernym,
    SemanticRelation.hyponym,
    SemanticRelation.related,
  ]..shuffle(rnd);

  return List.generate(candidateWords.length, (i) {
    final double dist = 0.15 + rnd.nextDouble() * 0.55;
    final double angle = (i / candidateWords.length) * 2 * pi + rnd.nextDouble() * 0.45;
    return SemanticWord(
      word: candidateWords[i],
      distance: dist,
      relation: relations[i % relations.length],
      orbitAngle: angle,
    );
  });
}
