// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'core_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODULO 03 // PIPELINE RAG & DATABASE VETTORIALE ("ESAME A LIBRO APERTO")
// Perfetto per chi parte da 0:
// - Spiega perché l'AI senza RAG fa un "Esame a Libro Chiuso" e inventa (Allucinazione)
// - Mostra i Vettori come 4 "Termometri di Argomento" colorati (niente matematica astratta!)
// - Permette anche di cliccare sulle Schede per "aprire/chiudere la pagina del libro" all'AI
// ─────────────────────────────────────────────────────────────────────────────

enum RagStage {
  chunking,      // Passo 1: Dividere il manuale in singole Pagine/Schede (Chunk)
  embedding,     // Passo 2: Dare i "voti per argomento" a ogni scheda (Vettori)
  vectorSearch,  // Passo 3: Trovare sulla mappa le schede vicine alla domanda
  promptAugment, // Passo 4: Aprire le schede giuste davanti all'AI (Prompt)
  llmGeneration, // Passo 5: Confronto Libro Chiuso (Senza RAG) vs Libro Aperto (Con RAG)
}

class RagChunk {
  final int id;
  final String category;
  final String title;
  final String content;
  // Punteggi da 0.0 a 1.0 sui 4 temi: [0] Tech/GPU, [1] Sicurezza/Wi-Fi, [2] Esami/Tesi, [3] Tasse/Borse
  final List<double> semanticScores;
  final Offset mapPos;
  final List<String> keywords;
  double similarityScore;
  bool isSelectedTopK;

  RagChunk({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.semanticScores,
    required this.mapPos,
    required this.keywords,
    this.similarityScore = 0.0,
    this.isSelectedTopK = false,
  });
}

class RagLabWorkspace extends StatefulWidget {
  final GenerativeModel? geminiModel;
  final bool hasValidKey;
  final bool isBeginnerMode;

  const RagLabWorkspace({
    super.key,
    required this.geminiModel,
    required this.hasValidKey,
    this.isBeginnerMode = true,
  });

  @override
  State<RagLabWorkspace> createState() => _RagLabWorkspaceState();
}

class _RagLabWorkspaceState extends State<RagLabWorkspace>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  final TextEditingController _queryCtrl = TextEditingController(
    text: 'Quante ore posso prenotare i server GPU del laboratorio e quanta memoria VRAM hanno?',
  );

  int _selectedPresetQuestion = 0;
  final int _topK = 2;
  final double _similarityThreshold = 0.45;
  bool _isRunning = false;
  RagStage _currentStage = RagStage.vectorSearch;
  int _rightTabIndex = 0; // 0 = Le Pagine del Libro & Vettori, 1 = Il Bigliettino (Prompt), 2 = Libro Chiuso vs Libro Aperto

  Offset _queryMapPos = const Offset(0.45, -0.40);
  List<double> _querySemanticScores = [0.92, 0.25, 0.15, 0.05];

  late List<RagChunk> _chunks;
  String _ragResponse = '';
  String _noRagResponse = '';

  final List<(String, String)> _presetQuestions = [
    (
      '💻 1. Server GPU & Lab',
      'Quante ore posso prenotare i server GPU del laboratorio e quanta memoria VRAM hanno?'
    ),
    (
      '🎓 2. Tesi & Bonus Punti',
      'Entro quanti giorni va consegnata la tesi di laurea e quanti punti vale al massimo?'
    ),
    (
      '🔐 3. Password Wi-Fi',
      'Come funziona la rete Wi-Fi del campus e ogni quanto scade la password di accesso?'
    ),
    (
      '💶 4. Tasse & Borse ISEE',
      'Qual è il limite ISEE per non pagare le tasse universitarie e avere il rimborso alloggio?'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _initKnowledgeBase();
    _recomputeSimilarities(_queryCtrl.text);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _initKnowledgeBase() {
    _chunks = [
      RagChunk(
        id: 1,
        category: 'HARDWARE & AI',
        title: 'PAGINA #01 // Utilizzo Server GPU & Laboratorio AI',
        content:
            'Ogni studente può prenotare il cluster NVIDIA del Laboratorio AI per un massimo di 4 ore consecutive al giorno. '
            'Ciascun nodo mette a disposizione esattamente 32 GB di memoria VRAM dedicata.',
        semanticScores: [0.95, 0.30, 0.20, 0.05],
        mapPos: const Offset(0.52, -0.45),
        keywords: ['gpu', 'server', 'laboratorio', 'ore', 'prenotare', 'vram', 'memoria', 'nvidia', 'nodo', 'cluster'],
      ),
      RagChunk(
        id: 2,
        category: 'RETI & SICUREZZA',
        title: 'PAGINA #02 // Rete Wi-Fi Campus & Scadenza Password',
        content:
            'La rete protetta "Campus-Secure" utilizza il protocollo WPA3 sulla porta 8443. '
            'Per sicurezza, la password personale dello studente scade e va cambiata ogni 90 giorni.',
        semanticScores: [0.70, 0.96, 0.10, 0.05],
        mapPos: const Offset(-0.52, -0.42),
        keywords: ['wifi', 'wi-fi', 'rete', 'password', 'scade', 'sicurezza', 'porta', '8443', 'giorni', 'accesso'],
      ),
      RagChunk(
        id: 3,
        category: 'DIDATTICA & LAUREA',
        title: 'PAGINA #03 // Regolamento Tesi di Laurea & Punteggio',
        content:
            'Il file PDF della tesi di laurea deve essere caricato sul portale almeno 15 giorni prima della seduta. '
            'La commissione può assegnare fino a un massimo di 6 punti bonus per tesi sperimentali.',
        semanticScores: [0.15, 0.05, 0.96, 0.20],
        mapPos: const Offset(0.48, 0.46),
        keywords: ['tesi', 'laurea', 'giorni', 'punti', 'bonus', 'esame', 'consegnata', 'commissione', 'seduta'],
      ),
      RagChunk(
        id: 4,
        category: 'TASSE & BORSE',
        title: 'PAGINA #04 // Esonero Tasse & Borsa di Studio Alloggio',
        content:
            'Gli studenti con indicatore ISEE inferiore a 24.000 euro ottengono l\'esonero totale dalle tasse annuali '
            'e possono richiedere un contributo alloggio per fuori sede fino a 3.200 euro all\'anno.',
        semanticScores: [0.05, 0.10, 0.35, 0.96],
        mapPos: const Offset(-0.50, 0.48),
        keywords: ['isee', 'tasse', 'borsa', 'borse', 'studio', 'alloggio', 'euro', 'esonero', 'rimborso', 'limite'],
      ),
      RagChunk(
        id: 5,
        category: 'HARDWARE & RETE',
        title: 'PAGINA #05 // Accesso VPN Remoto ai Server del Laboratorio',
        content:
            'Per collegarsi da casa ai server GPU del laboratorio è necessario attivare la VPN di Ateneo. '
            'Le sessioni inattive per più di 30 minuti vengono chiuse automaticamente per liberare la VRAM.',
        semanticScores: [0.82, 0.68, 0.15, 0.05],
        mapPos: const Offset(0.12, -0.52),
        keywords: ['server', 'gpu', 'laboratorio', 'vpn', 'vram', 'memoria', 'casa', 'remoto', 'sessioni'],
      ),
    ];
  }

  void _recomputeSimilarities(String query) {
    final qLower = query.toLowerCase();
    final qWords = qLower
        .split(RegExp(r'[^a-zA-Z0-9àèéìòù]+'))
        .where((w) => w.length > 2)
        .toSet();

    double qx = 0.0;
    double qy = 0.0;
    List<double> accumScores = [0.15, 0.15, 0.15, 0.15];
    int totalHits = 0;

    for (final c in _chunks) {
      int hits = c.keywords.where((k) => qLower.contains(k) || qWords.contains(k)).length;
      if (hits > 0) {
        totalHits += hits;
        qx += c.mapPos.dx * hits;
        qy += c.mapPos.dy * hits;
        for (int i = 0; i < 4; i++) {
          accumScores[i] += c.semanticScores[i] * hits;
        }
      }
    }

    if (totalHits > 0) {
      _queryMapPos = Offset(
        (qx / totalHits).clamp(-0.72, 0.72),
        (qy / totalHits).clamp(-0.72, 0.72),
      );
      double maxS = accumScores.reduce(max);
      _querySemanticScores = accumScores
          .map((s) => double.parse((s / maxS * 0.94).clamp(0.08, 0.96).toStringAsFixed(2)))
          .toList();
    } else {
      _queryMapPos = const Offset(0.0, 0.0);
      _querySemanticScores = [0.25, 0.25, 0.25, 0.25];
    }

    for (final c in _chunks) {
      int hits = c.keywords.where((k) => qLower.contains(k) || qWords.contains(k)).length;
      double dist = (c.mapPos - _queryMapPos).distance;
      double geomSim = (1.0 - (dist / 1.55)).clamp(0.10, 0.96);
      double keywordBoost = min(0.42, hits * 0.15);
      c.similarityScore = (geomSim * 0.62 + keywordBoost).clamp(0.12, 0.97);
      c.isSelectedTopK = false;
    }

    final sorted = List<RagChunk>.from(_chunks)
      ..sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    int count = 0;
    for (final c in sorted) {
      if (count < _topK && c.similarityScore >= _similarityThreshold) {
        c.isSelectedTopK = true;
        count++;
      }
    }

    _buildGroundedResponses(query);
  }

  // Permette all'utente di cliccare manualmente una pagina del libro per aprirla/chiuderla all'AI!
  void _toggleChunkManualSelection(RagChunk chunk) {
    setState(() {
      chunk.isSelectedTopK = !chunk.isSelectedTopK;
      _buildGroundedResponses(_queryCtrl.text);
    });
  }

  void _buildGroundedResponses(String query) {
    final selected = _chunks.where((c) => c.isSelectedTopK).toList()
      ..sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    _noRagResponse =
        '📕 ESAME A LIBRO CHIUSO (L\'AI non ha letto il tuo manuale e tira a indovinare):\n'
        '"Non ho mai letto il regolamento interno del vostro Campus! '
        'Provo a indovinare: forse i laboratori si prenotano per 2 ore e hanno 16 GB di RAM, '
        'oppure la tesi va consegnata 30 giorni prima..."\n'
        '⚠️ ATTENZIONE: Questa si chiama ALLUCINAZIONE (numeri plausibili ma completamente inventati!).';

    if (selected.isEmpty) {
      _ragResponse =
          '⚠️ HAI CHIUSO TUTTE LE PAGINE DEL LIBRO (0 Schede selezionate)!\n'
          'Con la RAG attiva, se nessuna pagina supera la soglia (o se le deselezioni tutte), '
          'l\'AI ha l\'ordine tassativo di NON inventare e ti risponde: '
          '"Mi dispiace, non ho trovato nessuna pagina ufficiale su questo argomento."';
    } else {
      final citations = selected.map((c) => '[Pagina #0${c.id}]').join(' ');
      final synth = selected
          .map((c) => '• Letto da Pagina #0${c.id} (${(c.similarityScore * 100).toStringAsFixed(0)}% affinità): "${c.content}"')
          .join('\n');
      _ragResponse =
          '📖 ESAME A LIBRO APERTO CON RAG $citations:\n'
          'Il Database Vettoriale ha aperto il manuale esattamente alle pagine giuste per l\'AI. Ecco la risposta certa al 100%:\n$synth';
    }
  }

  void _selectStage(RagStage stage) {
    setState(() {
      _currentStage = stage;
      if (stage == RagStage.chunking || stage == RagStage.embedding || stage == RagStage.vectorSearch) {
        _rightTabIndex = 0;
      } else if (stage == RagStage.promptAugment) {
        _rightTabIndex = 1;
      } else if (stage == RagStage.llmGeneration) {
        _rightTabIndex = 2;
      }
    });
  }

  Future<void> _runFullRagPipeline() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _recomputeSimilarities(_queryCtrl.text);
    });

    const delay = Duration(milliseconds: 950);
    for (final st in RagStage.values) {
      if (!mounted) return;
      _selectStage(st);
      await Future.delayed(delay);
    }

    if (mounted) {
      setState(() => _isRunning = false);
    }
  }

  void _nextStage() {
    const stages = RagStage.values;
    final nextIdx = (stages.indexOf(_currentStage) + 1) % stages.length;
    _recomputeSimilarities(_queryCtrl.text);
    _selectStage(stages[nextIdx]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool wide = constraints.maxWidth > 980;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 11, child: _buildLeftVisualPanel(true)),
            Container(width: 1, color: Colors.purpleAccent.withOpacity(0.25)),
            Expanded(flex: 10, child: _buildRightInspectorPanel(true)),
          ],
        );
      } else {
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildLeftVisualPanel(false),
              Container(height: 1, color: Colors.purpleAccent.withOpacity(0.25)),
              _buildRightInspectorPanel(false),
            ],
          ),
        );
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PANNELLO SINISTRO: METAFORA LIBRO APERTO + MAPPA VETTORIALE + SPIEGAZIONE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLeftVisualPanel(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 20 : 14),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF170E2C), Color(0xFF06060F)],
          radius: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThreeSimpleCards(),
          const SizedBox(height: 10),
          _buildRagStageBar(),
          const SizedBox(height: 10),
          if (wide)
            Expanded(child: _buildVectorSpaceCanvas())
          else
            SizedBox(height: 310, child: _buildVectorSpaceCanvas()),
          const SizedBox(height: 10),
          _buildClearStepExplanationBox(),
        ],
      ),
    );
  }

  Widget _buildThreeSimpleCards() {
    return Row(
      children: [
        _simpleConceptCard(
          badge: '📕 1. SENZA RAG = LIBRO CHIUSO',
          title: 'Perché l\'AI inventa?',
          body: 'Se chiedi all\'AI una regola del tuo PDF privato senza farglielo leggere, fa un esame a libro chiuso e tira a indovinare!',
          color: const Color(0xFFFF5252),
        ),
        const SizedBox(width: 8),
        _simpleConceptCard(
          badge: '🧭 2. IL DATABASE VETTORIALE',
          title: 'L\'Indice Intelligente',
          body: 'Dà a ogni pagina del PDF 4 "voti per argomento" (Vettore) e la posiziona su una mappa per trovare subito quella giusta.',
          color: const Color(0xFFB388FF),
        ),
        const SizedBox(width: 8),
        _simpleConceptCard(
          badge: '📖 3. CON RAG = LIBRO APERTO',
          title: 'Zero Allucinazioni!',
          body: 'Il programma apre il libro alle 2 pagine più vicine alla domanda e le mette sotto gli occhi dell\'AI prima che risponda.',
          color: const Color(0xFF69F0AE),
        ),
      ],
    );
  }

  Widget _simpleConceptCard({
    required String badge,
    required String title,
    required String body,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge,
              style: GoogleFonts.spaceMono(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              body,
              style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRagStageBar() {
    final stages = [
      (RagStage.chunking, 'PASSO 1: Taglia in Pagine', Colors.cyanAccent),
      (RagStage.embedding, 'PASSO 2: Dai Voti (Vettori)', const Color(0xFFB388FF)),
      (RagStage.vectorSearch, 'PASSO 3: Trova le Più Vicine', Colors.amberAccent),
      (RagStage.promptAugment, 'PASSO 4: Apri il Libro all\'AI', const Color(0xFFFF6B35)),
      (RagStage.llmGeneration, 'PASSO 5: Risposta Esatta', const Color(0xFF69F0AE)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: stages.map((st) {
              final bool active = _currentStage == st.$1;
              return InkWell(
                onTap: () => _selectStage(st.$1),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? st.$3.withOpacity(0.25) : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: active ? st.$3 : Colors.white24, width: active ? 1.4 : 1.0),
                  ),
                  child: Text(
                    st.$2,
                    style: GoogleFonts.spaceMono(
                      color: active ? st.$3 : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          InkWell(
            onTap: _nextStage,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: Text(
                'Avanza Passo ▶',
                style: GoogleFonts.spaceMono(
                  color: Colors.cyanAccent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVectorSpaceCanvas() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF060510),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.35)),
      ),
      child: Stack(
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _RagVectorSpacePainter(
                animCtrl: _animCtrl,
                chunks: _chunks,
                queryPos: _queryMapPos,
                stage: _currentStage,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'MAPPA DEI SIGNIFICATI (VECTOR DB) // Le pagine vicine al pallino giallo parlano dello stesso tema!',
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFFB388FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Wrap(
                spacing: 14,
                children: [
                  _legendDot(Colors.amberAccent, 'La tua Domanda'),
                  _legendDot(const Color(0xFF69F0AE), 'Pagina Aperta per l\'AI ✓'),
                  _legendDot(Colors.blueGrey.shade200, 'Pagina Chiusa (Altro Tema ✗)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color col, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 11)),
      ],
    );
  }

  Widget _buildClearStepExplanationBox() {
    String stepTitle;
    String plainExplanation;
    String concreteExample;
    Color col;

    final topSelected = _chunks.where((c) => c.isSelectedTopK).toList();
    final topNames = topSelected.isEmpty
        ? 'Nessuna pagina aperta'
        : topSelected.map((c) => 'Pagina #0${c.id} (${(c.similarityScore * 100).toInt()}%)').join(' e ');

    switch (_currentStage) {
      case RagStage.chunking:
        stepTitle = 'PASSO 1 // TAGLIARE IL LIBRO IN SINGOLE PAGINE ("CHUNKING")';
        plainExplanation =
            'Se hai un manuale di 300 pagine, non puoi darlo tutto insieme all\'AI per una singola domanda. '
            'Il programma divide quindi il manuale in tante piccole schede numerate indipendenti (chiamate "Chunk").';
        concreteExample =
            'Qui sopra: Il Regolamento Universitario è stato diviso in 5 Pagine '
            '(Pagina #01 Server GPU, Pagina #02 Wi-Fi, Pagina #03 Tesi, Pagina #04 Tasse, Pagina #05 VPN).';
        col = Colors.cyanAccent;
        break;

      case RagStage.embedding:
        stepTitle = 'PASSO 2 // DARE I "VOTI PER ARGOMENTO" A OGNI PAGINA ("VETTORE")';
        plainExplanation =
            'Cos\'è un Vettore (Embedding)? È semplicissimo: il computer legge una frase e le dà un voto da 0% a 100% su vari argomenti '
            '(Quanto parla di Computer? Quanto di Sicurezza? Quanto di Esami? Quanto di Soldi?). '
            'Questi voti diventano le coordinate X e Y per posizionare la pagina sulla mappa qui sopra!';
        concreteExample =
            'La tua domanda ha ricevuto i voti: 💻 Tech ${(100 * _querySemanticScores[0]).toInt()}% | '
            '🔐 Sicurezza ${(100 * _querySemanticScores[1]).toInt()}% | 🎓 Esami ${(100 * _querySemanticScores[2]).toInt()}% | '
            '💶 Tasse ${(100 * _querySemanticScores[3]).toInt()}%.';
        col = const Color(0xFFB388FF);
        break;

      case RagStage.vectorSearch:
        stepTitle = 'PASSO 3 // PRENDERE COL RIGHELLO LE PAGINE PIÙ VICINE ("SIMILARITY SEARCH")';
        plainExplanation =
            'Adesso il computer guarda la mappa e misura la distanza tra il pallino giallo (la tua domanda) e tutte le pagine del manuale. '
            'Le pagine più vicine hanno gli stessi argomenti della tua domanda e diventano VERDI!';
        concreteExample =
            'Pagine scelte automaticamente perché più vicine: $topNames. '
            '(Puoi anche cliccare tu sulle schede a destra per aprirle o chiuderle manualmente!)';
        col = Colors.amberAccent;
        break;

      case RagStage.promptAugment:
        stepTitle = 'PASSO 4 // APRIRE LE PAGINE VERDI DAVANTI ALL\'AI ("PROMPT INJECTION")';
        plainExplanation =
            'Ecco il trucco della RAG: prima di mandare la domanda all\'AI, il programma incolla nel messaggio il testo esatto '
            'delle pagine verdi appena trovate, dicendo all\'AI: "Usa questo libro aperto per rispondere!".';
        concreteExample =
            'Guarda la scheda "2. IL BIGLIETTINO PER L\'AI" qui a destra per leggere il testo completo che viene spedito!';
        col = const Color(0xFFFF6B35);
        break;

      case RagStage.llmGeneration:
        stepTitle = 'PASSO 5 // ESAME A LIBRO APERTO: RISPOSTA CERTA AL 100%!';
        plainExplanation =
            'Leggendo le pagine ufficiali appena aperte, l\'AI non deve più tirare a indovinare: '
            'ti dà i numeri esatti del regolamento e ti indica anche da quale pagina li ha presi!';
        concreteExample =
            'Guarda a destra il confronto tra "Esame a Libro Chiuso (Senza RAG)" ed "Esame a Libro Aperto (Con RAG)"!';
        col = const Color(0xFF69F0AE);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.68),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepTitle,
            style: GoogleFonts.spaceMono(color: col, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            plainExplanation,
            style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: col.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: col.withOpacity(0.35)),
            ),
            child: Text(
              concreteExample,
              style: GoogleFonts.spaceMono(
                color: Colors.white.withOpacity(0.95),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PANNELLO DESTRO: DOMANDA + TERMOMETRI VETTORIALI + LIBRO APERTO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRightInspectorPanel(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 20 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQueryControllerCard(),
          const SizedBox(height: 10),
          _buildRightTabs(),
          const SizedBox(height: 10),
          if (wide)
            Expanded(child: _buildRightTabBody())
          else
            SizedBox(height: 540, child: _buildRightTabBody()),
        ],
      ),
    );
  }

  Widget _buildQueryControllerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '① CLICCA UNA DOMANDA DI PROVA (OPPURE SCRIVINE UNA TUA):',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFFB388FF),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_presetQuestions.length, (i) {
              final bool sel = _selectedPresetQuestion == i;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPresetQuestion = i;
                    _queryCtrl.text = _presetQuestions[i].$2;
                    _recomputeSimilarities(_queryCtrl.text);
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFB388FF).withOpacity(0.25)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: sel ? const Color(0xFFB388FF) : Colors.white24,
                    ),
                  ),
                  child: Text(
                    _presetQuestions[i].$1,
                    style: GoogleFonts.spaceMono(
                      color: sel ? const Color(0xFFB388FF) : Colors.white,
                      fontSize: 10.5,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  onChanged: (v) => setState(() => _recomputeSimilarities(v)),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Scrivi una domanda (es. tesi, wifi, password, gpu, tasse)...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runFullRagPipeline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB388FF).withOpacity(0.22),
                  foregroundColor: const Color(0xFFB388FF),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  side: const BorderSide(color: Color(0xFFB388FF), width: 1.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(_isRunning ? Icons.hourglass_top : Icons.play_circle_fill, size: 18),
                label: Text(
                  _isRunning ? 'IN CORSO...' : 'AVVIA TOUR 5 PASSI',
                  style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightTabs() {
    final tabs = [
      (Icons.menu_book, '1. PAGINE & VOTI VETTORE'),
      (Icons.post_add, '2. IL BIGLIETTINO PER L\'AI'),
      (Icons.compare_arrows, '3. LIBRO CHIUSO vs APERTO'),
    ];
    return Row(
      children: List.generate(tabs.length, (i) {
        final bool active = _rightTabIndex == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8.0 : 0),
            child: InkWell(
              onTap: () => setState(() => _rightTabIndex = i),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFB388FF).withOpacity(0.22)
                      : Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? const Color(0xFFB388FF) : Colors.white24,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$1, size: 15, color: active ? const Color(0xFFB388FF) : Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[i].$2,
                        style: GoogleFonts.spaceMono(
                          color: active ? const Color(0xFFB388FF) : Colors.white,
                          fontSize: 10.5,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRightTabBody() {
    switch (_rightTabIndex) {
      case 0:
        return _buildVectorsAndChunksTab();
      case 1:
        return _buildAugmentedPromptInspector();
      default:
        return _buildComparisonView();
    }
  }

  // ── TAB 1: Termometri Vettoriali + Pagine Cliccabili ──
  Widget _buildVectorsAndChunksTab() {
    final sorted = List<RagChunk>.from(_chunks)
      ..sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Termometro visivo del Vettore della Domanda
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amberAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amberAccent.withOpacity(0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎯 I 4 "VOTI PER ARGOMENTO" DELLA TUA DOMANDA (IL SUO VETTORE):',
                style: GoogleFonts.spaceMono(
                  color: Colors.amberAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _buildVisualVectorBars(_querySemanticScores),
              const SizedBox(height: 6),
              Text(
                '💡 SUGGERIMENTO INTERATTIVO: Il computer ha aperto per l\'AI le pagine con le barre più simili. '
                'Prova a CLICCARE su qualsiasi pagina qui sotto per aprirla o chiuderla manualmente!',
                style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = sorted[i];
              final Color col = c.isSelectedTopK ? const Color(0xFF69F0AE) : Colors.white54;
              return InkWell(
                onTap: () => _toggleChunkManualSelection(c),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: c.isSelectedTopK
                        ? const Color(0xFF69F0AE).withOpacity(0.09)
                        : Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: c.isSelectedTopK ? const Color(0xFF69F0AE).withOpacity(0.75) : Colors.white12,
                      width: c.isSelectedTopK ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            c.isSelectedTopK ? Icons.check_box : Icons.check_box_outline_blank,
                            color: col,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: col.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.isSelectedTopK
                                  ? '📖 PAGINA APERTA PER L\'AI'
                                  : '📕 PAGINA CHIUSA (CLICCA PER APRIRE)',
                              style: GoogleFonts.spaceMono(
                                color: col,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Somiglianza: ${(c.similarityScore * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.spaceMono(
                              color: col,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.title,
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        c.content,
                        style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 12.5, height: 1.38),
                      ),
                      const SizedBox(height: 8),
                      _buildVisualVectorBars(c.semanticScores),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Mostra i 4 numeri del vettore come 4 mini-termometri colorati chiarissimi!
  Widget _buildVisualVectorBars(List<double> scores) {
    final items = [
      ('💻 Tech/GPU', scores[0], Colors.cyanAccent),
      ('🔐 Sicurezza', scores[1], Colors.orangeAccent),
      ('🎓 Esami/Tesi', scores[2], const Color(0xFFB388FF)),
      ('💶 Tasse/Borse', scores[3], const Color(0xFF69F0AE)),
    ];
    return Row(
      children: items.map((item) {
        final pct = (item.$2 * 100).toInt();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: item.$3.withOpacity(item.$2 > 0.5 ? 0.6 : 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.$1,
                          style: TextStyle(
                            color: item.$2 > 0.5 ? Colors.white : Colors.white60,
                            fontSize: 9.5,
                            fontWeight: item.$2 > 0.5 ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: GoogleFonts.spaceMono(
                          color: item.$3,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.$2,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(item.$3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── TAB 2: Il "Bigliettino" completo mandato all'AI ──
  Widget _buildAugmentedPromptInspector() {
    final selected = _chunks.where((c) => c.isSelectedTopK).toList();
    final contextBlocks = selected.isEmpty
        ? '[NESSUNA PAGINA APERTA — L\'AI NON AVRÀ INFORMAZIONI SU CUI BASARSI]'
        : selected.map((c) => '--- [${c.title}] ---\n${c.content}').join('\n\n');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.45)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 IL "BIGLIETTINO" COMPLETO CHE IL PROGRAMMA INVIA ALL\'AI:',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFFFF6B35),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ecco perché l\'AI con la RAG non sbaglia: prima della tua domanda, il programma incolla '
              'in automatico le ${selected.length} pagine verdi che hai aperto nella Tab 1!',
              style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),

            _promptSectionCard(
              label: 'PARTE 1 // LA REGOLA D\'ORO ("Non inventare nulla!")',
              color: Colors.cyanAccent,
              text:
                  'Sei l\'assistente del Campus. Rispondi alla domanda dello studente leggendo SOLO le Pagine Ufficiali copiate qui sotto. Cita sempre la pagina usata.',
            ),
            const SizedBox(height: 12),

            _promptSectionCard(
              label: 'PARTE 2 // LE ${selected.length} PAGINE DEL LIBRO APERTE DAL DATABASE VETTORIALE',
              color: const Color(0xFF69F0AE),
              text: contextBlocks,
            ),
            const SizedBox(height: 12),

            _promptSectionCard(
              label: 'PARTE 3 // LA TUA DOMANDA',
              color: Colors.amberAccent,
              text: _queryCtrl.text,
            ),
          ],
        ),
      ),
    );
  }

  Widget _promptSectionCard({
    required String label,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: GoogleFonts.spaceMono(color: Colors.white.withOpacity(0.95), fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: Confronto Diretto Libro Chiuso vs Libro Aperto ──
  Widget _buildComparisonView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.5)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❌ SENZA RAG: ESAME A LIBRO CHIUSO (L\'AI non ha letto le pagine)',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFFF5252),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _noRagResponse,
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13.5, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF69F0AE).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.55)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ CON RAG: ESAME A LIBRO APERTO (L\'AI legge le pagine verdi)',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF69F0AE),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _ragResponse,
                    style: TextStyle(color: Colors.white.withOpacity(0.96), fontSize: 13.5, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: MAPPA SEMANTICA 2D CON AREE TEMATICHE CHIARE
// ─────────────────────────────────────────────────────────────────────────────
class _RagVectorSpacePainter extends CustomPainter {
  final Animation<double> animCtrl;
  final List<RagChunk> chunks;
  final Offset queryPos;
  final RagStage stage;

  _RagVectorSpacePainter({
    required this.animCtrl,
    required this.chunks,
    required this.queryPos,
    required this.stage,
  }) : super(repaint: animCtrl);

  double get animPhase => animCtrl.value;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) * 0.39;

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), gridPaint);
    }
    canvas.drawLine(Offset(24, center.dy), Offset(size.width - 24, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 34), Offset(center.dx, size.height - 34), gridPaint);

    _drawLabel(
      canvas,
      '🔐 AREA RETI & SICUREZZA',
      Offset(size.width * 0.22, 46),
      Colors.cyanAccent.withOpacity(0.55),
      10.5,
      bold: true,
    );
    _drawLabel(
      canvas,
      '💻 AREA HARDWARE & AI',
      Offset(size.width * 0.78, 46),
      Colors.cyanAccent.withOpacity(0.55),
      10.5,
      bold: true,
    );
    _drawLabel(
      canvas,
      '💶 AREA TASSE & BORSE',
      Offset(size.width * 0.22, size.height - 42),
      Colors.purpleAccent.withOpacity(0.55),
      10.5,
      bold: true,
    );
    _drawLabel(
      canvas,
      '🎓 AREA ESAMI & TESI',
      Offset(size.width * 0.78, size.height - 42),
      Colors.purpleAccent.withOpacity(0.55),
      10.5,
      bold: true,
    );

    final Offset qScreen = Offset(
      center.dx + queryPos.dx * radius,
      center.dy + queryPos.dy * radius,
    );

    if (stage == RagStage.vectorSearch || stage == RagStage.promptAugment || stage == RagStage.llmGeneration) {
      final double waveRadius = (animPhase * radius * 1.25);
      final Paint radarPaint = Paint()
        ..color = Colors.amberAccent.withOpacity((1.0 - animPhase) * 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawCircle(qScreen, waveRadius, radarPaint);
    }

    for (final c in chunks) {
      final Offset cScreen = Offset(
        center.dx + c.mapPos.dx * radius,
        center.dy + c.mapPos.dy * radius,
      );

      final bool highlight = c.isSelectedTopK;
      final Color lineCol = highlight
          ? const Color(0xFF69F0AE).withOpacity(0.9)
          : Colors.white.withOpacity(0.15);

      final Paint linePaint = Paint()
        ..color = lineCol
        ..strokeWidth = highlight ? 2.6 : 1.0;
      canvas.drawLine(qScreen, cScreen, linePaint);

      if (highlight) {
        final Offset mid = Offset.lerp(qScreen, cScreen, 0.5)!;
        _drawBadgeLabel(
          canvas,
          'Affinità ${(c.similarityScore * 100).toInt()}% ✓',
          mid,
          const Color(0xFF69F0AE),
        );
      }

      final Color nodeCol = highlight ? const Color(0xFF69F0AE) : Colors.blueGrey.shade200;
      if (highlight) {
        FastCanvasEffects.drawSoftGlowCircle(
          canvas,
          cScreen,
          9.0,
          nodeCol,
          intensity: 0.9,
          rings: 3,
        );
      }
      canvas.drawCircle(cScreen, highlight ? 9 : 6.5, Paint()..color = nodeCol);

      _drawLabel(
        canvas,
        'Pagina #0${c.id}',
        cScreen.translate(0, -20),
        nodeCol,
        11.5,
        bold: true,
      );
      _drawLabel(
        canvas,
        c.category,
        cScreen.translate(0, 18),
        highlight ? Colors.white : Colors.white70,
        10,
        bold: highlight,
      );
    }

    FastCanvasEffects.drawSoftGlowCircle(
      canvas,
      qScreen,
      10.0,
      Colors.amberAccent,
      intensity: 0.95,
      rings: 3,
    );
    canvas.drawCircle(qScreen, 9.5, Paint()..color = Colors.amberAccent);
    _drawBadgeLabel(
      canvas,
      'LA TUA DOMANDA',
      qScreen.translate(0, -24),
      Colors.amberAccent,
    );
  }

  void _drawBadgeLabel(Canvas canvas, String text, Offset center, Color color) {
    TextLayoutCache.paintBadge(
      canvas,
      text: text,
      center: center,
      textColor: color,
      borderColor: color.withOpacity(0.75),
      bgColor: const Color(0xFF070812).withOpacity(0.92),
      fontSize: 10.5,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset pos,
    Color col,
    double fontSize, {
    bool bold = false,
  }) {
    TextLayoutCache.paintCentered(
      canvas,
      text: text,
      center: pos,
      fontSize: fontSize,
      color: col,
      weight: bold ? FontWeight.bold : FontWeight.normal,
    );
  }

  @override
  bool shouldRepaint(covariant _RagVectorSpacePainter oldDelegate) =>
      oldDelegate.queryPos != queryPos || oldDelegate.stage != stage;
}
