// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'core_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LAB 05 // COSTRUISCI UN'APP INTERA ("IL GIOCO DELL'ARCHITETTURA")
// Gioco didattico interattivo Drag & Drop (e 1-Click) per persone non tecniche:
// - Trascina sulla lavagna: Frontend, FastAPI, Backend, Database, AI & Docker
// - Pop-up illustrati che spiegano cos'è ogni pezzo con la metafora del Ristorante
// - Validazione visiva VERDE (collegamento perfetto) o ROSSO (pezzo mancante o
//   collegato nel posto sbagliato, es. Frontend collegato diretto al Database!)
// - Simulatore live "▶ PROVA LA TUA APP!" che fa viaggiare un vero messaggio
// ─────────────────────────────────────────────────────────────────────────────

enum AppPieceType {
  frontend, // 1. Lo Schermo (Sala & Menù) — Flutter / React
  fastapi,  // 2. Il Cameriere Veloce — FastAPI / API REST
  backend,  // 3. La Cucina & Regole — Python Backend / Sicurezza
  database, // 4. L'Archivio Memoria — PostgreSQL / Vector DB
  aiDocker, // 5. Lo Chef Intelligente in Valigia — Gemini AI + Docker
}

class AppComponentSpec {
  final AppPieceType type;
  final int correctSlotIndex; // 0..4
  final String emoji;
  final String shortTitle;
  final String roleLabel;
  final String techStack;
  final String simpleWhatIsIt;
  final String restaurantAnalogy;
  final String whatIfMissing;
  final String wrongPlacementHint;
  final Color color;

  const AppComponentSpec({
    required this.type,
    required this.correctSlotIndex,
    required this.emoji,
    required this.shortTitle,
    required this.roleLabel,
    required this.techStack,
    required this.simpleWhatIsIt,
    required this.restaurantAnalogy,
    required this.whatIfMissing,
    required this.wrongPlacementHint,
    required this.color,
  });
}

class AppBuilderLabWorkspace extends StatefulWidget {
  final bool isBeginnerMode;

  const AppBuilderLabWorkspace({
    super.key,
    this.isBeginnerMode = true,
  });

  @override
  State<AppBuilderLabWorkspace> createState() => _AppBuilderLabWorkspaceState();
}

class _AppBuilderLabWorkspaceState extends State<AppBuilderLabWorkspace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  static const Color _greenOk = Color(0xFF10B981);
  static const Color _mintOk = Color(0xFF34D399);
  static const Color _redErr = Color(0xFFF43F5E);
  static const Color _amberWarn = Color(0xFFFBBF24);
  static const Color _cyan = Color(0xFF00F0FF);

  static const List<AppComponentSpec> _allSpecs = [
    AppComponentSpec(
      type: AppPieceType.frontend,
      correctSlotIndex: 0,
      emoji: '📱',
      shortTitle: 'FRONTEND',
      roleLabel: 'Lo Schermo (Ciò che vedi)',
      techStack: 'Flutter · React · HTML/CSS',
      simpleWhatIsIt:
          'Il Frontend è la "faccia" dell\'applicazione: i bottoni che tocchi, i colori, le animazioni e le caselle in cui scrivi sul telefono o sul computer.',
      restaurantAnalogy:
          '🍽️ Nel ristorante è la SALA CON IL MENÙ: accoglie il cliente ed è bella da vedere, ma da sola non sa cucinare i piatti!',
      whatIfMissing:
          '💥 Se manca il Frontend: lo schermo è completamente nero! L\'utente non ha nessun bottone da premere per usare l\'app.',
      wrongPlacementHint:
          'Il Frontend deve stare sempre al POSTO ① (all\'inizio), perché è il primo punto di contatto con l\'utente umano!',
      color: Color(0xFF38BDF8),
    ),
    AppComponentSpec(
      type: AppPieceType.fastapi,
      correctSlotIndex: 1,
      emoji: '⚡',
      shortTitle: 'FASTAPI (API)',
      roleLabel: 'Il Cameriere Veloce',
      techStack: 'FastAPI (Python) · REST JSON',
      simpleWhatIsIt:
          'FastAPI è il ponte ultra-rapido che raccoglie le richieste inviate dallo Schermo (Frontend), controlla che siano valide e le consegna al motore interno (Backend).',
      restaurantAnalogy:
          '🏃‍♂️ Nel ristorante è il CAMERIERE VELOCE: prende la comanda dal tavolo del cliente e corre a portarla allo sportello della cucina!',
      whatIfMissing:
          '💥 Se manca FastAPI: premi i bottoni sullo schermo ma il messaggio cade nel vuoto! Lo schermo e il server non riescono a parlarsi.',
      wrongPlacementHint:
          'FastAPI va messo al POSTO ②, proprio sul ponte di collegamento tra lo Schermo (①) e la Cucina del Backend (③)!',
      color: Color(0xFF34D399),
    ),
    AppComponentSpec(
      type: AppPieceType.backend,
      correctSlotIndex: 2,
      emoji: '⚙️',
      shortTitle: 'BACKEND',
      roleLabel: 'La Cucina & Le Regole',
      techStack: 'Python · Logica · Sicurezza',
      simpleWhatIsIt:
          'Il Backend è il cervello organizzativo nascosto dietro le quinte: controlla chi sei (password e sicurezza), fa i calcoli e coordina l\'Archivio Dati e l\'Intelligenza Artificiale.',
      restaurantAnalogy:
          '👨‍🍳 Nel ristorante è la CUCINA CON IL CAPO-CUOCO: riceve gli ordini dal cameriere, prende gli ingredienti dalla dispensa e prepara il piatto.',
      whatIfMissing:
          '💥 Se manca il Backend: nessuno controlla i permessi di sicurezza e nessuno coordina il Database o l\'AI!',
      wrongPlacementHint:
          'Il Backend deve stare al centro, al POSTO ③: riceve gli ordini da FastAPI (②) e comanda in sicurezza il Database (④) e l\'AI (⑤).',
      color: Color(0xFFA78BFA),
    ),
    AppComponentSpec(
      type: AppPieceType.database,
      correctSlotIndex: 3,
      emoji: '🗄️',
      shortTitle: 'DATABASE',
      roleLabel: 'La Memoria & Archivio',
      techStack: 'PostgreSQL · Vector DB · SQL',
      simpleWhatIsIt:
          'Il Database è la cassaforte della memoria: salva in modo permanente gli account degli utenti, i messaggi passati, i documenti e le impostazioni anche quando spegni tutto.',
      restaurantAnalogy:
          '🥫 Nel ristorante è la DISPENSA + IL REGISTRO PRENOTAZIONI: conserva tutti gli ingredienti e ricorda i gusti dei clienti abituali.',
      whatIfMissing:
          '💥 Se manca il Database: l\'app soffre di amnesia totale! Appena chiudi o ricarichi la pagina, perde tutti i dati e non ti riconosce più.',
      wrongPlacementHint:
          '⚠️ MAI mettere il Database al posto ① o ②! Il Database va al POSTO ④, protetto dietro il Backend (③), altrimenti chiunque da fuori potrebbe rubare i dati!',
      color: Color(0xFFFBBF24),
    ),
    AppComponentSpec(
      type: AppPieceType.aiDocker,
      correctSlotIndex: 4,
      emoji: '🧠',
      shortTitle: 'AI + DOCKER',
      roleLabel: 'Lo Chef Geniale in Valigia',
      techStack: 'Gemini AI · Container Docker',
      simpleWhatIsIt:
          'Il Motore AI genera risposte intelligenti su misura, mentre la "Valigia Docker" tiene tutta l\'applicazione impacchettata e pronta a funzionare su qualsiasi computer del Cloud!',
      restaurantAnalogy:
          '🤖🐳 È lo CHEF STELLATO per i piatti speciali + il CONTAINER TERMICO che permette al ristorante di funzionare identico in qualsiasi città del mondo.',
      whatIfMissing:
          '💥 Se manca AI + Docker: l\'app non sa rispondere alle domande intelligenti e rischia di bloccarsi quando la sposti sul server Internet!',
      wrongPlacementHint:
          'AI + Docker va al POSTO ⑤ (Specialista & Cloud), collegato direttamente al Backend (③) che gli invia le domande pronte.',
      color: Color(0xFFF472B6),
    ),
  ];

  // I 5 slot della lavagna architettonica (null = slot vuoto)
  final List<AppPieceType?> _boardSlots = [
    AppPieceType.frontend, // Pre-posizioniamo solo il 1° pezzo per invitare subito a giocare!
    null,
    null,
    null,
    null,
  ];

  bool _autoShowPopupOnDrop = true;
  bool _isTestingApp = false;
  int _testFlowStep = -1; // -1 = fermo, 0..4 = slot raggiunto dal pacchetto di test
  bool _testStoppedOnError = false;
  String _liveDiagnosticBanner =
      '🎯 MISSIONE: Trascina i pezzi mancanti nei riquadri giusti (②, ③, ④, ⑤) per far diventare tutta la rete VERDE!';

  static const List<(String, String, String)> _slotDescriptions = [
    (
      'POSTO ① · LATO UTENTE',
      'Chi mostra i bottoni sullo schermo?',
      'Qui serve la faccia visibile dell\'App (Frontend)',
    ),
    (
      'POSTO ② · IL PONTE DI COMUNICAZIONE',
      'Chi porta il messaggio dallo schermo al server?',
      'Qui serve il Cameriere Veloce (FastAPI)',
    ),
    (
      'POSTO ③ · IL CUORE DEL SERVER',
      'Chi applica le regole e controlla la sicurezza?',
      'Qui serve la Cucina centrale (Backend)',
    ),
    (
      'POSTO ④ · LA CASSAFORTE DEI DATI',
      'Chi conserva i dati senza dimenticarli?',
      'Qui serve l\'Archivio protetto (Database)',
    ),
    (
      'POSTO ⑤ · INTELLIGENZA & CLOUD',
      'Chi ragiona e impacchetta tutto per il Cloud?',
      'Qui servono Motore AI + Valigia Docker',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  AppComponentSpec _specFor(AppPieceType type) =>
      _allSpecs.firstWhere((s) => s.type == type);

  bool _isSlotCorrect(int slotIdx) {
    final piece = _boardSlots[slotIdx];
    if (piece == null) return false;
    return _specFor(piece).correctSlotIndex == slotIdx;
  }

  int get _correctCount {
    int c = 0;
    for (int i = 0; i < 5; i++) {
      if (_isSlotCorrect(i)) c++;
    }
    return c;
  }

  bool get _hasWrongPlacedPiece {
    for (int i = 0; i < 5; i++) {
      if (_boardSlots[i] != null && !_isSlotCorrect(i)) return true;
    }
    return false;
  }

  void _placePieceInSlot(AppPieceType piece, int targetSlot, {bool showPopup = true}) {
    setState(() {
      _testFlowStep = -1;
      _testStoppedOnError = false;

      // Se il pezzo era già in un altro slot, lo rimuoviamo da lì
      for (int i = 0; i < _boardSlots.length; i++) {
        if (_boardSlots[i] == piece) {
          _boardSlots[i] = null;
        }
      }
      _boardSlots[targetSlot] = piece;
      _updateDiagnosticMessage(lastPlaced: piece, targetSlot: targetSlot);
    });

    if (showPopup && _autoShowPopupOnDrop && mounted) {
      _showComponentExplanationDialog(_specFor(piece), placedInSlot: targetSlot);
    }
  }

  void _removePieceFromSlot(int slotIdx) {
    setState(() {
      _boardSlots[slotIdx] = null;
      _testFlowStep = -1;
      _testStoppedOnError = false;
      _updateDiagnosticMessage();
    });
  }

  /// Inserisce il pezzo nel primo slot vuoto (o nel suo slot corretto se l'utente clicca "Posiziona")
  void _quickPlacePiece(AppPieceType piece) {
    int emptyIdx = _boardSlots.indexOf(null);
    if (emptyIdx == -1) {
      emptyIdx = _specFor(piece).correctSlotIndex;
    }
    _placePieceInSlot(piece, emptyIdx, showPopup: true);
  }

  void _updateDiagnosticMessage({AppPieceType? lastPlaced, int? targetSlot}) {
    if (lastPlaced != null && targetSlot != null) {
      final spec = _specFor(lastPlaced);
      if (spec.correctSlotIndex != targetSlot) {
        _liveDiagnosticBanner =
            '🔴 ATTENZIONE AL POSTO ${targetSlot + 1}: Hai messo ${spec.emoji} ${spec.shortTitle} nel posto sbagliato! ${spec.wrongPlacementHint}';
        return;
      }
    }

    // Controlla se ci sono altri pezzi nel posto sbagliato
    for (int i = 0; i < 5; i++) {
      final p = _boardSlots[i];
      if (p != null && !_isSlotCorrect(i)) {
        final spec = _specFor(p);
        _liveDiagnosticBanner =
            '🔴 COLLEGAMENTO ERRATO AL POSTO ${i + 1}: ${spec.emoji} ${spec.shortTitle} non può stare qui! ${spec.wrongPlacementHint}';
        return;
      }
    }

    // Controlla se mancano pezzi
    for (int i = 0; i < 5; i++) {
      if (_boardSlots[i] == null) {
        final needed = _allSpecs[i];
        _liveDiagnosticBanner =
            '🟡 PEZZO MANCANTE AL POSTO ${i + 1}: Manca ${needed.emoji} ${needed.shortTitle} (${needed.roleLabel}). ${needed.whatIfMissing}';
        return;
      }
    }

    _liveDiagnosticBanner =
        '🟢 ARCHITETTURA PERFETTA AL 100%! Tutti e 5 i pezzi sono collegati nell\'ordine giusto. Clicca "▶ PROVA LA TUA APP!" per vederla in azione!';
  }

  Future<void> _runInteractiveAppTest() async {
    if (_isTestingApp) return;
    setState(() {
      _isTestingApp = true;
      _testFlowStep = -1;
      _testStoppedOnError = false;
    });

    for (int i = 0; i < 5; i++) {
      if (!mounted) return;
      setState(() => _testFlowStep = i);
      await Future.delayed(const Duration(milliseconds: 650));

      final piece = _boardSlots[i];
      if (piece == null) {
        final missingSpec = _allSpecs[i];
        setState(() {
          _testStoppedOnError = true;
          _isTestingApp = false;
          _liveDiagnosticBanner =
              '💥 TEST FALLITO AL POSTO ${i + 1}: Il messaggio si è bloccato perché manca ${missingSpec.emoji} ${missingSpec.shortTitle}! ${missingSpec.whatIfMissing}';
        });
        return;
      }

      if (!_isSlotCorrect(i)) {
        final wrongSpec = _specFor(piece);
        final expectedSpec = _allSpecs[i];
        setState(() {
          _testStoppedOnError = true;
          _isTestingApp = false;
          _liveDiagnosticBanner =
              '💥 CORTOCIRCUITO AL POSTO ${i + 1}: Il messaggio cercava ${expectedSpec.emoji} ${expectedSpec.shortTitle}, ma ha trovato ${wrongSpec.emoji} ${wrongSpec.shortTitle}! ${wrongSpec.wrongPlacementHint}';
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isTestingApp = false;
        _liveDiagnosticBanner =
            '🏆 TEST SUPERATO AL 100%! L\'utente ha toccato il Frontend (①) ➔ FastAPI (②) ha portato l\'ordine ➔ il Backend (③) ha salvato nel Database (④) e interrogato l\'AI in Docker (⑤)!';
      });
    }
  }

  void _resetBoard() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        _boardSlots[i] = null;
      }
      _testFlowStep = -1;
      _testStoppedOnError = false;
      _liveDiagnosticBanner =
          '🧹 Lavagna svuotata! Trascina i 5 mattoncini dalla cassetta degli attrezzi ai posti ① ➔ ⑤.';
    });
  }

  void _createWrongExampleForLearning() {
    setState(() {
      // Esempio classico di errore: Frontend collegato direttamente al Database senza FastAPI/Backend!
      _boardSlots[0] = AppPieceType.frontend;
      _boardSlots[1] = AppPieceType.database; // ERRORE ROSSO!
      _boardSlots[2] = null;
      _boardSlots[3] = AppPieceType.backend;  // INVERTITO!
      _boardSlots[4] = null;
      _testFlowStep = -1;
      _testStoppedOnError = false;
      _updateDiagnosticMessage(lastPlaced: AppPieceType.database, targetSlot: 1);
    });
  }

  void _autoSolveBoard() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        _boardSlots[i] = _allSpecs[i].type;
      }
      _testFlowStep = -1;
      _testStoppedOnError = false;
      _updateDiagnosticMessage();
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // POP-UP DIDATTICO ILLUSTRATO ("COS'È QUESTO PEZZO?")
  // ───────────────────────────────────────────────────────────────────────────
  void _showComponentExplanationDialog(AppComponentSpec spec, {int? placedInSlot}) {
    final bool isCorrectSpot = placedInSlot == null || placedInSlot == spec.correctSlotIndex;
    final Color statusCol = isCorrectSpot ? _mintOk : _redErr;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111C3D), Color(0xFF090F24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusCol, width: 2.2),
                boxShadow: [
                  BoxShadow(color: statusCol.withOpacity(0.28), blurRadius: 28),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Esito Posizionamento (Verde o Rosso)
                    if (placedInSlot != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: statusCol.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusCol, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrectSpot ? Icons.check_circle_rounded : Icons.error_rounded,
                              color: statusCol,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isCorrectSpot
                                    ? '🟢 OTTIMO! Hai collegato ${spec.shortTitle} nel posto giusto (Posto ${placedInSlot + 1})!'
                                    : '🔴 POSTO SBAGLIATO! Hai messo ${spec.shortTitle} nel Posto ${placedInSlot + 1}, ma il suo posto corretto è il Posto ${spec.correctSlotIndex + 1}!',
                                style: AuroraPalette.headingStyle(size: 13.5, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Intestazione del Pezzo
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: spec.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: spec.color, width: 1.8),
                          ),
                          child: Center(
                            child: Text(spec.emoji, style: const TextStyle(fontSize: 30)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${spec.shortTitle} · ${spec.roleLabel}',
                                style: AuroraPalette.headingStyle(size: 19, color: spec.color),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Tecnologie famose: ${spec.techStack}',
                                  style: AuroraPalette.monoStyle(size: 11.5, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 1. Cos'è spiegato semplice
                    _popupSection(
                      title: '🌱 COS\'È IN PAROLE SEMPLICI?',
                      body: spec.simpleWhatIsIt,
                      color: _cyan,
                    ),
                    const SizedBox(height: 12),

                    // 2. La metafora del Ristorante
                    _popupSection(
                      title: '🍽️ LA METAFORA DEL RISTORANTE',
                      body: spec.restaurantAnalogy,
                      color: _mintOk,
                    ),
                    const SizedBox(height: 12),

                    // 3. Cosa succede se manca o è collegato male
                    _popupSection(
                      title: isCorrectSpot
                          ? '⚠️ COSA SUCCEDEREBBE SENZA QUESTO PEZZO?'
                          : '🔴 PERCHÉ NON PUÒ STARE IN QUESTO POSTO?',
                      body: isCorrectSpot ? spec.whatIfMissing : spec.wrongPlacementHint,
                      color: _redErr,
                    ),
                    const SizedBox(height: 18),

                    // Bottoni azione del Pop-up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isCorrectSpot)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _placePieceInSlot(
                                  spec.type,
                                  spec.correctSlotIndex,
                                  showPopup: false,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: _mintOk.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _mintOk, width: 1.5),
                                ),
                                child: Text(
                                  '✨ Spostalo subito al Posto giusto (${spec.correctSlotIndex + 1})!',
                                  style: AuroraPalette.headingStyle(size: 13, color: _mintOk),
                                ),
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                              color: spec.color.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: spec.color, width: 1.5),
                            ),
                            child: Text(
                              'HO CAPITO! ✓',
                              style: AuroraPalette.headingStyle(size: 13.5, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _popupSection({
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AuroraPalette.headingStyle(size: 12.5, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: AuroraPalette.bodyStyle(
              size: 14,
              color: Colors.white.withOpacity(0.95),
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD PRINCIPALE DEL LABORATORIO
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final bool wide = constraints.maxWidth > 1050;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 24 : 14,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header con punteggio Verde/Rosso e pulsanti "Prova la tua App", "Simula Errore", "Auto-Completa"
              _buildGameHeader(wide),
              const SizedBox(height: 14),

              // 2. Banner Diagnostico Live (Verde = Tutto OK, Rosso = Errore di collegamento, Giallo = Pezzo mancante)
              _buildDiagnosticStatusBanner(),
              const SizedBox(height: 16),

              // 3. Cassetta degli Attrezzi: I 5 Mattoncini trascinabili (con tasto "ℹ️ Cos'è?")
              _buildDraggableToolbox(wide),
              const SizedBox(height: 18),

              // 4. Lavagna Interattiva di Costruzione (Slots ① -> ② -> ③ -> ④ -> ⑤ con Cavi Verdi/Rossi)
              _buildArchitectureDropBoard(wide),
              const SizedBox(height: 18),

              // 5. Guida Rapida "Come viaggia un click dentro un'App vera?"
              _buildBottomRestaurantLegend(wide),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameHeader(bool wide) {
    final int score = _correctCount;
    final bool allGood = score == 5;
    final Color scoreCol = allGood ? _mintOk : (_hasWrongPlacedPiece ? _redErr : _amberWarn);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF102042).withOpacity(0.94),
            const Color(0xFF091126).withOpacity(0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreCol.withOpacity(0.55), width: 1.6),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scoreCol.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scoreCol, width: 1.6),
                ),
                child: const Center(
                  child: Text('🧩', style: TextStyle(fontSize: 27)),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIOCO INTERATTIVO // COSTRUISCI UNA VERA APPLICAZIONE!',
                      style: AuroraPalette.headingStyle(
                        size: wide ? 19 : 16.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trascina i 5 pezzi (Frontend, FastAPI, Backend, Database, AI/Docker) nelle caselle giuste qui sotto. Clicca su ogni pezzo per aprire il pop-up che spiega cos\'è!',
                      style: AuroraPalette.bodyStyle(
                        size: 13.5,
                        color: const Color(0xFFBAE6FD),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Pulsanti Azione del Gioco
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Contatore Pezzi Corretti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: scoreCol.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scoreCol, width: 1.5),
                ),
                child: Text(
                  allGood
                      ? '🟢 5/5 PEZZI CORRETTI!'
                      : (_hasWrongPlacedPiece
                          ? '🔴 ERRORE DI COLLEGAMENTO ($score/5)'
                          : '🟡 PEZZI PRONTI: $score / 5'),
                  style: AuroraPalette.headingStyle(size: 12.5, color: scoreCol),
                ),
              ),

              // Pulsante "▶ PROVA LA TUA APP!"
              InkWell(
                onTap: _isTestingApp ? null : _runInteractiveAppTest,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_mintOk.withOpacity(0.32), _greenOk.withOpacity(0.18)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _mintOk, width: 1.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTestingApp ? Icons.sync_rounded : Icons.play_circle_fill_rounded,
                        size: 18,
                        color: _mintOk,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isTestingApp ? 'TEST IN CORSO...' : '▶ PROVA LA TUA APP!',
                        style: AuroraPalette.headingStyle(size: 12.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Pulsante "Mostra un Errore Rosso" per imparare
              InkWell(
                onTap: _createWrongExampleForLearning,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _redErr.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _redErr.withOpacity(0.6)),
                  ),
                  child: Text(
                    '🔴 Simula Errore',
                    style: AuroraPalette.headingStyle(size: 12, color: _redErr),
                  ),
                ),
              ),

              // Pulsante "Completa Tutto in Verde"
              InkWell(
                onTap: _autoSolveBoard,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _cyan.withOpacity(0.6)),
                  ),
                  child: Text(
                    '💡 Soluzione Completa',
                    style: AuroraPalette.headingStyle(size: 12, color: _cyan),
                  ),
                ),
              ),

              // Pulsante "Svuota"
              InkWell(
                onTap: _resetBoard,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '↺ Svuota',
                    style: AuroraPalette.headingStyle(size: 12, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. BANNER DIAGNOSTICO IN TEMPO REALE (VERDE / ROSSO / GIALLO)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDiagnosticStatusBanner() {
    final bool isComplete = _correctCount == 5;
    final bool hasError = _hasWrongPlacedPiece || _testStoppedOnError;
    final Color col = hasError ? _redErr : (isComplete ? _mintOk : _amberWarn);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: col.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col, width: 1.8),
        boxShadow: [
          BoxShadow(color: col.withOpacity(0.15), blurRadius: 14),
        ],
      ),
      child: Row(
        children: [
          Icon(
            hasError
                ? Icons.dangerous_rounded
                : (isComplete ? Icons.verified_rounded : Icons.info_outline_rounded),
            color: col,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _liveDiagnosticBanner,
              style: AuroraPalette.headingStyle(
                size: 14,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => setState(() => _autoShowPopupOnDrop = !_autoShowPopupOnDrop),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _autoShowPopupOnDrop ? '💬 Pop-up automatici: ON' : '💬 Pop-up automatici: OFF',
                style: AuroraPalette.bodyStyle(size: 11.5, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. CASSETTA DEGLI ATTREZZI (PEZZI TRASCINABILI + PULSANTE POP-UP "ℹ️ COS'È?")
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDraggableToolbox(bool wide) {
    return AuroraGlassCard(
      accentColor: _cyan,
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handyman_rounded, color: _cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🧰 1. I 5 PEZZI DI UN\'APPLICAZIONE — Trascinali nei riquadri sotto (oppure clicca "➕ Inserisci" o "ℹ️ Cos\'è?"):',
                  style: AuroraPalette.headingStyle(size: 14, color: _cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _allSpecs.map((spec) {
              final int placedIndex = _boardSlots.indexOf(spec.type);
              final bool isPlaced = placedIndex != -1;
              final bool isCorrectlyPlaced = isPlaced && placedIndex == spec.correctSlotIndex;

              final Widget cardContent = _buildToolboxPieceCard(
                spec: spec,
                isPlaced: isPlaced,
                isCorrectlyPlaced: isCorrectlyPlaced,
                placedIndex: placedIndex,
              );

              return Draggable<AppPieceType>(
                data: spec.type,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.06,
                    child: SizedBox(
                      width: 230,
                      child: _buildToolboxPieceCard(
                        spec: spec,
                        isPlaced: false,
                        isCorrectlyPlaced: false,
                        placedIndex: -1,
                        isDraggingFeedback: true,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: SizedBox(width: 225, child: cardContent),
                ),
                child: SizedBox(width: 225, child: cardContent),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolboxPieceCard({
    required AppComponentSpec spec,
    required bool isPlaced,
    required bool isCorrectlyPlaced,
    required int placedIndex,
    bool isDraggingFeedback = false,
  }) {
    final Color statusBorder = !isPlaced
        ? spec.color
        : (isCorrectlyPlaced ? _mintOk : _redErr);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDraggingFeedback
            ? const Color(0xFF14224A)
            : const Color(0xFF0B142C).withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusBorder,
          width: isPlaced || isDraggingFeedback ? 2.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: statusBorder.withOpacity(isDraggingFeedback ? 0.45 : 0.15),
            blurRadius: isDraggingFeedback ? 20 : 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(spec.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.shortTitle,
                      style: AuroraPalette.headingStyle(size: 14, color: Colors.white),
                    ),
                    Text(
                      spec.roleLabel,
                      style: AuroraPalette.bodyStyle(size: 11.5, color: spec.color),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.drag_indicator_rounded, color: Colors.white38, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              spec.techStack,
              style: AuroraPalette.monoStyle(size: 10.5, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pulsante Pop-up "ℹ️ Cos'è?"
              InkWell(
                onTap: () => _showComponentExplanationDialog(spec),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: spec.color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: spec.color.withOpacity(0.55)),
                  ),
                  child: Text(
                    'ℹ️ Cos\'è?',
                    style: AuroraPalette.headingStyle(size: 11.5, color: Colors.white),
                  ),
                ),
              ),
              // Pulsante 1-Click per chi non vuole trascinare
              InkWell(
                onTap: () => _quickPlacePiece(spec.type),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPlaced
                        ? (isCorrectlyPlaced
                            ? _mintOk.withOpacity(0.2)
                            : _redErr.withOpacity(0.2))
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPlaced
                          ? (isCorrectlyPlaced ? _mintOk : _redErr)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    isPlaced
                        ? (isCorrectlyPlaced
                            ? '🟢 Posto ${placedIndex + 1} ✓'
                            : '🔴 Posto ${placedIndex + 1} ✗')
                        : '➕ Inserisci',
                    style: AuroraPalette.headingStyle(
                      size: 11.5,
                      color: isPlaced
                          ? (isCorrectlyPlaced ? _mintOk : _redErr)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. LAVAGNA INTERATTIVA DRAG & DROP CON CAVI VERDI / ROSSI
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildArchitectureDropBoard(bool wide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF060A18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _correctCount == 5
              ? _mintOk.withOpacity(0.75)
              : (_hasWrongPlacedPiece ? _redErr.withOpacity(0.75) : _cyan.withOpacity(0.35)),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (_correctCount == 5
                    ? _mintOk
                    : (_hasWrongPlacedPiece ? _redErr : _cyan))
                .withOpacity(0.12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_tree_rounded, color: _cyan, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '🏗️ 2. LA LAVAGNA DELL\'APP — Trascina ogni pezzo nella sua postazione (① ➔ ② ➔ ③ ➔ ④ ➔ ⑤):',
                    style: AuroraPalette.headingStyle(size: 15, color: Colors.white),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(_mintOk, 'Verde = Collegato Bene'),
                  const SizedBox(width: 12),
                  _legendDot(_redErr, 'Rosso = Mancante o Sbagliato'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Schema Visivo dei Cavi di Connessione Animati (Canvas GPU Fast-Path)
          SizedBox(
            height: 76,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CircuitCablesPainter(
                  pulseCtrl: _pulseCtrl,
                  slots: _boardSlots,
                  allSpecs: _allSpecs,
                  testFlowStep: _testFlowStep,
                  testStoppedOnError: _testStoppedOnError,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // I 5 Grandi Slot DragTarget
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 4 ? 10 : 0),
                    child: _buildDropSlotTarget(i),
                  ),
                );
              }),
            )
          else
            Column(
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDropSlotTarget(i),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color col, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AuroraPalette.headingStyle(size: 12, color: col),
        ),
      ],
    );
  }

  Widget _buildDropSlotTarget(int slotIdx) {
    final slotInfo = _slotDescriptions[slotIdx];
    final AppPieceType? placedType = _boardSlots[slotIdx];
    final AppComponentSpec? placedSpec = placedType != null ? _specFor(placedType) : null;
    final bool isEmpty = placedSpec == null;
    final bool isCorrect = _isSlotCorrect(slotIdx);
    final bool isActiveTestStep = _testFlowStep == slotIdx;

    // Colore semaforico chiarissimo:
    // - Verde Smeraldo se il pezzo inserito è quello giusto
    // - Rosso Corallo se lo slot è vuoto (manca un pezzo!) oppure se c'è un pezzo sbagliato
    final Color statusColor = isCorrect ? _mintOk : _redErr;

    return DragTarget<AppPieceType>(
      onWillAccept: (_) => true,
      onAccept: (piece) => _placePieceInSlot(piece, slotIdx, showPopup: true),
      builder: (ctx, candidateData, _) {
        final bool isHoveringDrag = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minHeight: 245),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isHoveringDrag
                  ? [_cyan.withOpacity(0.28), const Color(0xFF0D1B3A)]
                  : (isCorrect
                      ? [_mintOk.withOpacity(0.18), const Color(0xFF091826)]
                      : [_redErr.withOpacity(0.16), const Color(0xFF1A0B18)]),
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHoveringDrag ? _cyan : statusColor,
              width: isHoveringDrag || isActiveTestStep ? 2.8 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHoveringDrag ? _cyan : statusColor).withOpacity(0.22),
                blurRadius: isActiveTestStep ? 22 : 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intestazione della Postazione (①..⑤) + Bollino Verde/Rosso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      slotInfo.$1,
                      style: AuroraPalette.headingStyle(
                        size: 12,
                        color: isCorrect ? _mintOk : const Color(0xFFFDA4AF),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      isCorrect
                          ? '🟢 OK ✓'
                          : (isEmpty ? '🔴 MANCA!' : '🔴 ERRATO!'),
                      style: AuroraPalette.headingStyle(size: 10.5, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                slotInfo.$2,
                style: AuroraPalette.headingStyle(size: 13, color: Colors.white),
              ),
              const SizedBox(height: 12),

              // Contenuto: Slot Vuoto vs Pezzo Inserito
              if (isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHoveringDrag ? _cyan : _redErr.withOpacity(0.55),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isHoveringDrag ? Icons.download_done_rounded : Icons.add_circle_outline_rounded,
                        color: isHoveringDrag ? _cyan : _redErr,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isHoveringDrag
                            ? 'RILASCIA QUI IL PEZZO!'
                            : 'CASELLA VUOTA\nTrascina qui un pezzo!',
                        style: AuroraPalette.headingStyle(
                          size: 12.5,
                          color: isHoveringDrag ? _cyan : const Color(0xFFFDA4AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '💡 Indizio: ${slotInfo.$3}',
                  style: AuroraPalette.bodyStyle(
                    size: 12,
                    color: Colors.white70,
                  ),
                ),
              ] else ...[
                // Pezzo Posizionato nello Slot
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081124).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1.6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(placedSpec.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placedSpec.shortTitle,
                                  style: AuroraPalette.headingStyle(size: 14.5, color: Colors.white),
                                ),
                                Text(
                                  placedSpec.roleLabel,
                                  style: AuroraPalette.bodyStyle(size: 11.5, color: placedSpec.color),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCorrect
                            ? '✅ Perfetto! ${placedSpec.restaurantAnalogy}'
                            : '❌ Posto sbagliato! ${placedSpec.wrongPlacementHint}',
                        style: AuroraPalette.bodyStyle(
                          size: 12,
                          color: isCorrect ? Colors.white : const Color(0xFFFECDD3),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => _showComponentExplanationDialog(
                              placedSpec,
                              placedInSlot: slotIdx,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: placedSpec.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ℹ️ Spiegazione',
                                style: AuroraPalette.headingStyle(size: 11, color: Colors.white),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _removePieceFromSlot(slotIdx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✖ Togli',
                                style: AuroraPalette.headingStyle(size: 11, color: Colors.white70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. RIEPILOGO VISIVO IN BASSO: "LA METAFORA DEL RISTORANTE DIGITALE"
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomRestaurantLegend(bool wide) {
    return AuroraGlassCard(
      accentColor: _mintOk,
      padding: const EdgeInsets.all(18),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🍽️ COME RICORDARLI TUTTI E 5 SENZA FATICA? PENSA A UN RISTORANTE!',
            style: AuroraPalette.headingStyle(size: 15, color: _mintOk),
          ),
          const SizedBox(height: 6),
          Text(
            'Ogni volta che usi Instagram, WhatsApp, ChatGPT o Netflix, dietro lo schermo lavorano sempre questi 5 personaggi in squadra:',
            style: AuroraPalette.bodyStyle(size: 13.5, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allSpecs.map((s) {
              return InkWell(
                onTap: () => _showComponentExplanationDialog(s),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: wide ? 210 : double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: s.color.withOpacity(0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.emoji} ${s.correctSlotIndex + 1}. ${s.shortTitle}',
                        style: AuroraPalette.headingStyle(size: 13.5, color: s.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.restaurantAnalogy,
                        style: AuroraPalette.bodyStyle(size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITTORE CAVI ARCHITETTONICI (VERDE = COLLEGATO BENE, ROSSO = INTERROTTO/ERRATO)
// ─────────────────────────────────────────────────────────────────────────────
class _CircuitCablesPainter extends CustomPainter {
  final Animation<double> pulseCtrl;
  final List<AppPieceType?> slots;
  final List<AppComponentSpec> allSpecs;
  final int testFlowStep;
  final bool testStoppedOnError;

  _CircuitCablesPainter({
    required this.pulseCtrl,
    required this.slots,
    required this.allSpecs,
    required this.testFlowStep,
    required this.testStoppedOnError,
  }) : super(repaint: pulseCtrl);

  static const Color _mintOk = Color(0xFF34D399);
  static const Color _redErr = Color(0xFFF43F5E);

  bool _slotOk(int idx) {
    final p = slots[idx];
    if (p == null) return false;
    final spec = allSpecs.firstWhere((s) => s.type == p);
    return spec.correctSlotIndex == idx;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height * 0.52;
    final List<Offset> nodes = List.generate(5, (i) {
      final double x = size.width * (0.10 + i * 0.20);
      return Offset(x, cy);
    });

    final List<String> linkLabels = [
      'Richiesta HTTP ➔',
      'Ordine JSON ➔',
      'Salva / Leggi Dati ⇄',
      'Chiedi a AI & Cloud ⇄',
    ];

    // Disegna i 4 cavi di collegamento tra i 5 nodi
    for (int i = 0; i < 4; i++) {
      final Offset pA = nodes[i];
      final Offset pB = nodes[i + 1];
      final bool linkHealthy = _slotOk(i) && _slotOk(i + 1);
      final Color cableCol = linkHealthy ? _mintOk : _redErr;

      canvas.drawLine(
        pA,
        pB,
        Paint()
          ..color = cableCol.withOpacity(linkHealthy ? 0.75 : 0.45)
          ..strokeWidth = linkHealthy ? 4.0 : 2.8,
      );

      final Offset mid = Offset((pA.dx + pB.dx) * 0.5, cy - 22);
      TextLayoutCache.paintBadge(
        canvas,
        text: linkHealthy ? '🟢 ${linkLabels[i]}' : '🔴 Collegamento Interrotto',
        center: mid,
        textColor: cableCol,
        borderColor: cableCol.withOpacity(0.65),
        fontSize: 10.5,
      );

      // Impulso luminoso che viaggia lungo i cavi VERDI correttamente collegati
      if (linkHealthy) {
        final Offset pulsePos = Offset.lerp(pA, pB, pulseCtrl.value)!;
        FastCanvasEffects.drawSoftGlowCircle(canvas, pulsePos, 7, _mintOk, intensity: 0.9, rings: 2);
        canvas.drawCircle(pulsePos, 4.5, Paint()..color = Colors.white);
      }
    }

    // Disegna i 5 nodi numerati ①..⑤
    for (int i = 0; i < 5; i++) {
      final bool ok = _slotOk(i);
      final bool isCurrentTest = testFlowStep == i;
      final Color nodeCol = ok ? _mintOk : _redErr;

      FastCanvasEffects.drawSoftGlowCircle(
        canvas,
        nodes[i],
        isCurrentTest ? 18 : 13,
        nodeCol,
        intensity: isCurrentTest ? 1.0 : 0.8,
      );
      canvas.drawCircle(nodes[i], 13, Paint()..color = const Color(0xFF081024));
      canvas.drawCircle(
        nodes[i],
        13,
        Paint()
          ..color = nodeCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      TextLayoutCache.paintCentered(
        canvas,
        text: '${i + 1}',
        center: nodes[i],
        fontSize: 12,
        color: Colors.white,
        weight: FontWeight.bold,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitCablesPainter oldDelegate) =>
      oldDelegate.testFlowStep != testFlowStep ||
      oldDelegate.testStoppedOnError != testStoppedOnError;
}
