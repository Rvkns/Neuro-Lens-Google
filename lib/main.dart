// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'particle_engine.dart';
import 'globe_painter.dart';
import 'semantic_compass.dart';
import 'api_lab.dart';
import 'rag_lab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}
  runApp(const NeuralLensApp());
}

class NeuralLensApp extends StatelessWidget {
  const NeuralLensApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neural Lens v4.0 // Academic Edition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06060F),
        textTheme: GoogleFonts.spaceMonoTextTheme(ThemeData.dark().textTheme),
      ),
      home: const AcademicShell(),
    );
  }
}

// ─── SHELL ACCADEMICA MULTI-MODULO (Navigazione Superiore) ───
class AcademicShell extends StatefulWidget {
  const AcademicShell({super.key});

  @override
  State<AcademicShell> createState() => _AcademicShellState();
}

class _AcademicShellState extends State<AcademicShell> {
  int _selectedIndex = 0;
  double _textScale = 1.12; // Scala di default potenziata per massima leggibilità
  late final GenerativeModel _sharedModel;
  late final bool _hasKey;

  @override
  void initState() {
    super.initState();
    String key = const String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) {
      key = dotenv.env['GEMINI_API_KEY'] ?? '';
    }
    _hasKey = key.isNotEmpty;
    _sharedModel = GenerativeModel(model: 'gemini-2.5-flash', apiKey: key);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(_textScale)),
      child: Scaffold(
        body: Column(
          children: [
            _buildTopAcademicNavBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  NeuralWorkspace(
                    onOpenApiLab: () => setState(() => _selectedIndex = 1),
                  ),
                  ApiLabWorkspace(
                    geminiModel: _sharedModel,
                    hasValidKey: _hasKey,
                  ),
                  RagLabWorkspace(
                    geminiModel: _sharedModel,
                    hasValidKey: _hasKey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAcademicNavBar() {
    final modules = [
      (
        0,
        Icons.blur_on,
        'LAB 01 // RETI NEURALI & LLM',
        'Spazio Latente 3D, Softmax & Embedding',
        Colors.cyanAccent,
      ),
      (
        1,
        Icons.api,
        'LAB 02 // CHIAMATE API & CODICE',
        'Flusso Client⇄Server, JSON, Status HTTP & SDK',
        const Color(0xFF69F0AE),
      ),
      (
        2,
        Icons.hub_outlined,
        'LAB 03 // PIPELINE RAG & VECTOR DB',
        'Chunking, Cosine Similarity & Anti-Allucinazione',
        const Color(0xFFB388FF),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080916),
        border: Border(
          bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.22), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 12),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Brand Accademico
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEURAL LENS // ACADEMIC LAB',
                    style: GoogleFonts.spaceMono(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Visualizzatore Interattivo di Meccanismi AI & Architetture Moderne',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          // Selettori Moduli Didattici + Controllo Zoom Testo
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...modules.map((m) {
                final bool active = _selectedIndex == m.$1;
                final Color col = m.$5;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = m.$1),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? col.withOpacity(0.18) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active ? col : Colors.white.withOpacity(0.18),
                        width: active ? 1.4 : 1.0,
                      ),
                      boxShadow: active
                          ? [BoxShadow(color: col.withOpacity(0.2), blurRadius: 10)]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.$2, size: 18, color: active ? col : Colors.white70),
                        const SizedBox(width: 9),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.$3,
                              style: GoogleFonts.spaceMono(
                                color: active ? col : Colors.white,
                                fontSize: 11,
                                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              m.$4,
                              style: TextStyle(
                                color: Colors.white.withOpacity(active ? 0.85 : 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Selettore Zoom Testo (A- / A / A+)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.text_fields, size: 15, color: Colors.cyanAccent),
                    const SizedBox(width: 6),
                    _zoomBtn('100%', 1.0),
                    const SizedBox(width: 4),
                    _zoomBtn('112%', 1.12),
                    const SizedBox(width: 4),
                    _zoomBtn('125%', 1.25),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zoomBtn(String label, double scale) {
    final bool active = (_textScale - scale).abs() < 0.02;
    return InkWell(
      onTap: () => setState(() => _textScale = scale),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.cyanAccent.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? Colors.cyanAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            color: active ? Colors.cyanAccent : Colors.white70,
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Candidato token per la Probability Matrix ───
class TokenCandidate {
  final String word;
  final double probability;
  final bool isSelected;
  TokenCandidate({required this.word, required this.probability, required this.isSelected});
}

// ─── Metriche live ───
class LiveMetrics {
  int totalTokens = 0;
  double tokensPerSecond = 0.0;
  double entropy = 0.0;
  int? firstTokenMs;
  DateTime? _streamStart;
  DateTime? _lastToken;

  void onStreamStart() {
    _streamStart = DateTime.now();
    _lastToken = null;
    totalTokens = 0;
  }

  void onToken(List<TokenCandidate> candidates) {
    final now = DateTime.now();
    firstTokenMs ??= now.difference(_streamStart!).inMilliseconds;
    totalTokens++;
    if (_lastToken != null) {
      double elapsed = now.difference(_streamStart!).inMilliseconds / 1000.0;
      tokensPerSecond = elapsed > 0 ? totalTokens / elapsed : 0;
    }
    _lastToken = now;
    // Entropia simulata di Shannon: H = -Σ p*log2(p)
    entropy = -candidates.fold(0.0, (sum, c) {
      if (c.probability <= 0) return sum;
      return sum + c.probability * (log(c.probability) / log(2));
    });
  }
}

class NeuralWorkspace extends StatefulWidget {
  final VoidCallback? onOpenApiLab;
  const NeuralWorkspace({super.key, this.onOpenApiLab});
  @override
  State<NeuralWorkspace> createState() => _NeuralWorkspaceState();
}

class _NeuralWorkspaceState extends State<NeuralWorkspace>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _tokens = [];
  bool _isReceiving = false;
  late final GenerativeModel _model;

  // Rotazione globo 3D
  double _globeRotY = 0.0;
  static const double _autoRotSpeed = 0.003;

  // Posizione mouse relativa al globo (Offset.zero = centro)
  Offset _mouseOffset = Offset.zero;

  // Token Probability Matrix
  List<TokenCandidate> _candidates = [];
  String _decodingToken = "";

  // Semantic Compass
  String _currentSemanticToken = "";
  List<SemanticWord> _semanticNeighbors = [];

  // Metriche live
  final LiveMetrics _metrics = LiveMetrics();
  String _networkState = "IN ATTESA";

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initGemini();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _controller.addListener(_onFrame);
  }

  void _initParticles() {
    final rnd = Random();
    // Distribuzione di Fibonacci sulla sfera per massima uniformità
    final golden = pi * (3 - sqrt(5));
    for (int i = 0; i < 150; i++) {
      double y = 1 - (i / 149) * 2;
      double r = sqrt(1 - y * y);
      double phi = golden * i;
      _particles.add(Particle(
        phi: acos(y.clamp(-1.0, 1.0)),
        theta: phi,
        radius: 280.0 + rnd.nextDouble() * 110.0, // Raggio aumentato di circa 80%
        baseMaxSpeed: 0.6 + rnd.nextDouble() * 0.8,
        size: rnd.nextDouble() * 3.5 + 2.5, // Nodi più grandi e visibili
      ));
    }
  }

  void _initGemini() {
    String key = const String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) {
      key = dotenv.env['GEMINI_API_KEY'] ?? '';
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: key);
  }

  void _onFrame() {
    if (!mounted) return;
    _globeRotY += _autoRotSpeed;
    double breath = 1.0 + sin(_controller.value * 2 * pi) * 0.06;
    for (var p in _particles) {
      p.updateProjection(0.35, _globeRotY, breath);
      p.update(_mouseOffset);
    }
    // OTTIMIZZAZIONE 1: Nessun setState generale chiamato qui. 
    // L'UI principale smette di ricalcolarsi 60 volte al secondo!
  }

  void _exciteNetwork(int n, {List<String>? concepts}) {
    final rnd = Random();
    int count = min(n * 4, _particles.length ~/ 2);
    for (int i = 0; i < count; i++) {
      String? assignedConcept;
      if (concepts != null && concepts.isNotEmpty) {
        assignedConcept = concepts[rnd.nextInt(concepts.length)];
      }
      _particles[rnd.nextInt(_particles.length)].excite(0.4 + rnd.nextDouble() * 0.6, concept: assignedConcept);
    }
  }

  void _playTickSound() {
    try {
      js.context.callMethod('eval', [
        '''(function(){
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          var o = ctx.createOscillator();
          var g = ctx.createGain();
          o.connect(g); g.connect(ctx.destination);
          o.type = 'sine';
          o.frequency.value = 880 + Math.random() * 440;
          g.gain.setValueAtTime(0.04, ctx.currentTime);
          g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.08);
          o.start(ctx.currentTime); o.stop(ctx.currentTime + 0.08);
        })()'''
      ]);
    } catch (_) {}
  }

  void _updateCandidates(String token) {
    final rnd = Random();
    double winP = 0.60 + rnd.nextDouble() * 0.28;
    double rem = 1.0 - winP;
    List<String> alts = [_mutateSuffix(token, rnd), _scramble(token, rnd)];
    List<double> altP = [rem * 0.58, rem * 0.42];
    final cands = [
      TokenCandidate(word: token, probability: winP, isSelected: true),
      ...alts.asMap().entries.map((e) =>
          TokenCandidate(word: e.value, probability: altP[e.key], isSelected: false)),
    ];
    _metrics.onToken(cands);
    setState(() => _candidates = cands);
  }

  String _mutateSuffix(String t, Random r) {
    const s = ['are', 'ità', 'ivo', 'ale', 'zione', 'ore'];
    String b = t.length > 4 ? t.substring(0, t.length - 2) : t;
    return b + s[r.nextInt(s.length)];
  }

  String _scramble(String t, Random r) {
    if (t.length < 3) return '${t}s';
    List<String> ch = t.split('');
    ch.sublist(max(0, ch.length - 3)).shuffle(r);
    return ch.join();
  }

  Future<void> _decodeEffect(String token) async {
    const g = '!@#\$%^█▓▒░▐▌><{}~';
    final r = Random();
    for (int i = 0; i < 4; i++) {
      if (!mounted) break;
      setState(() => _decodingToken = List.generate(token.length, (_) => g[r.nextInt(g.length)]).join());
      await Future.delayed(const Duration(milliseconds: 45));
    }
    if (mounted) setState(() => _decodingToken = "");
  }

  Future<void> _sendPrompt() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _metrics.onStreamStart();
    setState(() {
      _tokens.clear();
      _candidates = [];
      _decodingToken = "";
      _tokens.add(">> Inizializzazione rete neurale...\n");
      _isReceiving = true;
      _networkState = "ELABORAZIONE";
    });
    try {
      final stream = _model.generateContentStream([Content.text(text)]);
      await for (final chunk in stream) {
        if (!mounted) break;
        if (chunk.text == null || chunk.text!.isEmpty) continue;
        final words = RegExp(r'(\S+|\n)').allMatches(chunk.text!);
        for (final m in words) {
          if (!mounted) break;
          final w = m.group(0)!;
          _updateCandidates(w);
          _playTickSound();
          await _decodeEffect(w);

          List<String> currentConcepts = [];
          if (w.trim().isNotEmpty && w.trim().length > 1) {
             currentConcepts.add(w.trim());
             currentConcepts.addAll(generateSemanticNeighbors(w).map((e) => e.word));
          }
          
          _exciteNetwork(1, concepts: currentConcepts);

          setState(() {
            _tokens.add(w == '\n' ? '\n' : w);
            _currentSemanticToken = w;
            _semanticNeighbors = generateSemanticNeighbors(w);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() => _tokens.add("\n[ERRORE]: $e"));
    } finally {
      if (mounted) {
        setState(() {
          _tokens.add("\n>> Trasmissione completata.");
          _isReceiving = false;
          _networkState = "IN ATTESA";
          _decodingToken = "";
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      bool wide = constraints.maxWidth > 900;
      final panels = [_buildGlobePanel(wide), _divider(wide), _buildAnalysisPanel(wide)];
      return wide
          ? Row(children: panels)
          : SingleChildScrollView(child: Column(children: panels));
    });
  }

  // ─────────────── PANNELLO SINISTRO ───────────────
  Widget _buildGlobePanel(bool wide) {
    Widget globe = MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        setState(() {
          _mouseOffset = Offset(
            e.localPosition.dx - (wide ? size.width / 4 : size.width / 2),
            e.localPosition.dy - (wide ? size.height / 2 : 200),
          );
        });
      },
      onExit: (_) => setState(() => _mouseOffset = Offset.zero),
      child: Container(
        height: wide ? double.infinity : 380,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: _isReceiving
                ? [const Color(0xFF0D1A2E), const Color(0xFF060610)]
                : [const Color(0xFF101018), const Color(0xFF060610)],
            radius: 1.2,
          ),
        ),
        child: Stack(children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: GlobePainter(particles: _particles, isActive: _isReceiving),
              );
            },
          ),
          Positioned(
            top: 14, 
            left: 14, 
            child: Transform.scale(
              scale: wide ? 1.0 : 0.8, 
              alignment: Alignment.topLeft, 
              child: _buildLegendHUD()
            )
          ),
          Positioned(bottom: 14, left: 0, right: 0, child: Center(child: _buildNetworkStatus())),
        ]),
      ),
    );
    return wide ? Expanded(flex: 1, child: globe) : globe;
  }

  Widget _divider(bool wide) => Container(
    width: wide ? 1 : double.infinity,
    height: wide ? double.infinity : 1,
    color: Colors.cyan.withOpacity(0.15),
  );

  // ─────────────── PANNELLO DESTRO ───────────────
  Widget _buildAnalysisPanel(bool wide) {
    Widget matrixCompass = wide
        ? Row(children: [
            Expanded(flex: 3, child: _buildProbabilityMatrix()),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: SemanticCompass(
              currentToken: _currentSemanticToken,
              neighbors: _semanticNeighbors,
              isActive: _isReceiving,
            )),
          ])
        : Column(children: [
            SizedBox(height: 220, child: _buildProbabilityMatrix()),
            const SizedBox(height: 10),
            SizedBox(height: 220, child: SemanticCompass(
              currentToken: _currentSemanticToken,
              neighbors: _semanticNeighbors,
              isActive: _isReceiving,
            )),
          ]);

    Widget content = Container(
      padding: EdgeInsets.all(wide ? 24.0 : 16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAB 01 // RETI NEURALI & LLM',
                      style: GoogleFonts.spaceMono(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent,
                        letterSpacing: 1.5,
                        shadows: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10)],
                      )),
                  const SizedBox(height: 4),
                  Text('Simulatore Didattico Spazio Latente, Softmax & Embedding // Gemini 2.5 Flash',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                ],
              ),
            ),
            if (widget.onOpenApiLab != null)
              InkWell(
                onTap: widget.onOpenApiLab,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.api, size: 16, color: Color(0xFF69F0AE)),
                      const SizedBox(width: 7),
                      Text(
                        'Dietro le quinte API ➔',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF69F0AE),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Metriche live
        _buildMetricsBar(wide),
        const SizedBox(height: 14),

        // Token stream
        if (wide) Expanded(flex: 4, child: _buildTokenStream())
        else SizedBox(height: 280, child: _buildTokenStream()),
        
        const SizedBox(height: 12),

        // Probability Matrix + Semantic Compass
        if (wide) Expanded(flex: 3, child: matrixCompass)
        else matrixCompass,
        
        const SizedBox(height: 14),

        // Input
        _buildInput(),
      ]),
    );

    return wide ? Expanded(flex: 1, child: content) : content;
  }

  Widget _buildMetricsBar(bool wide) {
    String latency = _metrics.firstTokenMs != null ? '${_metrics.firstTokenMs}ms' : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: wide
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _metricCell('TOKEN/s', _metrics.tokensPerSecond.toStringAsFixed(1), Colors.cyanAccent),
              _metricCell('TOTALE', '${_metrics.totalTokens}', Colors.white),
              _metricCell('ENTROPIA', _metrics.entropy.toStringAsFixed(2), Colors.purpleAccent),
              _metricCell('LATENZA', latency, const Color(0xFFFF6B35)),
            ])
          : Wrap(
              spacing: 16, runSpacing: 10, alignment: WrapAlignment.spaceBetween,
              children: [
                _metricCell('TOKEN/s', _metrics.tokensPerSecond.toStringAsFixed(1), Colors.cyanAccent),
                _metricCell('TOTALE', '${_metrics.totalTokens}', Colors.white),
                _metricCell('ENTROPIA', _metrics.entropy.toStringAsFixed(2), Colors.purpleAccent),
                _metricCell('LATENZA', latency, const Color(0xFFFF6B35)),
              ],
            ),
    );
  }

  Widget _metricCell(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildTokenStream() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.05), blurRadius: 20, spreadRadius: 4)],
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Wrap(spacing: 6, runSpacing: 4, children: [
          ..._tokens.map((t) {
            if (t == '\n') return const SizedBox(width: double.infinity, height: 8);
            if (t.startsWith('>>') || t.startsWith('[')) {
              return SizedBox(
                width: double.infinity,
                child: Text(t, style: TextStyle(color: Colors.cyanAccent.withOpacity(0.75), fontSize: 13)),
              );
            }
            return TokenWidget(token: t);
          }),
          if (_decodingToken.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.yellowAccent.withOpacity(0.6)),
              ),
              child: Text(_decodingToken,
                  style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontFamily: 'monospace')),
            ),
        ]),
      ),
    );
  }

  Widget _buildProbabilityMatrix() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('SOFTMAX DISTRIBUTION', style: GoogleFonts.spaceMono(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const Spacer(),
          Text(_isReceiving ? '● LIVE' : '○ IDLE',
              style: GoogleFonts.spaceMono(color: _isReceiving ? Colors.purpleAccent : Colors.white60, fontSize: 10.5)),
        ]),
        const SizedBox(height: 10),
        if (_candidates.isEmpty)
          Center(child: Text('In attesa...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)))
        else
          ..._candidates.map((c) => _candidateBar(c)),
      ]),
    );
  }

  Widget _candidateBar(TokenCandidate c) {
    Color col = c.isSelected ? Colors.cyanAccent : Colors.purpleAccent.withOpacity(0.8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(
            '${c.isSelected ? '▶ ' : '  '}${c.word}',
            style: GoogleFonts.spaceMono(
              color: col, fontSize: 12,
              fontWeight: c.isSelected ? FontWeight.bold : FontWeight.normal,
              decoration: c.isSelected ? null : TextDecoration.lineThrough,
              decorationColor: Colors.red.withOpacity(0.5),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(children: [
            Container(height: 12, decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(3))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 12,
              width: c.probability * 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: c.isSelected
                      ? [const Color(0xFF00BCD4), Colors.cyanAccent]
                      : [Colors.purple.withOpacity(0.4), Colors.purple.withOpacity(0.65)],
                ),
                boxShadow: c.isSelected ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.35), blurRadius: 4)] : [],
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Text('${(c.probability * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.spaceMono(color: col, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildLegendHUD() {
    return Container(
      width: 285,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LEGENDA RETE', style: GoogleFonts.spaceMono(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        _legendRow(Colors.cyanAccent, 'circle', 'NODO ATTIVO', 'Spazio Latente in elaborazione'),
        _legendRow(Colors.blue.shade300, 'circle', 'NODO INATTIVO', 'Embedding a riposo'),
        _legendRow(const Color(0xFFFF6B35), 'circle', 'NODO HOT', 'Alta attenzione storica (heatmap)'),
        _legendRow(Colors.cyanAccent, 'line', 'SINAPSI ATTIVA', 'Peso W_{ij} elevato'),
        _legendRow(Colors.blue.shade200.withOpacity(0.5), 'line', 'SINAPSI DEBOLE', 'Peso W_{ij} basso'),
      ]),
    );
  }

  Widget _legendRow(Color color, String shape, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 20, height: 20, child: Center(
          child: shape == 'circle'
              ? Container(width: 9, height: 9, decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)]))
              : Container(width: 18, height: 2.5, color: color),
        )),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildNetworkStatus() {
    Color c = _isReceiving ? Colors.cyanAccent : Colors.white70;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.5)),
        boxShadow: _isReceiving ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.18), blurRadius: 8)] : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          boxShadow: _isReceiving ? [BoxShadow(color: Colors.cyanAccent, blurRadius: 4)] : [],
        )),
        const SizedBox(width: 8),
        Text('RETE NEURALE: $_networkState',
            style: GoogleFonts.spaceMono(color: c, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ]),
    );
  }

  Widget _buildInput() {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: TextField(
            focusNode: _focusNode,
            controller: _textCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
            hintText: 'Invia stimolo alla rete neurale...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.55),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          onSubmitted: (_) => _sendPrompt(),
        ),
      ),
      ),
      const SizedBox(width: 10),
      InkWell(
        onTap: _isReceiving ? null : _sendPrompt,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isReceiving ? Colors.grey.withOpacity(0.15) : Colors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isReceiving ? Colors.transparent : Colors.cyanAccent.withOpacity(0.45),
            ),
            boxShadow: _isReceiving ? [] : [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Icon(Icons.send, color: _isReceiving ? Colors.white24 : Colors.cyanAccent, size: 20),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOKEN WIDGET — Animazione entrata slide+fade per ogni token generato
// ─────────────────────────────────────────────────────────────────────────────
class TokenWidget extends StatefulWidget {
  final String token;
  const TokenWidget({super.key, required this.token});
  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
      position: _slide,
      child: Text(widget.token, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16, height: 1.65)),
    ),
  );
}
