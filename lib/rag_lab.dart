// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODULO 03 // PIPELINE RAG (RETRIEVAL-AUGMENTED GENERATION) & VECTOR DB
// Spiega visivamente come dare "memoria esterna verificabile" a un LLM:
// 1. Chunking -> 2. Embedding Vettoriale -> 3. Cosine Similarity Search ->
// 4. Prompt Injection (Contesto) -> 5. Generazione Grounded (senza allucinazioni).
// ─────────────────────────────────────────────────────────────────────────────

enum RagStage {
  idle,
  chunking,         // 1. Divisione documento in frammenti (Chunk)
  embedding,        // 2. Conversione testo -> Vettori numerici [x1, x2, ..., xn]
  vectorSearch,     // 3. Calcolo Cosine Similarity nel Vector Database (Top-K)
  promptAugment,    // 4. Iniezione dei Chunk recuperati dentro il System Prompt
  llmGeneration,    // 5. Risposta finale ancorata alle fonti (Con vs Senza RAG)
}

class RagChunk {
  final int id;
  final String title;
  final String content;
  final List<double> vectorPreview; // 4 dimensioni dimostrative
  final Offset spacePos;            // Posizione normalizzata (-1..1) nel Vector Space 2D
  final List<String> keywords;
  double similarityScore;
  bool isSelectedTopK;

  RagChunk({
    required this.id,
    required this.title,
    required this.content,
    required this.vectorPreview,
    required this.spacePos,
    required this.keywords,
    this.similarityScore = 0.0,
    this.isSelectedTopK = false,
  });
}

class RagLabWorkspace extends StatefulWidget {
  final GenerativeModel? geminiModel;
  final bool hasValidKey;

  const RagLabWorkspace({
    super.key,
    required this.geminiModel,
    required this.hasValidKey,
  });

  @override
  State<RagLabWorkspace> createState() => _RagLabWorkspaceState();
}

class _RagLabWorkspaceState extends State<RagLabWorkspace>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  final TextEditingController _queryCtrl = TextEditingController(
    text: 'Qual è la soglia massima di latenza consentita dal protocollo Hyperion e su quale porta opera?',
  );

  int _selectedPresetQuestion = 0;
  int _topK = 2;
  double _similarityThreshold = 0.45;
  bool _isRunning = false;
  RagStage _currentStage = RagStage.idle;
  int _rightTabIndex = 0; // 0 = Chunks & Similarity, 1 = Prompt Aumentato, 2 = Confronto Con/Senza RAG

  Offset _queryVectorPos = const Offset(0.32, -0.28);
  List<double> _queryVectorPreview = [0.81, -0.34, 0.67, 0.19];

  late List<RagChunk> _chunks;
  String _ragResponse = '';
  String _noRagResponse = '';

  final List<(String, String)> _presetQuestions = [
    (
      'Protocollo Rete (Hyperion)',
      'Qual è la soglia massima di latenza consentita dal protocollo Hyperion e su quale porta opera?'
    ),
    (
      'Sicurezza & API Key',
      'Ogni quanto tempo ruotano le chiavi crittografiche nel sistema Aegis e quale algoritmo usano?'
    ),
    (
      'Architettura Memoria GPU',
      'Quanti nodi tensoriali usa il cluster Quantum-Core e quanta VRAM dedica alla cache KV?'
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
        title: 'CHUNK #01 // Protocollo di Rete Hyperion v4',
        content:
            'Il protocollo accademico Hyperion v4 opera esclusivamente sulla porta UDP 8443. '
            'La soglia massima di latenza consentita (SLA) è fissata a 12.5 ms; superata tale soglia '
            'viene attivato il routing secondario automatico.',
        vectorPreview: [0.84, -0.31, 0.72, 0.15],
        spacePos: const Offset(0.42, -0.35),
        keywords: ['protocollo', 'hyperion', 'latenza', 'soglia', 'porta', '8443', 'udp', 'ms', 'rete'],
      ),
      RagChunk(
        id: 2,
        title: 'CHUNK #02 // Criteri Sicurezza & Rotazione Aegis',
        content:
            'Nel modulo di sicurezza Aegis, tutte le API Key e i token di sessione vengono ruotati '
            'automaticamente ogni 6 ore utilizzando la firma asimmetrica Ed25519 e cifratura AES-256-GCM.',
        vectorPreview: [-0.62, 0.78, 0.11, -0.44],
        spacePos: const Offset(-0.52, 0.45),
        keywords: ['sicurezza', 'chiavi', 'api', 'key', 'ruotano', 'aegis', 'algoritmo', 'ed25519', 'ore'],
      ),
      RagChunk(
        id: 3,
        title: 'CHUNK #03 // Cluster GPU Quantum-Core & KV Cache',
        content:
            'L\'infrastruttura di calcolo Quantum-Core impiega 64 nodi tensoriali interconnessi via NVLink. '
            'Ogni nodo riserva esattamente 32 GB di VRAM HBM3 alla sola KV-Cache per accelerare il contesto lungo.',
        vectorPreview: [0.18, 0.64, -0.75, 0.51],
        spacePos: const Offset(0.38, 0.52),
        keywords: ['nodi', 'tensoriali', 'cluster', 'quantum', 'core', 'vram', 'cache', 'kv', 'gpu', 'memoria'],
      ),
      RagChunk(
        id: 4,
        title: 'CHUNK #04 // Policy Alimentazione & Raffreddamento Data Center',
        content:
            'Il sistema di raffreddamento a liquido diretto mantiene i rack a una temperatura costante di 21°C '
            'con un indice di efficienza energetica PUE pari a 1.08 usando energia geotermica.',
        vectorPreview: [-0.71, -0.58, -0.22, 0.39],
        spacePos: const Offset(-0.55, -0.42),
        keywords: ['raffreddamento', 'temperatura', 'liquido', 'energia', 'data', 'center', 'pue'],
      ),
      RagChunk(
        id: 5,
        title: 'CHUNK #05 // SLA Latenza & Telemetria Pacchetti',
        content:
            'Il monitoraggio telemetrico campiona i pacchetti sulla porta 8443 ogni 100 millisecondi, '
            'registrando jitter, perdita pacchetti e verificando il rispetto dei 12.5 ms del protocollo Hyperion.',
        vectorPreview: [0.76, -0.22, 0.61, 0.09],
        spacePos: const Offset(0.22, -0.18),
        keywords: ['latenza', 'telemetria', 'pacchetti', 'porta', '8443', 'hyperion', 'ms', 'monitoraggio'],
      ),
    ];
  }

  void _recomputeSimilarities(String query) {
    final qLower = query.toLowerCase();
    final qWords = qLower
        .split(RegExp(r'[^a-zA-Z0-9àèéìòù]+'))
        .where((w) => w.length > 2)
        .toSet();

    // Determina il baricentro vettoriale della query in base alle parole chiave
    double qx = 0.05;
    double qy = -0.05;
    for (final c in _chunks) {
      int hits = c.keywords.where((k) => qLower.contains(k) || qWords.contains(k)).length;
      if (hits > 0) {
        qx += c.spacePos.dx * hits * 0.35;
        qy += c.spacePos.dy * hits * 0.35;
      }
    }
    _queryVectorPos = Offset(qx.clamp(-0.75, 0.75), qy.clamp(-0.75, 0.75));
    _queryVectorPreview = [
      double.parse(_queryVectorPos.dx.toStringAsFixed(2)),
      double.parse(_queryVectorPos.dy.toStringAsFixed(2)),
      double.parse(((_queryVectorPos.dx - _queryVectorPos.dy) * 0.6).clamp(-0.99, 0.99).toStringAsFixed(2)),
      0.24,
    ];

    // Calcola Cosine Similarity simulata + lessematica per ogni Chunk
    for (final c in _chunks) {
      int hits = c.keywords.where((k) => qLower.contains(k) || qWords.contains(k)).length;
      double dist = (c.spacePos - _queryVectorPos).distance;
      double geomSim = (1.0 - (dist / 1.6)).clamp(0.12, 0.96);
      double keywordBoost = min(0.45, hits * 0.14);
      c.similarityScore = (geomSim * 0.65 + keywordBoost).clamp(0.11, 0.98);
      c.isSelectedTopK = false;
    }

    // Ordina una copia per determinare i Top-K sopra soglia
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

  void _buildGroundedResponses(String query) {
    final selected = _chunks.where((c) => c.isSelectedTopK).toList()
      ..sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    _noRagResponse =
        '⚠️ RISPOSTA SENZA RAG (Solo memoria pre-addestrata del modello):\n'
        '"Non ho accesso alla documentazione interna del vostro progetto (Hyperion / Aegis / Quantum-Core). '
        'Posso solo ipotizzare valori generici standard (es. porta 443 e latenza 50-100ms), '
        'rischiando di generare un\'ALLUCINAZIONE con dati inventati!"';

    if (selected.isEmpty) {
      _ragResponse =
          'Nessun Chunk ha superato la soglia di similarità (${(_similarityThreshold * 100).toInt()}%). '
          'Il sistema RAG evita di inventare una risposta e dichiara che l\'informazione non è presente nei documenti forniti.';
    } else {
      final citations = selected.map((c) => '[Fonte: Chunk #0${c.id}]').join(' ');
      final synth = selected.map((c) => '• ${c.content} (Affinità: ${(c.similarityScore * 100).toStringAsFixed(0)}%)').join('\n');
      _ragResponse =
          '✅ RISPOSTA VERIFICATA CON RAG $citations:\n'
          'In base ai frammenti estratti dal Vector Database per la tua domanda:\n$synth';
    }
  }

  Future<void> _runFullRagPipeline() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _recomputeSimilarities(_queryCtrl.text);
      _currentStage = RagStage.chunking;
    });

    const delay = Duration(milliseconds: 700);
    await Future.delayed(delay);
    if (!mounted) return;
    setState(() => _currentStage = RagStage.embedding);

    await Future.delayed(delay);
    if (!mounted) return;
    setState(() => _currentStage = RagStage.vectorSearch);

    await Future.delayed(delay);
    if (!mounted) return;
    setState(() => _currentStage = RagStage.promptAugment);

    await Future.delayed(delay);
    if (!mounted) return;
    setState(() {
      _currentStage = RagStage.llmGeneration;
      _isRunning = false;
    });
  }

  void _nextStage() {
    const stages = RagStage.values;
    final nextIdx = (stages.indexOf(_currentStage) + 1) % stages.length;
    setState(() {
      _recomputeSimilarities(_queryCtrl.text);
      _currentStage = stages[nextIdx == 0 ? 1 : nextIdx];
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool wide = constraints.maxWidth > 980;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 11, child: _buildLeftVectorSpacePanel(true)),
            Container(width: 1, color: Colors.purpleAccent.withOpacity(0.18)),
            Expanded(flex: 10, child: _buildRightRagInspectorPanel(true)),
          ],
        );
      } else {
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildLeftVectorSpacePanel(false),
              Container(height: 1, color: Colors.purpleAccent.withOpacity(0.18)),
              _buildRightRagInspectorPanel(false),
            ],
          ),
        );
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PANNELLO SINISTRO: VECTOR DATABASE SPACE 2D + PIPELINE STEPPER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLeftVectorSpacePanel(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 22 : 14),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF170E2C), Color(0xFF06060F)],
          radius: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFB388FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.45)),
                ),
                child: Text(
                  'LAB 03 // PIPELINE RAG & VECTOR DB',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFB388FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Come collegare documenti privati a un LLM eliminando le allucinazioni',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra delle 5 fasi RAG cliccabili
          _buildRagStageBar(),
          const SizedBox(height: 12),

          // Canvas interattivo: Spazio Vettoriale 2D + Ricerca Cosine Similarity
          if (wide)
            Expanded(child: _buildVectorSpaceCanvas())
          else
            SizedBox(height: 300, child: _buildVectorSpaceCanvas()),

          const SizedBox(height: 12),

          // Box didattico che spiega la fase selezionata della pipeline RAG
          _buildStageExplanationBox(),
        ],
      ),
    );
  }

  Widget _buildRagStageBar() {
    final stages = [
      (RagStage.chunking, '1. CHUNKING', Colors.cyanAccent),
      (RagStage.embedding, '2. EMBEDDING', const Color(0xFFB388FF)),
      (RagStage.vectorSearch, '3. VECTOR SEARCH', Colors.amberAccent),
      (RagStage.promptAugment, '4. PROMPT INJECT', const Color(0xFFFF6B35)),
      (RagStage.llmGeneration, '5. GENERAZIONE', const Color(0xFF69F0AE)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: stages.map((st) {
              final bool active = _currentStage == st.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _currentStage = st.$1),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? st.$3.withOpacity(0.22) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: active ? st.$3 : Colors.white12),
                    ),
                    child: Text(
                      st.$2,
                      style: GoogleFonts.spaceMono(
                        color: active ? st.$3 : Colors.white54,
                        fontSize: 8.5,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
              ),
              child: Text(
                'Passo Successivo ▶',
                style: GoogleFonts.spaceMono(color: Colors.cyanAccent, fontSize: 8.5),
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
        border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.25)),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _RagVectorSpacePainter(
                  chunks: _chunks,
                  queryPos: _queryVectorPos,
                  queryVector: _queryVectorPreview,
                  stage: _currentStage,
                  animPhase: _animCtrl.value,
                ),
              );
            },
          ),
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'VECTOR DATABASE // SPAZIO EMBEDDING MULTIDIMENSIONALE (Cosine Similarity)',
                style: GoogleFonts.spaceMono(color: const Color(0xFFB388FF), fontSize: 8.5),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(Colors.amberAccent, 'Query Utente (Vettore Domanda)'),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF69F0AE), 'Chunk Recuperato (Top-K Match)'),
                  const SizedBox(width: 12),
                  _legendDot(Colors.blueGrey, 'Chunk Scartato (Bassa Affinità)'),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
      ],
    );
  }

  Widget _buildStageExplanationBox() {
    String title;
    String body;
    String formula;
    Color col;

    switch (_currentStage) {
      case RagStage.idle:
      case RagStage.chunking:
        title = 'FASE 1 // DOCUMENT CHUNKING (Frammentazione Intelligente)';
        body =
            'Un manuale di 500 pagine non può essere inviato tutto insieme a ogni domanda (costerebbe troppo e confonderebbe il modello). '
            'Il documento viene quindi diviso in blocchi autonomi da 150-500 parole detti "Chunk", mantenendo un piccolo margine di sovrapposizione (Overlap) per non spezzare le frasi a metà.';
        formula = 'Documento (N pagine) ──► [Chunk #01, Chunk #02, ..., Chunk #k]';
        col = Colors.cyanAccent;
        break;
      case RagStage.embedding:
        title = 'FASE 2 // VECTOR EMBEDDING (Traduzione Semantica in Numeri)';
        body =
            'Un modello di Embedding trasforma sia ogni Chunk sia la domanda dell\'utente in una lista di coordinate numeriche (es. 768 o 1536 numeri decimali). '
            'Frasi che parlano dello stesso argomento finiscono geometricamente vicine nello spazio vettoriale, anche se usano sinonimi!';
        formula = 'Embedding("Qual è la latenza?") ──► Vettore Q = $_queryVectorPreview';
        col = const Color(0xFFB388FF);
        break;
      case RagStage.vectorSearch:
        title = 'FASE 3 // RICERCA PER SIMILARITÀ COSENO (Top-K Retrieval)';
        body =
            'Il Vector Database calcola l\'angolo geometrico tra il vettore della tua domanda (Q) e tutti i Chunk archiviati (C). '
            'Più il coseno dell\'angolo si avvicina a 1.0 (100%), più il frammento è pertinente. Vengono estratti solo i migliori Top-$_topK Chunk sopra la soglia.';
        formula = 'CosineSimilarity(Q, C) = (Q · C) / (||Q|| × ||C||)  ──►  Estrazione Top-$_topK Chunk';
        col = Colors.amberAccent;
        break;
      case RagStage.promptAugment:
        title = 'FASE 4 // CONTEXT AUGMENTATION (Prompt Injection Verificata)';
        body =
            'Prima di chiamare l\'API dell\'LLM, il programma incolla automaticamente i Top-$_topK Chunk appena trovati dentro il Prompt, '
            'istruendo il modello a rispondere basandosi ESCLUSIVAMENTE sui fatti forniti nel contesto.';
        formula = 'Prompt Finale = [Istruzione Anti-Allucinazione] + [Top-$_topK Chunk] + [Domanda Utente]';
        col = const Color(0xFFFF6B35);
        break;
      case RagStage.llmGeneration:
        title = 'FASE 5 // GENERAZIONE GROUNDED (Zero Allucinazioni & Citazione Fonti)';
        body =
            'L\'LLM non deve più "indovinare a memoria": legge i dati esatti iniettati nel prompt (es. 12.5 ms, porta 8443) e sintetizza '
            'una risposta precisa citando il Chunk di provenienza. Guarda a destra il confronto tra Risposta Senza RAG e Con RAG!';
        formula = 'LLM(Prompt Aumentato) ──► Risposta Certificata + Citazione [Chunk #ID]';
        col = const Color(0xFF69F0AE);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceMono(color: col, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, height: 1.45),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: col.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: col.withOpacity(0.25)),
            ),
            child: Text(
              formula,
              style: GoogleFonts.spaceMono(color: col, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PANNELLO DESTRO: CONTROLLI QUERY, CLASSIFICA CHUNK, PROMPT AUMENTATO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRightRagInspectorPanel(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 22 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQueryControllerCard(),
          const SizedBox(height: 12),
          _buildRightTabs(),
          const SizedBox(height: 12),
          if (wide)
            Expanded(child: _buildRightTabBody())
          else
            SizedBox(height: 450, child: _buildRightTabBody()),
        ],
      ),
    );
  }

  Widget _buildQueryControllerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Domande di esempio rapide
          Row(
            children: [
              Text(
                'DOMANDA UTENTE (QUERY DI RICERCA):',
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFFB388FF),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ...List.generate(_presetQuestions.length, (i) {
                final bool sel = _selectedPresetQuestion == i;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPresetQuestion = i;
                        _queryCtrl.text = _presetQuestions[i].$2;
                        _recomputeSimilarities(_queryCtrl.text);
                      });
                    },
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFB388FF).withOpacity(0.22)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: sel ? const Color(0xFFB388FF) : Colors.white12,
                        ),
                      ),
                      child: Text(
                        _presetQuestions[i].$1,
                        style: GoogleFonts.spaceMono(
                          color: sel ? const Color(0xFFB388FF) : Colors.white60,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  onChanged: (v) => setState(() => _recomputeSimilarities(v)),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Fai una domanda sui documenti nel Vector Database...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runFullRagPipeline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB388FF).withOpacity(0.2),
                  foregroundColor: const Color(0xFFB388FF),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  side: const BorderSide(color: Color(0xFFB388FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.bolt, size: 16),
                label: Text(
                  'ESEGUI RAG',
                  style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Controlli Top-K e Soglia Similarità
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Top-K Chunks da estrarre: $_topK',
                    style: GoogleFonts.spaceMono(color: Colors.cyanAccent, fontSize: 9.5),
                  ),
                  SizedBox(
                    width: 100,
                    height: 24,
                    child: Slider(
                      value: _topK.toDouble(),
                      min: 1,
                      max: 4,
                      divisions: 3,
                      activeColor: Colors.cyanAccent,
                      onChanged: (v) {
                        setState(() {
                          _topK = v.round();
                          _recomputeSimilarities(_queryCtrl.text);
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Soglia Minima: ${(_similarityThreshold * 100).toInt()}%',
                    style: GoogleFonts.spaceMono(color: Colors.amberAccent, fontSize: 9.5),
                  ),
                  SizedBox(
                    width: 100,
                    height: 24,
                    child: Slider(
                      value: _similarityThreshold,
                      min: 0.20,
                      max: 0.85,
                      divisions: 13,
                      activeColor: Colors.amberAccent,
                      onChanged: (v) {
                        setState(() {
                          _similarityThreshold = v;
                          _recomputeSimilarities(_queryCtrl.text);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightTabs() {
    final tabs = [
      (Icons.storage, '1. VECTOR DB & SIMILARITY'),
      (Icons.integration_instructions_outlined, '2. PROMPT INJECTION'),
      (Icons.compare_arrows, '3. SENZA RAG vs CON RAG'),
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
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFB388FF).withOpacity(0.18)
                      : Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? const Color(0xFFB388FF) : Colors.white12,
                  ),
                ),
                child: Center(
                  child: Text(
                    tabs[i].$2,
                    style: GoogleFonts.spaceMono(
                      color: active ? const Color(0xFFB388FF) : Colors.white60,
                      fontSize: 9,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
        return _buildChunksRankingList();
      case 1:
        return _buildAugmentedPromptInspector();
      default:
        return _buildComparisonView();
    }
  }

  // ── TAB 1: Classifica dei Chunk nel Vector DB con barra di Cosine Similarity ──
  Widget _buildChunksRankingList() {
    final sorted = List<RagChunk>.from(_chunks)
      ..sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = sorted[i];
        final Color col = c.isSelectedTopK ? const Color(0xFF69F0AE) : Colors.white38;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.isSelectedTopK
                ? const Color(0xFF69F0AE).withOpacity(0.06)
                : Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: c.isSelectedTopK ? const Color(0xFF69F0AE).withOpacity(0.5) : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: col.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.isSelectedTopK ? '✓ RECUPERATO (TOP-K)' : 'SCARTATO',
                      style: GoogleFonts.spaceMono(
                        color: col,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.title,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'cos(θ) = ${(c.similarityScore * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.spaceMono(
                      color: col,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Barra grafica di similarità coseno
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: c.similarityScore,
                  minHeight: 5,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(col),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.content,
                style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 11, height: 1.35),
              ),
              const SizedBox(height: 4),
              Text(
                'Embedding Vector: ${c.vectorPreview} ... (768 dim)',
                style: GoogleFonts.spaceMono(color: Colors.purpleAccent.withOpacity(0.65), fontSize: 8.5),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── TAB 2: Come viene assemblato il Prompt Aumentato (Prompt Injection benigna) ──
  Widget _buildAugmentedPromptInspector() {
    final selected = _chunks.where((c) => c.isSelectedTopK).toList();
    final contextBlocks = selected.isEmpty
        ? '[NESSUN CHUNK SOPRA SOGLIA]'
        : selected.map((c) => '--- [${c.title}] ---\n${c.content}').join('\n\n');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.35)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANATOMIA DEL PROMPT AUMENTATO INVIATO ALL\'LLM:',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFFFF6B35),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Il segreto della RAG è che l\'LLM riceve un unico grande testo composto da 3 blocchi distinti assemblati dal tuo codice prima della chiamata API:',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
            const SizedBox(height: 12),

            _promptSectionCard(
              label: 'BLOCCO 1 // SYSTEM INSTRUCTION (Regole di Grounding)',
              color: Colors.cyanAccent,
              text:
                  'Sei un assistente accademico rigoroso. Rispondi alla domanda dell\'utente basandoti ESCLUSIVAMENTE sui frammenti di contesto forniti qui sotto. Cita sempre il numero del Chunk usato. Se la risposta non è nel contesto, dichiara che non disponi dei dati.',
            ),
            const SizedBox(height: 10),

            _promptSectionCard(
              label: 'BLOCCO 2 // CONTESTO INIETTATO DAL VECTOR DB (Top-${selected.length} Chunks)',
              color: const Color(0xFF69F0AE),
              text: contextBlocks,
            ),
            const SizedBox(height: 10),

            _promptSectionCard(
              label: 'BLOCCO 3 // DOMANDA ORIGINALE DELL\'UTENTE',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SelectableText(
            text,
            style: GoogleFonts.spaceMono(color: Colors.white.withOpacity(0.9), fontSize: 10.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: Confronto Diretto Senza RAG vs Con RAG ──
  Widget _buildComparisonView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❌ LLM TRADIZIONALE (SENZA RAG)',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFFF5252),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _noRagResponse,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF69F0AE).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.45)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ LLM CON PIPELINE RAG ATTIVA (GROUNDED GENERATION)',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF69F0AE),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ragResponse,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11.5, height: 1.45),
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
// CUSTOM PAINTER: SPAZIO VETTORIALE 2D E RICERCA COSINE SIMILARITY
// ─────────────────────────────────────────────────────────────────────────────
class _RagVectorSpacePainter extends CustomPainter {
  final List<RagChunk> chunks;
  final Offset queryPos;
  final List<double> queryVector;
  final RagStage stage;
  final double animPhase;

  _RagVectorSpacePainter({
    required this.chunks,
    required this.queryPos,
    required this.queryVector,
    required this.stage,
    required this.animPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) * 0.40;

    // Cerchi radar ed assi dello spazio di Embedding
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), gridPaint);
    }
    canvas.drawLine(Offset(20, center.dy), Offset(size.width - 20, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 20), Offset(center.dx, size.height - 20), gridPaint);

    final Offset qScreen = Offset(
      center.dx + queryPos.dx * radius,
      center.dy + queryPos.dy * radius,
    );

    // Onda radar di scansione durante Vector Search
    if (stage == RagStage.vectorSearch || stage == RagStage.promptAugment || stage == RagStage.llmGeneration) {
      final double waveRadius = (animPhase * radius * 1.3);
      final Paint radarPaint = Paint()
        ..color = Colors.amberAccent.withOpacity((1.0 - animPhase) * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(qScreen, waveRadius, radarPaint);
    }

    // Disegna le linee di distanza / Cosine Similarity tra Query e Chunks
    for (final c in chunks) {
      final Offset cScreen = Offset(
        center.dx + c.spacePos.dx * radius,
        center.dy + c.spacePos.dy * radius,
      );

      final bool highlight = c.isSelectedTopK;
      final Color lineCol = highlight
          ? const Color(0xFF69F0AE).withOpacity(0.75)
          : Colors.white.withOpacity(0.12);

      final Paint linePaint = Paint()
        ..color = lineCol
        ..strokeWidth = highlight ? 2.0 : 0.8;
      canvas.drawLine(qScreen, cScreen, linePaint);

      // Etichetta percentuale di similarità a metà della linea per i Top-K
      if (highlight) {
        final Offset mid = Offset.lerp(qScreen, cScreen, 0.5)!;
        _drawLabel(
          canvas,
          'cos=${(c.similarityScore * 100).toInt()}%',
          mid.translate(0, -8),
          const Color(0xFF69F0AE),
          9,
          bold: true,
        );
      }

      // Nodo del Chunk
      final Color nodeCol = highlight ? const Color(0xFF69F0AE) : Colors.blueGrey.shade300;
      if (highlight) {
        canvas.drawCircle(
          cScreen,
          16,
          Paint()
            ..color = nodeCol.withOpacity(0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      canvas.drawCircle(cScreen, highlight ? 7 : 5, Paint()..color = nodeCol);

      _drawLabel(
        canvas,
        'Chunk #0${c.id}',
        cScreen.translate(0, -15),
        nodeCol,
        9.5,
        bold: highlight,
      );
      _drawLabel(
        canvas,
        '${c.vectorPreview.take(2).toList()}',
        cScreen.translate(0, 14),
        Colors.white54,
        8,
      );
    }

    // Disegna il nodo della Query Utente (Stella Ambra)
    canvas.drawCircle(
      qScreen,
      20,
      Paint()
        ..color = Colors.amberAccent.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(qScreen, 7.5, Paint()..color = Colors.amberAccent);
    _drawLabel(
      canvas,
      'QUERY VECTOR',
      qScreen.translate(0, -16),
      Colors.amberAccent,
      9.5,
      bold: true,
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
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: col,
          fontSize: fontSize,
          fontFamily: 'monospace',
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RagVectorSpacePainter oldDelegate) => true;
}
