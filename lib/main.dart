// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:math';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'core_engine.dart';
import 'particle_engine.dart';
import 'globe_painter.dart';
import 'semantic_compass.dart';
import 'api_lab.dart';
import 'rag_lab.dart';
import 'docker_lab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}
  PerformanceMonitor.instance.start();
  runApp(const NeuralLensApp());
}

class NeuralLensApp extends StatelessWidget {
  const NeuralLensApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neural Lens v5.0 // HyperFluid Aurora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AuroraPalette.bgDeep,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: const AcademicShell(),
    );
  }
}

// ─── SHELL ACCADEMICA MULTI-MODULO (Con TickerMode Isolation & Live FPS Engine) ───
class AcademicShell extends StatefulWidget {
  const AcademicShell({super.key});

  @override
  State<AcademicShell> createState() => _AcademicShellState();
}

class _AcademicShellState extends State<AcademicShell> {
  int _selectedIndex = 0;
  double _textScale = 1.16;
  bool _isBeginnerMode = true;
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

  Color get _activeAccent {
    switch (_selectedIndex) {
      case 0:
        return AuroraPalette.cyan;
      case 1:
        return AuroraPalette.mint;
      case 2:
        return const Color(0xFFC084FC);
      default:
        return const Color(0xFF38BDF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(_textScale)),
      child: Scaffold(
        backgroundColor: AuroraPalette.bgDeep,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.85),
              radius: 1.55,
              colors: [
                _activeAccent.withOpacity(0.11),
                const Color(0xFF0A0F24),
                AuroraPalette.bgDeep,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: Column(
            children: [
              _buildTopAcademicNavBar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    // TickerMode(enabled) ferma al 100% i controller dei tab non visibili -> 0% CPU/GPU spreco!
                    TickerMode(
                      enabled: _selectedIndex == 0,
                      child: RepaintBoundary(
                        child: NeuralWorkspace(
                          isBeginnerMode: _isBeginnerMode,
                          onOpenApiLab: () => setState(() => _selectedIndex = 1),
                        ),
                      ),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 1,
                      child: RepaintBoundary(
                        child: ApiLabWorkspace(
                          geminiModel: _sharedModel,
                          hasValidKey: _hasKey,
                          isBeginnerMode: _isBeginnerMode,
                        ),
                      ),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 2,
                      child: RepaintBoundary(
                        child: RagLabWorkspace(
                          geminiModel: _sharedModel,
                          hasValidKey: _hasKey,
                          isBeginnerMode: _isBeginnerMode,
                        ),
                      ),
                    ),
                    TickerMode(
                      enabled: _selectedIndex == 3,
                      child: RepaintBoundary(
                        child: DockerLabWorkspace(
                          isBeginnerMode: _isBeginnerMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAcademicNavBar() {
    final modules = [
      (
        0,
        Icons.hub_rounded,
        'LAB 01 // RETI NEURALI 3D',
        _isBeginnerMode ? 'Come pensa e sceglie le parole' : 'Spazio Latente 3D, Softmax & Embedding',
        AuroraPalette.cyan,
      ),
      (
        1,
        Icons.bolt_rounded,
        'LAB 02 // CHIAMATE API',
        _isBeginnerMode ? 'Il "Cameriere" tra App e Server' : 'Flusso Client⇄Server, JSON & Codice',
        AuroraPalette.mint,
      ),
      (
        2,
        Icons.auto_stories_rounded,
        'LAB 03 // MEMORIA RAG & VETTORI',
        _isBeginnerMode ? 'Esame a Libro Aperto per l\'AI' : 'Chunking, Vector DB & Anti-Allucinazione',
        const Color(0xFFC084FC),
      ),
      (
        3,
        Icons.inventory_2_rounded,
        _isBeginnerMode ? 'LAB 04 // COS\'È DOCKER?' : 'LAB 04 // DOCKER & CONTAINER',
        _isBeginnerMode ? 'La "Valigia Magica" dei Programmi' : 'Dockerfile, Immagini, Layer & Runtime',
        const Color(0xFF38BDF8),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0E152D).withOpacity(0.95),
            const Color(0xFF080C1B).withOpacity(0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: _activeAccent.withOpacity(0.28), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Brand + Badge Motore Grafico
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_activeAccent, const Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: _activeAccent.withOpacity(0.45), blurRadius: 12),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF050711), size: 19),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NEURAL LENS',
                        style: AuroraPalette.headingStyle(
                          size: 15.5,
                          color: Colors.white,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _activeAccent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _activeAccent.withOpacity(0.45)),
                        ),
                        child: Text(
                          'v5.0 AURORA',
                          style: AuroraPalette.monoStyle(size: 9.0, color: _activeAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isBeginnerMode
                        ? 'Percorso "Parto da Zero": spiegazioni visive ed esempi interattivi'
                        : 'Modalità Accademica Tecnica: telemetria e architettura ingegneristica',
                    style: AuroraPalette.bodyStyle(
                      size: 11,
                      color: _isBeginnerMode ? AuroraPalette.mint : AuroraPalette.cyan,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Selettori Moduli Didattici + Switch Livello + FPS Badge + Zoom
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...modules.map((m) {
                final bool active = _selectedIndex == m.$1;
                final Color col = m.$5;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = m.$1),
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
                    decoration: BoxDecoration(
                      gradient: active
                          ? LinearGradient(
                              colors: [col.withOpacity(0.24), col.withOpacity(0.08)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: active ? null : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: active ? col : Colors.white.withOpacity(0.14),
                        width: active ? 1.5 : 1.0,
                      ),
                      boxShadow: active
                          ? [BoxShadow(color: col.withOpacity(0.18), blurRadius: 12)]
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
                              style: AuroraPalette.headingStyle(
                                color: active ? col : Colors.white,
                                size: 11,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              m.$4,
                              style: AuroraPalette.bodyStyle(
                                color: Colors.white.withOpacity(active ? 0.9 : 0.62),
                                size: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Switch Globale: "🌱 Da Zero" vs "🎓 Tecnica"
              InkWell(
                onTap: () => setState(() => _isBeginnerMode = !_isBeginnerMode),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isBeginnerMode
                        ? AuroraPalette.mint.withOpacity(0.16)
                        : const Color(0xFFC084FC).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isBeginnerMode ? AuroraPalette.mint : const Color(0xFFC084FC),
                      width: 1.3,
                    ),
                  ),
                  child: Text(
                    _isBeginnerMode ? '🌱 LIVELLO: DA ZERO' : '🎓 LIVELLO: TECNICO',
                    style: AuroraPalette.headingStyle(
                      color: _isBeginnerMode ? AuroraPalette.mint : const Color(0xFFC084FC),
                      size: 10.5,
                    ),
                  ),
                ),
              ),

              // Badge Prestazioni & FPS Live (Cliccabile per cambiare LOD)
              _buildPerformanceBadge(),

              // Selettore Zoom Testo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.format_size_rounded, size: 14, color: AuroraPalette.cyan),
                    const SizedBox(width: 4),
                    _zoomBtn('100%', 1.0),
                    _zoomBtn('116%', 1.16),
                    _zoomBtn('130%', 1.30),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadge() {
    return ValueListenableBuilder<int>(
      valueListenable: PerformanceMonitor.instance.fps,
      builder: (context, fpsValue, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: PerformanceMonitor.instance.highQuality,
          builder: (context, isHighQ, _) {
            final Color c = isHighQ ? AuroraPalette.cyan : AuroraPalette.amber;
            return Tooltip(
              message: 'Motore HyperFluid GPU attivo. Clicca per alternare Ultra / Eco su dispositivi lenti.',
              child: InkWell(
                onTap: () => PerformanceMonitor.instance.toggleQualityMode(),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: c.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed_rounded, size: 14, color: c),
                      const SizedBox(width: 5),
                      Text(
                        '$fpsValue FPS · ${isHighQ ? "ULTRA" : "ECO"}',
                        style: AuroraPalette.monoStyle(size: 10, color: c),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _zoomBtn(String label, double scale) {
    final bool active = (_textScale - scale).abs() < 0.02;
    return InkWell(
      onTap: () => setState(() => _textScale = scale),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AuroraPalette.cyan.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AuroraPalette.monoStyle(
            color: active ? AuroraPalette.cyan : Colors.white70,
            size: 9.5,
            weight: active ? FontWeight.bold : FontWeight.normal,
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
    entropy = -candidates.fold(0.0, (sum, c) {
      if (c.probability <= 0) return sum;
      return sum + c.probability * (log(c.probability) / log(2));
    });
  }
}

class NeuralWorkspace extends StatefulWidget {
  final VoidCallback? onOpenApiLab;
  final bool isBeginnerMode;
  const NeuralWorkspace({
    super.key,
    this.onOpenApiLab,
    this.isBeginnerMode = true,
  });
  @override
  State<NeuralWorkspace> createState() => _NeuralWorkspaceState();
}

class _NeuralWorkspaceState extends State<NeuralWorkspace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final NeuralSimulationEngine _engine;

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _tokens = [];
  bool _isReceiving = false;
  late final GenerativeModel _model;
  bool _hasApiKey = false;

  bool _slowMotionMode = false;
  double _creativityTemp = 0.6;

  final List<(String, String, String)> _starterPrompts = [
    (
      '✨ 1. Come sceglie le parole?',
      'Spiega in modo semplice come un\'AI sceglie una parola dopo l\'altra.',
      'Un modello di intelligenza artificiale non pensa come un umano, ma funziona come un super completamento automatico: legge le parole scritte finora, calcola nel suo cervello digitale le probabilità di tutte le parole possibili e sceglie il mattoncino (chiamato Token) con la percentuale più adatta per continuare la frase!'
    ),
    (
      '🧠 2. Cos\'è una Rete Neurale?',
      'Cos\'è una rete neurale artificiale spiegata a chi parte da zero?',
      'Una rete neurale è una grande costellazione di nodi matematici chiamati neuroni collegati tra loro da fili luminosi detti sinapsi. Quando fai una domanda, gli impulsi di luce attraversano i collegamenti più forti accendendo i concetti correlati proprio come vedi brillare nel globo 3D qui a sinistra!'
    ),
    (
      '🧩 3. Cosa sono i Token?',
      'Cosa significa la parola Token nell\'intelligenza artificiale?',
      'Per leggere e scrivere velocemente, l\'intelligenza artificiale spezza ogni frase in piccoli mattoncini chiamati Token: un Token può essere una parola intera oppure una sillaba. Ogni volta che vedi apparire un nuovo blocchetto illuminato qui sotto, la rete ha appena completato un intero ciclo di calcolo!'
    ),
  ];

  List<TokenCandidate> _candidates = [];
  String _decodingToken = "";

  String _currentSemanticToken = "";
  List<SemanticWord> _semanticNeighbors = [];

  final LiveMetrics _metrics = LiveMetrics();
  String _networkState = "PRONTA · INTERATTIVA";

  @override
  void initState() {
    super.initState();
    _engine = NeuralSimulationEngine(count: 148);
    _initGemini();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    // Il listener aggiorna SOLO il NeuralSimulationEngine (ChangeNotifier) senza chiamare setState()!
    _controller.addListener(_engine.tick);
  }

  void _initGemini() {
    String key = const String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) {
      key = dotenv.env['GEMINI_API_KEY'] ?? '';
    }
    _hasApiKey = key.isNotEmpty;
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: key);
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
          g.gain.setValueAtTime(0.035, ctx.currentTime);
          g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.07);
          o.start(ctx.currentTime); o.stop(ctx.currentTime + 0.07);
        })()'''
      ]);
    } catch (_) {}
  }

  void _updateCandidates(String token) {
    final rnd = Random();
    double baseWin = (0.88 - (_creativityTemp * 0.30)).clamp(0.42, 0.92);
    double winP = (baseWin + (rnd.nextDouble() - 0.5) * 0.08).clamp(0.40, 0.94);
    double rem = 1.0 - winP;
    List<String> alts = [_mutateSuffix(token, rnd), _scramble(token, rnd)];
    List<double> altP = [rem * 0.58, rem * 0.42];
    final cands = [
      TokenCandidate(word: token, probability: winP, isSelected: true),
      ...alts.asMap().entries.map(
            (e) => TokenCandidate(word: e.value, probability: altP[e.key], isSelected: false),
          ),
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
    const g = '01◊◈▓▒░><~';
    final r = Random();
    final stepMs = _slowMotionMode ? 105 : 32;
    for (int i = 0; i < 3; i++) {
      if (!mounted) break;
      setState(() => _decodingToken = List.generate(token.length, (_) => g[r.nextInt(g.length)]).join());
      await Future.delayed(Duration(milliseconds: stepMs));
    }
    if (mounted) setState(() => _decodingToken = "");
  }

  Future<void> _emitWordsDidactically(String fullText) async {
    final words = RegExp(r'(\S+|\n)').allMatches(fullText);
    for (final m in words) {
      if (!mounted) break;
      final w = m.group(0)!;
      _updateCandidates(w);
      _playTickSound();
      await _decodeEffect(w);

      final neighbors = generateSemanticNeighbors(w);
      final List<String> currentConcepts = [];
      if (w.trim().isNotEmpty && w.trim().length > 1) {
        currentConcepts.add(w.trim());
        currentConcepts.addAll(neighbors.map((e) => e.word));
      }

      _engine.exciteBurst(1, concepts: currentConcepts);

      setState(() {
        _tokens.add(w == '\n' ? '\n' : w);
        _currentSemanticToken = w;
        _semanticNeighbors = neighbors;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendPrompt({String? customPrompt, String? fallbackAnswer}) async {
    final text = (customPrompt ?? _textCtrl.text).trim();
    if (text.isEmpty || _isReceiving) return;
    _textCtrl.clear();
    _metrics.onStreamStart();
    setState(() {
      _tokens.clear();
      _candidates = [];
      _decodingToken = "";
      _tokens.add(">> Domanda: \"$text\"\n");
      _isReceiving = true;
      _networkState = "ELABORAZIONE SINAPTICA ATTIVA";
    });

    try {
      if (_hasApiKey) {
        final stream = _model.generateContentStream([Content.text(text)]);
        await for (final chunk in stream) {
          if (!mounted) break;
          if (chunk.text == null || chunk.text!.isEmpty) continue;
          await _emitWordsDidactically(chunk.text!);
        }
      } else {
        final simulated = fallbackAnswer ??
            'Ecco una dimostrazione didattica per la tua domanda ("$text"): '
                'la rete neurale legge ogni parola, accende i neuroni collegati nel globo 3D a sinistra, '
                'mette in gara le possibili parole successive nella barra delle probabilità qui sotto '
                'e compone la frase finale un mattoncino (Token) dopo l\'altro!';
        await _emitWordsDidactically(simulated);
      }
    } catch (_) {
      final simulated = fallbackAnswer ??
          'Simulazione didattica attiva: la rete neurale analizza "$text", attiva i nodi semantici nel globo 3D '
              'e seleziona parola per parola il Token con la probabilità più adatta in base al livello di fantasia scelto!';
      await _emitWordsDidactically(simulated);
    } finally {
      if (mounted) {
        setState(() {
          _tokens.add("\n>> Generazione completata · Clicca o trascina la sfera 3D per esplorare i neuroni.");
          _isReceiving = false;
          _networkState = "PRONTA · INTERATTIVA";
          _decodingToken = "";
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_engine.tick);
    _controller.dispose();
    _engine.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final bool wide = constraints.maxWidth > 920;
      final panels = [_buildGlobePanel(wide), _divider(wide), _buildAnalysisPanel(wide)];
      return wide
          ? Row(children: panels)
          : SingleChildScrollView(child: Column(children: panels));
    });
  }

  // ─────────────── PANNELLO SINISTRO (② IL CERVELLO 3D INTERATTIVO) ───────────────
  Widget _buildGlobePanel(bool wide) {
    Widget globe = LayoutBuilder(
      builder: (ctx, box) {
        return MouseRegion(
          cursor: SystemMouseCursors.grab,
          onHover: (e) {
            // Nessun setState()! Aggiorna solo il motore 3D ad alta velocità.
            _engine.onPointerHover(
              Offset(
                e.localPosition.dx - box.maxWidth * 0.5,
                e.localPosition.dy - box.maxHeight * 0.5,
              ),
            );
          },
          onExit: (_) => _engine.onPointerExit(),
          child: GestureDetector(
            onPanUpdate: (d) => _engine.onPanUpdate(d.delta),
            onPanEnd: (_) => _engine.onPanEnd(),
            child: Container(
              height: wide ? double.infinity : 410,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: _isReceiving
                      ? [const Color(0xFF102347), const Color(0xFF070B18), AuroraPalette.bgDeep]
                      : [const Color(0xFF0C152C), const Color(0xFF060914), AuroraPalette.bgDeep],
                  radius: 1.15,
                ),
              ),
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: GlobePainter(
                        engine: _engine,
                        isActive: _isReceiving,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Transform.scale(
                      scale: wide ? 1.0 : 0.88,
                      alignment: Alignment.topLeft,
                      child: _buildLegendHUD(),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Center(child: _buildNetworkStatus()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return wide ? Expanded(flex: 10, child: globe) : globe;
  }

  Widget _divider(bool wide) => Container(
        width: wide ? 1.2 : double.infinity,
        height: wide ? double.infinity : 1.2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: wide ? Alignment.topCenter : Alignment.centerLeft,
            end: wide ? Alignment.bottomCenter : Alignment.centerRight,
            colors: [
              Colors.transparent,
              AuroraPalette.cyan.withOpacity(0.32),
              AuroraPalette.violet.withOpacity(0.32),
              Colors.transparent,
            ],
          ),
        ),
      );

  // ─────────────── PANNELLO DESTRO (GUIDATO ① -> ③ -> ④) ───────────────
  Widget _buildAnalysisPanel(bool wide) {
    Widget matrixCompass = wide
        ? Row(children: [
            Expanded(flex: 3, child: _buildProbabilityMatrix()),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SemanticCompass(
                currentToken: _currentSemanticToken,
                neighbors: _semanticNeighbors,
                isActive: _isReceiving,
                isBeginnerMode: widget.isBeginnerMode,
              ),
            ),
          ])
        : Column(children: [
            SizedBox(height: 235, child: _buildProbabilityMatrix()),
            const SizedBox(height: 12),
            SizedBox(
              height: 235,
              child: SemanticCompass(
                currentToken: _currentSemanticToken,
                neighbors: _semanticNeighbors,
                isActive: _isReceiving,
                isBeginnerMode: widget.isBeginnerMode,
              ),
            ),
          ]);

    Widget content = Container(
      padding: EdgeInsets.all(wide ? 20.0 : 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBeginnerMode
                          ? 'LAB 01 // COME FA UN\'AI A SCRIVERE UNA RISPOSTA?'
                          : 'LAB 01 // SPAZIO LATENTE 3D, SOFTMAX & EMBEDDING',
                      style: AuroraPalette.headingStyle(
                        size: 17.5,
                        color: AuroraPalette.cyan,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.isBeginnerMode
                          ? 'Segui i passi ① ➔ ② ➔ ③ ➔ ④: l\'AI calcola le probabilità e sceglie un mattoncino alla volta!'
                          : 'Decodifica autoregressiva in tempo reale con telemetria d\'entropia e proiezione semantica',
                      style: AuroraPalette.bodyStyle(
                        color: Colors.white.withOpacity(0.84),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onOpenApiLab != null)
                InkWell(
                  onTap: widget.onOpenApiLab,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AuroraPalette.mint.withOpacity(0.22),
                          AuroraPalette.emerald.withOpacity(0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AuroraPalette.mint.withOpacity(0.55)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16, color: AuroraPalette.mint),
                        const SizedBox(width: 6),
                        Text(
                          'Vai a Lab 02 (API) ➔',
                          style: AuroraPalette.headingStyle(
                            color: AuroraPalette.mint,
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),

          _buildBeginnerControlsCard(),
          const SizedBox(height: 11),

          _buildMetricsBar(wide),
          const SizedBox(height: 11),

          if (wide)
            Expanded(flex: 4, child: _buildTokenStream())
          else
            SizedBox(height: 260, child: _buildTokenStream()),

          const SizedBox(height: 11),

          if (wide)
            Expanded(flex: 3, child: matrixCompass)
          else
            matrixCompass,

          const SizedBox(height: 11),

          _buildInput(),
        ],
      ),
    );

    return wide ? Expanded(flex: 11, child: content) : content;
  }

  Widget _buildBeginnerControlsCard() {
    return AuroraGlassCard(
      accentColor: AuroraPalette.cyan,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '① PROVA SUBITO CON 1 CLICK:',
                style: AuroraPalette.headingStyle(
                  color: AuroraPalette.cyan,
                  size: 11,
                ),
              ),
              ..._starterPrompts.map((p) {
                return InkWell(
                  onTap: _isReceiving
                      ? null
                      : () => _sendPrompt(customPrompt: p.$2, fallbackAnswer: p.$3),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AuroraPalette.cyan.withOpacity(0.18),
                          AuroraPalette.electricBlue.withOpacity(0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AuroraPalette.cyan.withOpacity(0.45)),
                    ),
                    child: Text(
                      p.$1,
                      style: AuroraPalette.headingStyle(
                        color: Colors.white,
                        size: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: () => setState(() => _slowMotionMode = !_slowMotionMode),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _slowMotionMode
                        ? AuroraPalette.amber.withOpacity(0.22)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _slowMotionMode ? AuroraPalette.amber : Colors.white24,
                    ),
                  ),
                  child: Text(
                    _slowMotionMode
                        ? '🐢 RALLENTATORE PAROLA: ATTIVO (Ideale per osservare la gara!)'
                        : '⚡ VELOCITÀ FLUIDA (Clicca per Rallentare 🐢)',
                    style: AuroraPalette.headingStyle(
                      color: _slowMotionMode ? AuroraPalette.amber : Colors.white,
                      size: 10.5,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isBeginnerMode
                        ? '🎨 Fantasia AI (${_creativityTemp < 0.4 ? "Molto Precisa" : (_creativityTemp > 0.9 ? "Molto Creativa" : "Equilibrata")}):'
                        : 'Temperatura (${_creativityTemp.toStringAsFixed(1)}):',
                    style: AuroraPalette.headingStyle(
                      color: const Color(0xFFC4B5FD),
                      size: 11,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    height: 22,
                    child: Slider(
                      value: _creativityTemp,
                      min: 0.1,
                      max: 1.4,
                      divisions: 13,
                      activeColor: const Color(0xFFC4B5FD),
                      onChanged: (v) => setState(() => _creativityTemp = v),
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

  Widget _buildMetricsBar(bool wide) {
    final String latency = _metrics.firstTokenMs != null ? '${_metrics.firstTokenMs}ms' : '—';
    final l1 = widget.isBeginnerMode ? 'VELOCITÀ (Parole/s)' : 'TOKEN/s';
    final l2 = widget.isBeginnerMode ? 'PEZZI SCRITTI (Token)' : 'TOTALE TOKEN';
    final l3 = widget.isBeginnerMode ? 'INDECISIONE AI' : 'ENTROPIA SHANNON';
    final l4 = widget.isBeginnerMode ? 'TEMPO 1ª PAROLA' : 'LATENZA TTFT';

    return AuroraGlassCard(
      accentColor: Colors.white24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      borderRadius: 12,
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metricCell(l1, _metrics.tokensPerSecond.toStringAsFixed(1), AuroraPalette.cyan),
                _metricCell(l2, '${_metrics.totalTokens}', Colors.white),
                _metricCell(l3, _metrics.entropy.toStringAsFixed(2), const Color(0xFFC4B5FD)),
                _metricCell(l4, latency, AuroraPalette.coral),
              ],
            )
          : Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _metricCell(l1, _metrics.tokensPerSecond.toStringAsFixed(1), AuroraPalette.cyan),
                _metricCell(l2, '${_metrics.totalTokens}', Colors.white),
                _metricCell(l3, _metrics.entropy.toStringAsFixed(2), const Color(0xFFC4B5FD)),
                _metricCell(l4, latency, AuroraPalette.coral),
              ],
            ),
    );
  }

  Widget _metricCell(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AuroraPalette.bodyStyle(
              color: Colors.white70,
              size: 10,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AuroraPalette.monoStyle(color: color, size: 15, weight: FontWeight.bold),
          ),
        ],
      );

  Widget _buildTokenStream() {
    return AuroraGlassCard(
      accentColor: AuroraPalette.cyan,
      highlightBorder: _isReceiving,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AuroraPalette.cyan.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.auto_fix_high_rounded, size: 15, color: AuroraPalette.cyan),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isBeginnerMode
                      ? '④ LA FRASE SI COMPONE UN MATTONCINO ("TOKEN") ALLA VOLTA'
                      : '④ LIVE TOKEN STREAM (AUTOREGRESSIVE DECODING)',
                  style: AuroraPalette.headingStyle(
                    color: AuroraPalette.cyan,
                    size: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: _tokens.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Text(
                          '👆 Clicca uno dei 3 pulsanti di esempio qui sopra (oppure scrivi sotto) per vedere l\'AI costruire la frase!',
                          style: AuroraPalette.bodyStyle(
                            color: Colors.white70,
                            size: 13.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int i = 0; i < _tokens.length; i++)
                          _buildFastTokenItem(_tokens[i], isLatest: i == _tokens.length - 1 && _isReceiving),
                        if (_decodingToken.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AuroraPalette.amber.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AuroraPalette.amber.withOpacity(0.75)),
                            ),
                            child: Text(
                              _decodingToken,
                              style: AuroraPalette.monoStyle(
                                color: AuroraPalette.amber,
                                size: 14.5,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rendering leggero dei token: 0 AnimationController istanziati per parola = fluidità assoluta anche con centinaia di token!
  Widget _buildFastTokenItem(String t, {required bool isLatest}) {
    if (t == '\n') return const SizedBox(width: double.infinity, height: 6);
    if (t.startsWith('>>') || t.startsWith('[')) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            t,
            style: AuroraPalette.monoStyle(
              color: AuroraPalette.cyan.withOpacity(0.85),
              size: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLatest
            ? AuroraPalette.cyan.withOpacity(0.22)
            : Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLatest
              ? AuroraPalette.cyan
              : Colors.white.withOpacity(0.08),
          width: isLatest ? 1.3 : 1.0,
        ),
      ),
      child: Text(
        t,
        style: AuroraPalette.bodyStyle(
          color: isLatest ? AuroraPalette.cyan : Colors.white.withOpacity(0.96),
          size: 15.5,
          weight: isLatest ? FontWeight.w800 : FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildProbabilityMatrix() {
    return AuroraGlassCard(
      accentColor: AuroraPalette.violet,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AuroraPalette.violet.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.equalizer_rounded, size: 15, color: Color(0xFFC4B5FD)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isBeginnerMode
                      ? '③a. GARA TRA LE PROSSIME PAROLE'
                      : '③a. DISTRIBUZIONE SOFTMAX',
                  style: AuroraPalette.headingStyle(
                    color: const Color(0xFFC4B5FD),
                    size: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (_isReceiving ? AuroraPalette.mint : Colors.white24).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isReceiving ? '● IN GARA' : '○ PRONTA',
                  style: AuroraPalette.monoStyle(
                    color: _isReceiving ? AuroraPalette.mint : Colors.white60,
                    size: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.isBeginnerMode
                ? 'Come i suggerimenti dello smartphone: vince la parola azzurra (▶)!'
                : 'Probabilità condizionata P(w_t | w_<t) sui token candidati:',
            style: AuroraPalette.bodyStyle(color: Colors.white70, size: 10.5),
          ),
          const SizedBox(height: 10),
          if (_candidates.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Avvia una domanda per vedere le 3 parole finaliste sfidarsi a colpi di %!',
                  style: AuroraPalette.bodyStyle(color: Colors.white54, size: 11.5),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._candidates.map((c) => _candidateBar(c)),
        ],
      ),
    );
  }

  Widget _candidateBar(TokenCandidate c) {
    final Color col = c.isSelected ? AuroraPalette.cyan : const Color(0xFFC4B5FD);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              '${c.isSelected ? '▶ ' : '  '}${c.word}',
              style: AuroraPalette.monoStyle(
                color: col,
                size: 12,
                weight: c.isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: c.probability.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(
                  c.isSelected ? AuroraPalette.cyan : AuroraPalette.violet.withOpacity(0.65),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Text(
              '${(c.probability * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: AuroraPalette.monoStyle(color: col, size: 11.5, weight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendHUD() {
    return AuroraGlassCard(
      accentColor: AuroraPalette.cyan,
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.threed_rotation_rounded, size: 16, color: AuroraPalette.cyan),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.isBeginnerMode ? '② CERVELLO 3D INTERATTIVO' : '② SPAZIO LATENTE 3D',
                    style: AuroraPalette.headingStyle(
                      color: AuroraPalette.cyan,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _legendRow(
              AuroraPalette.cyan,
              'circle',
              widget.isBeginnerMode ? 'IDEA APPENA ACCESA' : 'NODO ATTIVO',
              widget.isBeginnerMode ? 'Parola che l\'AI sta calcolando ora' : 'Attivazione immediata nello strato',
            ),
            _legendRow(
              const Color(0xFFF43F5E),
              'circle',
              widget.isBeginnerMode ? 'TEMA RICORRENTE' : 'ATTENTION HOTSPOT',
              widget.isBeginnerMode ? 'Concetto centrale nel discorso' : 'Peso storico Self-Attention elevato',
            ),
            _legendRow(
              const Color(0xFF3B82F6),
              'circle',
              widget.isBeginnerMode ? 'MEMORIA A RIPOSO' : 'NODO LATENTE',
              widget.isBeginnerMode ? 'Concetti pronti ad accendersi' : 'Parametri non eccitati dal token',
            ),
            _legendRow(
              AuroraPalette.cyan,
              'line',
              widget.isBeginnerMode ? 'IMPULSO TRA CONCETTI' : 'SINAPSI & IMPULSI',
              widget.isBeginnerMode ? 'Fili luminosi tra parole collegate' : 'Propagazione pesi sinaptici W_ij',
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String shape, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: shape == 'circle'
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)],
                      ),
                    )
                  : Container(
                      width: 16,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AuroraPalette.headingStyle(color: color, size: 11),
                ),
                Text(
                  desc,
                  style: AuroraPalette.bodyStyle(
                    color: Colors.white.withOpacity(0.82),
                    size: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatus() {
    final Color c = _isReceiving ? AuroraPalette.cyan : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
      decoration: BoxDecoration(
        color: const Color(0xFF070B19).withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'RETE 3D: $_networkState · Trascina per ruotare in 3D o muovi il mouse',
              style: AuroraPalette.monoStyle(color: c, size: 10, weight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: TextField(
              focusNode: _focusNode,
              controller: _textCtrl,
              style: AuroraPalette.bodyStyle(color: Colors.white, size: 14),
              decoration: InputDecoration(
                hintText: 'Oppure scrivi qui qualsiasi domanda e premi Invio...',
                hintStyle: AuroraPalette.bodyStyle(color: Colors.white54, size: 13.5),
                filled: true,
                fillColor: const Color(0xFF0A1024).withOpacity(0.88),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AuroraPalette.cyan.withOpacity(0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AuroraPalette.cyan, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _sendPrompt(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _isReceiving ? null : () => _sendPrompt(),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: _isReceiving
                  ? null
                  : LinearGradient(
                      colors: [
                        AuroraPalette.cyan.withOpacity(0.28),
                        AuroraPalette.electricBlue.withOpacity(0.22),
                      ],
                    ),
              color: _isReceiving ? Colors.white10 : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isReceiving ? Colors.white12 : AuroraPalette.cyan.withOpacity(0.65),
              ),
            ),
            child: Icon(
              Icons.send_rounded,
              color: _isReceiving ? Colors.white24 : AuroraPalette.cyan,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
