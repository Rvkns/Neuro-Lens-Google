import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEMANTIC COMPASS v3.0
// Visualizza il token corrente al centro e le parole semanticamente correlate
// orbitarle attorno a distanze proporzionali alla "distanza coseno simulata".
// Replica visiva dello spazio vettoriale degli Embedding (Word2Vec / t-SNE).
// ─────────────────────────────────────────────────────────────────────────────

/// Parola semantica con distanza coseno simulata (0 = identica, 1 = opposta).
class SemanticWord {
  final String word;
  final double distance; // 0.0 (vicinissima) → 1.0 (lontanissima)
  final SemanticRelation relation;
  final double orbitAngle; // Angolo fisso sull'orbita

  SemanticWord({
    required this.word,
    required this.distance,
    required this.relation,
    required this.orbitAngle,
  });
}

enum SemanticRelation {
  synonym,   // Sinonimo — verde
  hypernym,  // Ipernimo (categoria superiore) — ciano
  hyponym,   // Iponimo (categoria inferiore) — azzurro
  antonym,   // Antonimo — rosso
  related,   // Correlato — viola
}

extension SemanticRelationStyle on SemanticRelation {
  Color get color {
    switch (this) {
      case SemanticRelation.synonym:   return const Color(0xFF69F0AE);
      case SemanticRelation.hypernym:  return Colors.cyanAccent;
      case SemanticRelation.hyponym:   return const Color(0xFF40C4FF);
      case SemanticRelation.antonym:   return const Color(0xFFFF5252);
      case SemanticRelation.related:   return const Color(0xFFB388FF);
    }
  }

  String get label {
    switch (this) {
      case SemanticRelation.synonym:   return 'Sinonimi';
      case SemanticRelation.hypernym:  return 'Categorie / Iperonimi';
      case SemanticRelation.hyponym:   return 'Sottocategorie / Iponimi';
      case SemanticRelation.antonym:   return 'Contrari / Opposti';
      case SemanticRelation.related:   return 'Concetti Correlati';
    }
  }
}

class SemanticCompass extends StatefulWidget {
  final String currentToken;
  final List<SemanticWord> neighbors;
  final bool isActive;

  const SemanticCompass({
    super.key,
    required this.currentToken,
    required this.neighbors,
    this.isActive = false,
  });

  @override
  State<SemanticCompass> createState() => _SemanticCompassState();
}

class _SemanticCompassState extends State<SemanticCompass>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotController;

  @override
  void initState() {
    super.initState();
    // Rotazione lenta del piano vettoriale (effetto cosmico)
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Text('SEMANTIC SPACE',
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFFB388FF),
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('Embedding Vettoriale t-SNE',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          // Canvas della bussola
          Expanded(
            child: AnimatedBuilder(
              animation: _rotController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _CompassPainter(
                    currentToken: widget.currentToken,
                    neighbors: widget.neighbors,
                    isActive: widget.isActive,
                    slowRotation: _rotController.value * 2 * pi * 0.15,
                  ),
                );
              },
            ),
          ),
          // Legenda relazioni semantiche (Ora chiara ed esplicita)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0, // Spazio orizzontale tra le voci
              runSpacing: 4.0, // Spazio verticale se vanno a capo
              children: SemanticRelation.values.map((r) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(r.label, style: TextStyle(color: r.color, fontSize: 9)),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final String currentToken;
  final List<SemanticWord> neighbors;
  final bool isActive;
  final double slowRotation;

  _CompassPainter({
    required this.currentToken,
    required this.neighbors,
    required this.isActive,
    required this.slowRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = min(size.width, size.height) / 2 - 30;

    // ── Cerchi concentrici delle orbite ──
    final Paint orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * i / 3, orbitPaint);
    }

    // ── Assi del piano vettoriale ──
    final Paint axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    // ── Label assi ──
    _drawLabel(canvas, 'dim₁', Offset(size.width - 24, center.dy - 14), Colors.white.withOpacity(0.2), 8);
    _drawLabel(canvas, 'dim₂', Offset(center.dx + 4, 12), Colors.white.withOpacity(0.2), 8);

    if (currentToken.isEmpty) {
      _drawLabel(canvas, 'In attesa...', center, Colors.white.withOpacity(0.2), 11);
      return;
    }

    // ── Linee di connessione dal centro ──
    for (final neighbor in neighbors) {
      double angle = neighbor.orbitAngle + slowRotation;
      double r = maxRadius * (0.25 + neighbor.distance * 0.7);
      Offset pos = Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);

      final Paint linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = neighbor.relation.color.withOpacity(0.35)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, pos, linePaint);

      // Punto satellite
      final Paint dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = neighbor.relation.color.withOpacity(0.85);
      canvas.drawCircle(pos, 3.5, dotPaint);

      // Alone glow sul satellite
      final Paint glowDot = Paint()
        ..style = PaintingStyle.fill
        ..color = neighbor.relation.color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, 7, glowDot);

      // Etichetta parola
      _drawLabel(canvas, neighbor.word, pos + const Offset(7, -8), neighbor.relation.color, 9);
    }

    // ── Token centrale (stella principale) ──
    final Paint centralGlow = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.cyanAccent.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, 22, centralGlow);

    final Paint centralPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.cyanAccent;
    canvas.drawCircle(center, 5, centralPaint);

    // Etichetta token centrale
    _drawLabel(canvas, currentToken, center + const Offset(0, 18), Colors.cyanAccent, 12);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'monospace',
          fontWeight: fontSize > 10 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.currentToken != currentToken ||
      oldDelegate.slowRotation != slowRotation ||
      oldDelegate.isActive != isActive;
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERATORE DI PAROLE SEMANTICHE SIMULATE
// Dato un token in input, genera un insieme plausibile di vicini vettoriali
// usando classi lessicali predefinite e randomizzazione coerente.
// ─────────────────────────────────────────────────────────────────────────────

/// Mappa di categorie semantiche italiane per gruppi di parole correlate.
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

/// Genera la lista di [SemanticWord] per il token dato.
List<SemanticWord> generateSemanticNeighbors(String token) {
  if (token.isEmpty || token.length < 2) return [];
  final rnd = Random(token.hashCode); // Seed fisso per token → stessi vicini ogni volta

  // Trova il gruppo semantico più vicino (match parziale)
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

  // Pesca 4 vicini casuali con ruoli semantici diversi
  candidateWords.shuffle(rnd);
  candidateWords = candidateWords.take(4).toList();

  final relations = [
    SemanticRelation.synonym,
    SemanticRelation.hypernym,
    SemanticRelation.hyponym,
    SemanticRelation.related,
  ]..shuffle(rnd);

  return List.generate(candidateWords.length, (i) {
    double dist = 0.15 + rnd.nextDouble() * 0.6;
    double angle = (i / candidateWords.length) * 2 * pi + rnd.nextDouble() * 0.5;
    return SemanticWord(
      word: candidateWords[i],
      distance: dist,
      relation: relations[i % relations.length],
      orbitAngle: angle,
    );
  });
}
