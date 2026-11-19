// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'core_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LAB 04 // DOCKER SPIEGATO A CHI NON È TECNICO ("LA VALIGIA MAGICA DELLE APP")
// Progettato per massima leggibilità, caratteri grandi, zero gergo intimidatorio
// in modalità "Da Zero" e illustrazioni animate ad alto contrasto.
// ─────────────────────────────────────────────────────────────────────────────

enum DockerStoryScene {
  problemWithoutDocker, // 1. Il Problema: "Sul mio PC funziona, sul tuo no!"
  solutionWithDocker,   // 2. La Soluzione: La "Valigia Completa" (Il Container)
  threeMagicWords,      // 3. Come funziona in 3 passi: Lista ➔ Pacco ➔ Scatola Accesa
  lightweightAdvantage, // 4. Perché è così veloce? Villa Pesante vs Stanza Pronta
}

class DockerLabWorkspace extends StatefulWidget {
  final bool isBeginnerMode;

  const DockerLabWorkspace({
    super.key,
    this.isBeginnerMode = true,
  });

  @override
  State<DockerLabWorkspace> createState() => _DockerLabWorkspaceState();
}

class _DockerLabWorkspaceState extends State<DockerLabWorkspace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  DockerStoryScene _scene = DockerStoryScene.problemWithoutDocker;

  // Simulatore interattivo "Prepara la spedizione":
  // L'utente può provare a inviare l'app con o senza gli ingredienti sigillati
  bool _includeEngine = true;
  bool _includeLibraries = true;
  int _activeClones = 2; // Quante copie della scatola accendere in 1 click (1, 2 o 3)

  static const Color _sky = Color(0xFF38BDF8);
  static const Color _cyan = Color(0xFF00F0FF);
  static const Color _mint = Color(0xFF34D399);
  static const Color _coral = Color(0xFFFB7185);
  static const Color _amber = Color(0xFFFBBF24);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _nextScene() {
    final idx = DockerStoryScene.values.indexOf(_scene);
    if (idx < DockerStoryScene.values.length - 1) {
      setState(() => _scene = DockerStoryScene.values[idx + 1]);
    } else {
      setState(() => _scene = DockerStoryScene.problemWithoutDocker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final bool wide = constraints.maxWidth > 1020;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 26 : 16,
            vertical: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Intestazione chiara e grande
              _buildHeroHeader(wide),
              const SizedBox(height: 16),

              // 2. Percorso guidato in 4 grandi tappe cliccabili (numerate 1 -> 2 -> 3 -> 4)
              _buildBigStepSelector(wide),
              const SizedBox(height: 18),

              // 3. Area principale: Grande Teatro Visivo Animato + Spiegazione Semplice a Fianco
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 12, child: _buildVisualTheaterCard(height: 470)),
                    const SizedBox(width: 20),
                    Expanded(flex: 10, child: _buildGuidedStoryCard()),
                  ],
                )
              else ...[
                _buildVisualTheaterCard(height: 420),
                const SizedBox(height: 16),
                _buildGuidedStoryCard(),
              ],

              const SizedBox(height: 20),

              // 4. Fascia inferiore: Riepilogo visivo delle 3 Carte d'Identità di Docker
              _buildBottomSummaryCards(wide),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. HERO HEADER AD ALTA VISIBILITÀ
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(bool wide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F224A).withOpacity(0.92),
            const Color(0xFF0A132C).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky.withOpacity(0.45), width: 1.4),
        boxShadow: [
          BoxShadow(color: _sky.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6)),
        ],
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
                  gradient: const LinearGradient(
                    colors: [_sky, Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: _sky.withOpacity(0.4), blurRadius: 12),
                  ],
                ),
                child: const Center(
                  child: Text('🐳', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isBeginnerMode
                          ? 'COS\'È DOCKER? // LA "VALIGIA MAGICA" DEI PROGRAMMI'
                          : 'DOCKER & CONTAINER // ARCHITETTURA E ISOLAMENTO',
                      style: AuroraPalette.headingStyle(
                        size: wide ? 20 : 17,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isBeginnerMode
                          ? 'Spiegato senza paroloni: perché un programma funziona su un computer ma si blocca su un altro, e come Docker risolve tutto con una scatola.'
                          : 'Come impacchettare codice, runtime e dipendenze in unità standardizzate che girano identiche su ogni sistema operativo.',
                      style: AuroraPalette.bodyStyle(
                        size: 14,
                        color: const Color(0xFFBAE6FD),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _nextScene,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: _mint.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _mint, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROSSIMO PASSO ➔',
                    style: AuroraPalette.headingStyle(size: 13, color: _mint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SELETTORE A 4 GRANDI TAPPE (CARATTERI GRANDI E CHIARI)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBigStepSelector(bool wide) {
    final steps = [
      (
        DockerStoryScene.problemWithoutDocker,
        '1',
        '❌ IL PROBLEMA',
        'Perché un programma si blocca su un altro PC?',
        _coral,
      ),
      (
        DockerStoryScene.solutionWithDocker,
        '2',
        '✅ LA VALIGIA DOCKER',
        'Spedire il programma insieme ai suoi ingredienti',
        _mint,
      ),
      (
        DockerStoryScene.threeMagicWords,
        '3',
        '📦 COME FUNZIONA',
        'Lista ➔ Pacco Sigillato ➔ Scatola Accesa',
        _sky,
      ),
      (
        DockerStoryScene.lightweightAdvantage,
        '4',
        '⚡ PERCHÉ È VELOCISSIMO',
        'Casa Intera (Vecchio) vs Stanza Pronta (Docker)',
        _amber,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: steps.map((s) {
        final bool active = _scene == s.$1;
        final Color col = s.$5;
        final double cardWidth = wide
            ? (MediaQuery.of(context).size.width - 88) / 4
            : double.infinity;

        return SizedBox(
          width: cardWidth.clamp(210.0, 520.0),
          child: InkWell(
            onTap: () => setState(() => _scene = s.$1),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        colors: [col.withOpacity(0.26), col.withOpacity(0.10)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active ? null : const Color(0xFF0E162E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? col : Colors.white.withOpacity(0.15),
                  width: active ? 2.0 : 1.0,
                ),
                boxShadow: active
                    ? [BoxShadow(color: col.withOpacity(0.22), blurRadius: 14)]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: active ? col : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s.$2,
                        style: AuroraPalette.headingStyle(
                          size: 15,
                          color: active ? const Color(0xFF050711) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$3,
                          style: AuroraPalette.headingStyle(
                            size: 13.5,
                            color: active ? col : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.$4,
                          style: AuroraPalette.bodyStyle(
                            size: 12,
                            color: Colors.white.withOpacity(active ? 0.95 : 0.7),
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
      }).toList(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3A. TEATRO VISIVO ANIMATO (GRANDE, PULITO E INTERATTIVO)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildVisualTheaterCard({required double height}) {
    final Color borderCol = _scene == DockerStoryScene.problemWithoutDocker
        ? _coral
        : (_scene == DockerStoryScene.solutionWithDocker ? _mint : _sky);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF070C1C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol.withOpacity(0.55), width: 1.8),
        boxShadow: [
          BoxShadow(color: borderCol.withOpacity(0.12), blurRadius: 24),
        ],
      ),
      child: Column(
        children: [
          // Barra superiore del Teatro Visivo con switch rapido Problema / Soluzione
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded, color: borderCol, size: 19),
                    const SizedBox(width: 8),
                    Text(
                      _theaterTitle(),
                      style: AuroraPalette.headingStyle(size: 13.5, color: Colors.white),
                    ),
                  ],
                ),
                // Pulsanti rapidi per confrontare al volo Senza vs Con Docker
                if (_scene == DockerStoryScene.problemWithoutDocker ||
                    _scene == DockerStoryScene.solutionWithDocker)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _quickScenePill(
                        label: '❌ Vedi Senza Docker',
                        active: _scene == DockerStoryScene.problemWithoutDocker,
                        color: _coral,
                        onTap: () => setState(() => _scene = DockerStoryScene.problemWithoutDocker),
                      ),
                      const SizedBox(width: 8),
                      _quickScenePill(
                        label: '✅ Vedi Con Docker',
                        active: _scene == DockerStoryScene.solutionWithDocker,
                        color: _mint,
                        onTap: () => setState(() => _scene = DockerStoryScene.solutionWithDocker),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Area Canvas Animata
          Expanded(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _FriendlyDockerPainter(
                  animCtrl: _animCtrl,
                  scene: _scene,
                  includeEngine: _includeEngine,
                  includeLibraries: _includeLibraries,
                  activeClones: _activeClones,
                  isBeginnerMode: widget.isBeginnerMode,
                ),
              ),
            ),
          ),

          // Barra inferiore interattiva dentro il teatro (Fai una prova tu!)
          _buildTheaterBottomControls(),
        ],
      ),
    );
  }

  String _theaterTitle() {
    switch (_scene) {
      case DockerStoryScene.problemWithoutDocker:
        return 'SCENA 1 // Cosa succede se mandi un programma "nudo" a un altro computer';
      case DockerStoryScene.solutionWithDocker:
        return 'SCENA 2 // Cosa succede se chiudi tutto nella Valigia Sigillata Docker';
      case DockerStoryScene.threeMagicWords:
        return 'SCENA 3 // Dalla Lista degli ingredienti alle Scatole Accese';
      case DockerStoryScene.lightweightAdvantage:
        return 'SCENA 4 // Confronto Velocità e Peso: Vecchio Metodo vs Docker';
    }
  }

  Widget _quickScenePill({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.24) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.white24, width: active ? 1.5 : 1.0),
        ),
        child: Text(
          label,
          style: AuroraPalette.headingStyle(
            size: 11.5,
            color: active ? color : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildTheaterBottomControls() {
    if (_scene == DockerStoryScene.solutionWithDocker) {
      final bool allPacked = _includeEngine && _includeLibraries;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D152C),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '🧪 PROVA TU — Cosa metti nella valigia insieme all\'App?',
              style: AuroraPalette.headingStyle(size: 12.5, color: _cyan),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ingredientToggle(
                  label: '⚙️ Il Motore Giusto',
                  checked: _includeEngine,
                  onTap: () => setState(() => _includeEngine = !_includeEngine),
                ),
                _ingredientToggle(
                  label: '📚 Gli Ingredienti Extra',
                  checked: _includeLibraries,
                  onTap: () => setState(() => _includeLibraries = !_includeLibraries),
                ),
                if (!allPacked)
                  InkWell(
                    onTap: () => setState(() {
                      _includeEngine = true;
                      _includeLibraries = true;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _mint.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _mint),
                      ),
                      child: Text(
                        '📦 Rimetti tutto con Docker!',
                        style: AuroraPalette.headingStyle(size: 11.5, color: _mint),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    if (_scene == DockerStoryScene.threeMagicWords) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D152C),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '🧪 PROVA TU — Quante Scatole (Container) vuoi accendere dallo stesso Pacco?',
              style: AuroraPalette.headingStyle(size: 12.5, color: _cyan),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 3].map((n) {
                final bool active = _activeClones == n;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkWell(
                    onTap: () => setState(() => _activeClones = n),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? _mint.withOpacity(0.25) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? _mint : Colors.white24, width: 1.4),
                      ),
                      child: Text(
                        '$n ${n == 1 ? "Scatola" : "Scatole"}',
                        style: AuroraPalette.headingStyle(
                          size: 12,
                          color: active ? _mint : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D152C),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              _scene == DockerStoryScene.problemWithoutDocker
                  ? '👉 Guarda sopra: il programma arriva sul PC di Sara senza il Motore e gli Ingredienti, quindi si blocca!'
                  : '👉 Guarda sopra: un Container Docker si accende in mezzo secondo perché non deve ricostruire tutta la casa!',
              style: AuroraPalette.bodyStyle(size: 12.5, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _nextScene,
            child: Text(
              'Vai avanti ➔',
              style: AuroraPalette.headingStyle(size: 12.5, color: _cyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientToggle({
    required String label,
    required bool checked,
    required VoidCallback onTap,
  }) {
    final Color col = checked ? _mint : _coral;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: col.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col, width: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: col,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AuroraPalette.headingStyle(size: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3B. SCHEDA DI SPIEGAZIONE SEMPLICE (TESTO GRANDE, ESEMPI QUOTIDIANI)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGuidedStoryCard() {
    switch (_scene) {
      case DockerStoryScene.problemWithoutDocker:
        return _storyContainer(
          accent: _coral,
          badgeText: 'TAPPA 1 DI 4 · IL PROBLEMA DI TUTTI I GIORNI',
          title: 'Perché un programma funziona sul mio computer e sul tuo no?',
          paragraphs: [
            'Immagina di aver preparato una torta buonissima a casa tua. Poi mandi a un tuo amico SOLO l\'impasto crudo, convinto che basti infornarlo.',
            'Quando il tuo amico prova a cuocerla a casa sua, però, il suo forno è diverso, gli manca la teglia giusta e non ha il lievito che avevi usato tu: la torta brucia!',
            'Nei computer succede la stessa identica cosa: un programma per funzionare ha bisogno di tanti "aiutanti" invisibili (il motore giusto, le librerie, i permessi). Se mandi solo il programma a un altro computer che non ha quegli aiutanti, appare un errore e non si apre.',
          ],
          exampleTitle: '💡 La frase più famosa (e odiata) dell\'informatica:',
          exampleText:
              '"Strano... sul mio computer funzionava benissimo!" — È proprio per eliminare per sempre questo problema che è nato Docker.',
          actionLabel: 'Scopri come risolve Docker ➔',
        );

      case DockerStoryScene.solutionWithDocker:
        return _storyContainer(
          accent: _mint,
          badgeText: 'TAPPA 2 DI 4 · LA SOLUZIONE DELLA VALIGIA SIGILLATA',
          title: 'Docker chiude il programma E i suoi aiutanti nella stessa valigia!',
          paragraphs: [
            'Invece di spedire il programma da solo e sperare che il computer di chi lo riceve abbia tutti i pezzi giusti, Docker crea una VALIGIA SIGILLATA (chiamata Container).',
            'Dentro questa valigia mettiamo tutto insieme:\n'
                '• 🎨 Il Programma vero e proprio\n'
                '• ⚙️ Il Motore esatto con cui è stato creato\n'
                '• 📚 Tutti gli Ingredienti e gli strumenti che gli servono',
            'Quando spedisci questa valigia sul PC di un collega, su un Mac o su un Server di Internet, la valigia ha già tutto dentro: si apre e funziona al primo colpo su qualsiasi computer del mondo!',
          ],
          exampleTitle: '🚢 Perché il simbolo di Docker è una Balena con le casse?',
          exampleText:
              'Perché si ispira ai Container delle navi cargo: prima ogni merce aveva casse diverse, oggi qualsiasi gru del mondo sposta lo stesso container standard a occhi chiusi!',
          actionLabel: 'Vedi i 3 passi con cui funziona ➔',
        );

      case DockerStoryScene.threeMagicWords:
        return _storyContainer(
          accent: _sky,
          badgeText: 'TAPPA 3 DI 4 · LE 3 PAROLE CHIAVE SPIEGATE FACILI',
          title: 'Come si crea una scatola Docker? (Come cucinare un piatto!)',
          paragraphs: [
            'Anche chi non programma può capire Docker ricordando solo 3 parole semplici:',
            '1️⃣ LA LISTA ("Dockerfile"): È un semplice foglietto di testo in cui c\'è scritto cosa mettere nella valigia (es. "Metti il programma e aggiungi gli ingredienti").\n\n'
                '2️⃣ IL PACCO SIGILLATO ("Immagine"): Seguendo la lista, Docker chiude la valigia col cellophane. È il tuo stampo pronto per essere spedito o copiato.\n\n'
                '3️⃣ LA SCATOLA ACCESA ("Container"): Quando apri il pacco su un computer e premi PLAY, il programma prende vita dentro la sua scatola protetta!',
          ],
          exampleTitle: '✨ Il superpotere: 1 Pacco ➔ Tante Scatole!',
          exampleText:
              'Se sul tuo sito arrivano 10.000 persone insieme, dallo stesso Pacco Sigillato puoi accendere 2, 10 o 100 Scatole gemelle in un secondo per dividere il lavoro!',
          actionLabel: 'Scopri perché è così leggero ➔',
        );

      case DockerStoryScene.lightweightAdvantage:
        return _storyContainer(
          accent: _amber,
          badgeText: 'TAPPA 4 DI 4 · PERCHÉ TUTTI USANO DOCKER OGGI?',
          title: 'Perché non rallenta il computer? (Villa Intera vs Stanza Pronta)',
          paragraphs: [
            'Prima di Docker, per isolare un programma si usavano le "Macchine Virtuali": era come costruire una VILLA INTERA da zero dentro il computer, con nuove fondamenta pesantissime. Ci metteva minuti interi solo ad accendersi!',
            'Un Container Docker, invece, è come arredare una STANZA PRONTA dentro il palazzo che hai già: usa le fondamenta del tuo computer, ma ha la sua porta chiusa a chiave così nessun altro programma può entrarci o fare disordine.',
            'Risultato? Pesa 100 volte di meno, si accende in mezzo secondo e quando lo spegni lascia il computer pulito come nuovo!',
          ],
          exampleTitle: '🎯 In sintesi, a cosa serve Docker?',
          exampleText:
              'Permette di provare, spostare e far funzionare qualsiasi programma o Intelligenza Artificiale su qualunque computer in 1 click, senza mai sporcare o bloccare il PC.',
          actionLabel: 'Ricomincia dal Passo 1 ↺',
        );
    }
  }

  Widget _storyContainer({
    required Color accent,
    required String badgeText,
    required String title,
    required List<String> paragraphs,
    required String exampleTitle,
    required String exampleText,
    required String actionLabel,
  }) {
    return AuroraGlassCard(
      accentColor: accent,
      highlightBorder: true,
      padding: const EdgeInsets.all(22),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.55)),
            ),
            child: Text(
              badgeText,
              style: AuroraPalette.headingStyle(size: 11.5, color: accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AuroraPalette.headingStyle(
              size: 19,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          ...paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                p,
                style: AuroraPalette.bodyStyle(
                  size: 14.5,
                  color: Colors.white.withOpacity(0.94),
                  height: 1.55,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exampleTitle,
                  style: AuroraPalette.headingStyle(size: 13.5, color: accent),
                ),
                const SizedBox(height: 5),
                Text(
                  exampleText,
                  style: AuroraPalette.bodyStyle(
                    size: 13.5,
                    color: Colors.white,
                    height: 1.48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: _nextScene,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.32), accent.withOpacity(0.14)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    actionLabel,
                    style: AuroraPalette.headingStyle(size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. RIEPILOGO VISIVO IN BASSO (3 GRANDI SCHEDE SEMPRE VISIBILI)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomSummaryCards(bool wide) {
    final cards = [
      (
        '📝 1. LA LISTA (Dockerfile)',
        'Cosa c\'è scritto dentro?',
        'È il bigliettino con le istruzioni per preparare la valigia: "Prendi il programma, aggiungi il motore giusto e chiudi tutto".',
        _sky,
      ),
      (
        '📦 2. IL PACCO CHIUSO (Immagine)',
        'Perché è così comodo?',
        'È la valigia sigillata pronta da spedire. Puoi inviarla su Internet o a 100 colleghi diversi con la certezza che nessuno perderà mai un pezzo.',
        const Color(0xFFC084FC),
      ),
      (
        '🚀 3. LA SCATOLA VIVA (Container)',
        'Cosa succede quando la apri?',
        'È il programma mentre funziona dentro la sua stanza protetta: si accende in 1 secondo e non sporca mai il computer che lo ospita!',
        _mint,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📌 RIASSUNTO A COLPO D\'OCCHIO: I 3 MATTONCINI DI DOCKER',
          style: AuroraPalette.headingStyle(size: 14.5, color: _cyan, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        if (wide)
          Row(
            children: cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _summaryCardItem(c.$1, c.$2, c.$3, c.$4),
                    ),
                  ),
                )
                .toList(),
          )
        else
          Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _summaryCardItem(c.$1, c.$2, c.$3, c.$4),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _summaryCardItem(String title, String subtitle, String body, Color color) {
    return AuroraGlassCard(
      accentColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AuroraPalette.headingStyle(size: 15, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AuroraPalette.headingStyle(size: 12.5, color: Colors.white),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: AuroraPalette.bodyStyle(
              size: 13.5,
              color: Colors.white.withOpacity(0.88),
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PITTORE GRAFICO AD ALTA VISIBILITÀ PER NON-TECNICI
// Box grandi, icone chiare, testi da 12-16px, zero formule o codici criptici.
// ─────────────────────────────────────────────────────────────────────────────
class _FriendlyDockerPainter extends CustomPainter {
  final Animation<double> animCtrl;
  final DockerStoryScene scene;
  final bool includeEngine;
  final bool includeLibraries;
  final int activeClones;
  final bool isBeginnerMode;

  _FriendlyDockerPainter({
    required this.animCtrl,
    required this.scene,
    required this.includeEngine,
    required this.includeLibraries,
    required this.activeClones,
    required this.isBeginnerMode,
  }) : super(repaint: animCtrl);

  double get t => animCtrl.value;

  static const Color _sky = Color(0xFF38BDF8);
  static const Color _cyan = Color(0xFF00F0FF);
  static const Color _mint = Color(0xFF34D399);
  static const Color _coral = Color(0xFFFB7185);
  static const Color _amber = Color(0xFFFBBF24);

  @override
  void paint(Canvas canvas, Size size) {
    FastCanvasEffects.drawSubtleTechGrid(
      canvas,
      size,
      color: Colors.white.withOpacity(0.03),
      spacing: 38,
    );

    switch (scene) {
      case DockerStoryScene.problemWithoutDocker:
        _paintScene1Problem(canvas, size);
        break;
      case DockerStoryScene.solutionWithDocker:
        _paintScene2ValigiaDocker(canvas, size);
        break;
      case DockerStoryScene.threeMagicWords:
        _paintScene3ThreeSteps(canvas, size);
        break;
      case DockerStoryScene.lightweightAdvantage:
        _paintScene4HouseVsRoom(canvas, size);
        break;
    }
  }

  // ── SCENA 1: SENZA DOCKER (MARCO SPEDISCE SOLO L'APP A SARA -> SI BLOCCA!) ──
  void _paintScene1Problem(Canvas canvas, Size size) {
    final double cy = size.height * 0.53;
    final Offset leftPc = Offset(size.width * 0.22, cy);
    final Offset rightPc = Offset(size.width * 0.78, cy);

    TextLayoutCache.paintBadge(
      canvas,
      text: '❌ SENZA DOCKER: SPEDISCI L\'APP DA SOLA E GLI ALTRI PEZZI RESTANO A CASA!',
      center: Offset(size.width * 0.5, 26),
      textColor: _coral,
      borderColor: _coral.withOpacity(0.75),
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );

    // Ponte tratteggiato tra i due computer
    canvas.drawLine(
      leftPc.translate(95, 0),
      rightPc.translate(-95, 0),
      Paint()
        ..color = _coral.withOpacity(0.45)
        ..strokeWidth = 3.5,
    );

    // PC di Marco (Ha tutti e 3 i pezzi!)
    _drawComputerCard(
      canvas,
      center: leftPc,
      width: 210,
      height: 225,
      header: '💻 PC DI MARCO',
      subHeader: '(Ha creato il programma)',
      accent: _mint,
      slots: const [
        ('🎨 1. Il Programma', true),
        ('⚙️ 2. Il Motore Giusto', true),
        ('📚 3. Gli Ingredienti', true),
      ],
      footerStatus: '✅ QUI FUNZIONA TUTTO!',
    );

    // PC di Sara (Riceve solo il pezzo 1, mancano 2 e 3!)
    _drawComputerCard(
      canvas,
      center: rightPc,
      width: 215,
      height: 225,
      header: '💻 PC DI SARA',
      subHeader: '(Riceve il programma)',
      accent: _coral,
      slots: const [
        ('🎨 1. Il Programma', true),
        ('❌ 2. Manca il Motore!', false),
        ('❌ 3. Mancano Ingredienti!', false),
      ],
      footerStatus: '💥 ERRORE: NON SI APRE!',
    );

    // Animazione del singolo pezzetto che viaggia da solo e va in errore
    final Offset start = leftPc.translate(95, 0);
    final Offset end = rightPc.translate(-95, 0);
    final Offset moving = Offset.lerp(start, end, t)!;
    final bool nearEnd = t > 0.65;

    FastCanvasEffects.drawSoftGlowCircle(
      canvas,
      moving,
      14,
      nearEnd ? _coral : _amber,
      intensity: 0.95,
    );
    TextLayoutCache.paintBadge(
      canvas,
      text: nearEnd ? '💥 Mancano i pezzi 2 e 3!' : '🎨 Viaggia SOLO il Programma',
      center: moving.translate(0, -24),
      textColor: nearEnd ? _coral : _amber,
      borderColor: nearEnd ? _coral : _amber,
      fontSize: 11.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
    canvas.drawCircle(moving, 7, Paint()..color = nearEnd ? _coral : _amber);
  }

  // ── SCENA 2: CON DOCKER (LA VALIGIA SIGILLATA CON TUTTI E 3 I PEZZI) ──
  void _paintScene2ValigiaDocker(Canvas canvas, Size size) {
    final bool allComplete = includeEngine && includeLibraries;
    final Color mainCol = allComplete ? _mint : _coral;

    TextLayoutCache.paintBadge(
      canvas,
      text: allComplete
          ? '✅ CON DOCKER: TUTTI I PEZZI VIAGGIANO CHIUSI NELLA STESSA VALIGIA!'
          : '⚠️ ATTENZIONE: HAI TOLTO UN PEZZO DALLA VALIGIA (RIMETTILO SOTTO!)',
      center: Offset(size.width * 0.5, 26),
      textColor: mainCol,
      borderColor: mainCol.withOpacity(0.8),
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );

    final Offset suitcaseCenter = Offset(size.width * 0.30, size.height * 0.54);
    final List<(String, Offset)> targets = [
      ('💻 PC di Sara', Offset(size.width * 0.78, size.height * 0.27)),
      ('🍎 Mac Ufficio', Offset(size.width * 0.78, size.height * 0.54)),
      ('☁️ Server Internet', Offset(size.width * 0.78, size.height * 0.81)),
    ];

    // Disegna le 3 linee di distribuzione verso i 3 computer diversi
    for (final target in targets) {
      final Offset start = suitcaseCenter.translate(115, 0);
      final Offset end = target.$2.translate(-88, 0);

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = mainCol.withOpacity(0.38)
          ..strokeWidth = 2.8,
      );

      // Piccola valigia in viaggio lungo ogni linea
      final Offset pkt = Offset.lerp(start, end, t)!;
      FastCanvasEffects.drawSoftGlowCircle(canvas, pkt, 7, mainCol, intensity: 0.85, rings: 2);
      canvas.drawCircle(pkt, 4.5, Paint()..color = Colors.white);

      // Scheda computer di destinazione
      final RRect destRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: target.$2, width: 172, height: 64),
        const Radius.circular(12),
      );
      FastCanvasEffects.drawSoftGlowRRect(canvas, destRect, mainCol, intensity: 0.65);
      canvas.drawRRect(destRect, Paint()..color = const Color(0xFF0B132B));
      canvas.drawRRect(
        destRect,
        Paint()
          ..color = mainCol
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      TextLayoutCache.paintCentered(
        canvas,
        text: target.$1,
        center: target.$2.translate(0, -11),
        fontSize: 12.5,
        color: Colors.white,
        weight: FontWeight.bold,
        mono: false,
      );
      TextLayoutCache.paintCentered(
        canvas,
        text: allComplete ? '✅ Funziona al 1° colpo!' : '💥 Manca un pezzo!',
        center: target.$2.translate(0, 12),
        fontSize: 11.5,
        color: mainCol,
        weight: FontWeight.bold,
        mono: false,
      );
    }

    // Grande Valigia Docker a Sinistra
    final RRect box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: suitcaseCenter, width: 228, height: 220),
      const Radius.circular(16),
    );
    FastCanvasEffects.drawSoftGlowRRect(canvas, box, _sky, intensity: 0.95);
    canvas.drawRRect(box, Paint()..color = const Color(0xFF0B1631));
    canvas.drawRRect(
      box,
      Paint()
        ..color = _cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: '🐳 VALIGIA DOCKER',
      center: suitcaseCenter.translate(0, -82),
      fontSize: 14,
      color: _cyan,
      weight: FontWeight.bold,
      mono: false,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: '(Container Sigillato)',
      center: suitcaseCenter.translate(0, -62),
      fontSize: 11.5,
      color: Colors.white70,
      mono: false,
    );

    _drawIngredientSlot(
      canvas,
      center: suitcaseCenter.translate(0, -24),
      width: 196,
      label: '🎨 1. Il Programma',
      present: true,
    );
    _drawIngredientSlot(
      canvas,
      center: suitcaseCenter.translate(0, 14),
      width: 196,
      label: includeEngine ? '⚙️ 2. Il Motore Giusto' : '❌ 2. Motore Tolto!',
      present: includeEngine,
    );
    _drawIngredientSlot(
      canvas,
      center: suitcaseCenter.translate(0, 52),
      width: 196,
      label: includeLibraries ? '📚 3. Gli Ingredienti' : '❌ 3. Ingredienti Tolti!',
      present: includeLibraries,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: allComplete ? '🔒 SIGILLATA E PRONTA' : '⚠️ VALIGIA INCOMPLETA',
      center: suitcaseCenter.translate(0, 88),
      fontSize: 11.5,
      color: mainCol,
      weight: FontWeight.bold,
    );
  }

  // ── SCENA 3: LE 3 PAROLE SEMPLICI (LISTA ➔ PACCO ➔ SCATOLE ACCESE) ──
  void _paintScene3ThreeSteps(Canvas canvas, Size size) {
    TextLayoutCache.paintBadge(
      canvas,
      text: '📦 I 3 PASSI DI DOCKER: DALLA LISTA SCRITTA ALLE SCATOLE ACCESE',
      center: Offset(size.width * 0.5, 26),
      textColor: _cyan,
      borderColor: _cyan.withOpacity(0.75),
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );

    final double cy = size.height * 0.54;
    final Offset p1 = Offset(size.width * 0.18, cy);
    final Offset p2 = Offset(size.width * 0.50, cy);
    final Offset p3 = Offset(size.width * 0.82, cy);

    // Frecce luminose tra i 3 grandi blocchi
    final Paint track = Paint()
      ..color = _sky.withOpacity(0.4)
      ..strokeWidth = 3.2;
    canvas.drawLine(p1.translate(88, 0), p2.translate(-88, 0), track);
    canvas.drawLine(p2.translate(88, 0), p3.translate(-92, 0), track);

    // Luce animata lungo il percorso
    final Offset pulse1 = Offset.lerp(p1.translate(88, 0), p2.translate(-88, 0), t)!;
    final Offset pulse2 = Offset.lerp(p2.translate(88, 0), p3.translate(-92, 0), t)!;
    FastCanvasEffects.drawSoftGlowCircle(canvas, pulse1, 7, _cyan, intensity: 0.9);
    FastCanvasEffects.drawSoftGlowCircle(canvas, pulse2, 7, _mint, intensity: 0.9);
    canvas.drawCircle(pulse1, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(pulse2, 4.5, Paint()..color = Colors.white);

    // Blocco 1: La Lista (Dockerfile)
    _drawBigStageCard(
      canvas,
      center: p1,
      width: 175,
      height: 195,
      stepNumber: 'PASSO 1',
      title: '📝 LA LISTA',
      techName: '(Dockerfile)',
      lines: const [
        '• Metti l\'App',
        '• Aggiungi il Motore',
        '• Aggiungi Librerie',
      ],
      footer: 'Il biglietto d\'istruzioni',
      color: _sky,
    );

    // Blocco 2: Il Pacco Sigillato (Immagine)
    _drawBigStageCard(
      canvas,
      center: p2,
      width: 178,
      height: 195,
      stepNumber: 'PASSO 2',
      title: '📦 IL PACCO',
      techName: '(Immagine Docker)',
      lines: const [
        '🔒 Tutto chiuso insieme',
        '☁️ Pronto da spedire',
        '♾️ Copiabile all\'infinito',
      ],
      footer: 'Lo stampo sigillato',
      color: const Color(0xFFC084FC),
    );

    // Blocco 3: Le Scatole Accese (Container)
    final RRect hostRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: p3, width: 186, height: 195),
      const Radius.circular(16),
    );
    FastCanvasEffects.drawSoftGlowRRect(canvas, hostRect, _mint, intensity: 0.85);
    canvas.drawRRect(hostRect, Paint()..color = const Color(0xFF0A142B));
    canvas.drawRRect(
      hostRect,
      Paint()
        ..color = _mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: 'PASSO 3',
      center: p3.translate(0, -76),
      fontSize: 10.5,
      color: _mint,
      weight: FontWeight.bold,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: '🚀 SCATOLE VIVE',
      center: p3.translate(0, -56),
      fontSize: 14,
      color: Colors.white,
      weight: FontWeight.bold,
      mono: false,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: '(Container in funzione)',
      center: p3.translate(0, -38),
      fontSize: 11,
      color: Colors.white70,
      mono: false,
    );

    for (int i = 0; i < activeClones; i++) {
      final double yOff = -8.0 + i * 33.0;
      final RRect cloneRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: p3.translate(0, yOff), width: 158, height: 26),
        const Radius.circular(8),
      );
      canvas.drawRRect(cloneRect, Paint()..color = _mint.withOpacity(0.2));
      canvas.drawRRect(
        cloneRect,
        Paint()
          ..color = _mint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
      TextLayoutCache.paintCentered(
        canvas,
        text: '🟢 Scatola #${i + 1} ACCESA',
        center: p3.translate(0, yOff),
        fontSize: 11.5,
        color: Colors.white,
        weight: FontWeight.bold,
        mono: false,
      );
    }

    TextLayoutCache.paintCentered(
      canvas,
      text: 'Funziona in 1 secondo!',
      center: p3.translate(0, 78),
      fontSize: 11,
      color: _mint,
      weight: FontWeight.bold,
      mono: false,
    );
  }

  // ── SCENA 4: VILLA PESANTE (MACCHINA VIRTUALE) vs STANZA AGILE (DOCKER) ──
  void _paintScene4HouseVsRoom(Canvas canvas, Size size) {
    TextLayoutCache.paintBadge(
      canvas,
      text: '⚡ PERCHÉ DOCKER È 100 VOLTE PIÙ LEGGERO DEL VECCHIO METODO?',
      center: Offset(size.width * 0.5, 26),
      textColor: _amber,
      borderColor: _amber.withOpacity(0.8),
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );

    final double cy = size.height * 0.55;
    final Offset leftCenter = Offset(size.width * 0.27, cy);
    final Offset rightCenter = Offset(size.width * 0.73, cy);

    // Card Sinistra: Vecchio Metodo (Macchina Virtuale = Costruire una Villa intera)
    final RRect leftRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: leftCenter, width: 255, height: 225),
      const Radius.circular(16),
    );
    canvas.drawRRect(leftRect, Paint()..color = const Color(0xFF141022));
    canvas.drawRRect(
      leftRect,
      Paint()
        ..color = _coral.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: '🏠 VECCHIO METODO',
      center: leftCenter.translate(0, -84),
      fontSize: 14,
      color: _coral,
      weight: FontWeight.bold,
      mono: false,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: '(Macchina Virtuale)',
      center: leftCenter.translate(0, -64),
      fontSize: 11.5,
      color: Colors.white70,
      mono: false,
    );

    _drawLayerBlock(
      canvas,
      leftCenter.translate(0, -28),
      215,
      28,
      '🎨 Il Programma',
      _sky,
    );
    _drawLayerBlock(
      canvas,
      leftCenter.translate(0, 6),
      215,
      30,
      '🧱 Intero Sistema Copia (20 GB!)',
      _coral,
    );
    _drawLayerBlock(
      canvas,
      leftCenter.translate(0, 42),
      215,
      30,
      '🪨 Fondamenta Duplicate Pesanti',
      _coral,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: '🐢 Lento: 2 Minuti per accendersi',
      center: leftCenter.translate(0, 84),
      fontSize: 12,
      color: _coral,
      weight: FontWeight.bold,
      mono: false,
    );

    // Card Destra: Metodo Docker (Container = Stanza Pronta e Leggera)
    final RRect rightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: rightCenter, width: 255, height: 225),
      const Radius.circular(16),
    );
    FastCanvasEffects.drawSoftGlowRRect(canvas, rightRect, _mint, intensity: 0.9);
    canvas.drawRRect(rightRect, Paint()..color = const Color(0xFF0A1929));
    canvas.drawRRect(
      rightRect,
      Paint()
        ..color = _mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: '🏢 METODO DOCKER',
      center: rightCenter.translate(0, -84),
      fontSize: 14,
      color: _mint,
      weight: FontWeight.bold,
      mono: false,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: '(Container Leggero)',
      center: rightCenter.translate(0, -64),
      fontSize: 11.5,
      color: Colors.white70,
      mono: false,
    );

    _drawLayerBlock(
      canvas,
      rightCenter.translate(0, -22),
      215,
      34,
      '🐳 Valigia App + Ingredienti (80 MB)',
      _mint,
    );
    _drawLayerBlock(
      canvas,
      rightCenter.translate(0, 26),
      215,
      34,
      '🏛️ Usa le Fondamenta già presenti!',
      _sky,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: '⚡ Istantaneo: 0,5 Secondi!',
      center: rightCenter.translate(0, 84),
      fontSize: 12.5,
      color: _mint,
      weight: FontWeight.bold,
      mono: false,
    );
  }

  void _drawComputerCard(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required String header,
    required String subHeader,
    required Color accent,
    required List<(String, bool)> slots,
    required String footerStatus,
  }) {
    final RRect card = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(16),
    );
    FastCanvasEffects.drawSoftGlowRRect(canvas, card, accent, intensity: 0.75);
    canvas.drawRRect(card, Paint()..color = const Color(0xFF0B132B));
    canvas.drawRRect(
      card,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: header,
      center: center.translate(0, -84),
      fontSize: 13.5,
      color: Colors.white,
      weight: FontWeight.bold,
      mono: false,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: subHeader,
      center: center.translate(0, -64),
      fontSize: 11,
      color: Colors.white70,
      mono: false,
    );

    for (int i = 0; i < slots.length; i++) {
      _drawIngredientSlot(
        canvas,
        center: center.translate(0, -24.0 + i * 38.0),
        width: width - 26,
        label: slots[i].$1,
        present: slots[i].$2,
      );
    }

    TextLayoutCache.paintCentered(
      canvas,
      text: footerStatus,
      center: center.translate(0, 88),
      fontSize: 11.5,
      color: accent,
      weight: FontWeight.bold,
      mono: false,
    );
  }

  void _drawIngredientSlot(
    Canvas canvas, {
    required Offset center,
    required double width,
    required String label,
    required bool present,
  }) {
    final Color col = present ? _mint : _coral;
    final RRect slot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: 30),
      const Radius.circular(8),
    );
    canvas.drawRRect(slot, Paint()..color = col.withOpacity(0.16));
    canvas.drawRRect(
      slot,
      Paint()
        ..color = col.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: label,
      center: center,
      fontSize: 11.5,
      color: Colors.white,
      weight: FontWeight.bold,
      mono: false,
    );
  }

  void _drawBigStageCard(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required String stepNumber,
    required String title,
    required String techName,
    required List<String> lines,
    required String footer,
    required Color color,
  }) {
    final RRect card = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(16),
    );
    FastCanvasEffects.drawSoftGlowRRect(canvas, card, color, intensity: 0.75);
    canvas.drawRRect(card, Paint()..color = const Color(0xFF0A142B));
    canvas.drawRRect(
      card,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: stepNumber,
      center: center.translate(0, -76),
      fontSize: 10.5,
      color: color,
      weight: FontWeight.bold,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: title,
      center: center.translate(0, -56),
      fontSize: 14,
      color: Colors.white,
      weight: FontWeight.bold,
      mono: false,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: techName,
      center: center.translate(0, -38),
      fontSize: 11,
      color: Colors.white70,
      mono: false,
    );

    for (int i = 0; i < lines.length; i++) {
      TextLayoutCache.paintCentered(
        canvas,
        text: lines[i],
        center: center.translate(0, -6.0 + i * 24.0),
        fontSize: 11.5,
        color: Colors.white.withOpacity(0.95),
        weight: FontWeight.w600,
        mono: false,
      );
    }

    TextLayoutCache.paintCentered(
      canvas,
      text: footer,
      center: center.translate(0, 78),
      fontSize: 11,
      color: color,
      weight: FontWeight.bold,
      mono: false,
    );
  }

  void _drawLayerBlock(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    String text,
    Color color,
  ) {
    final RRect r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(8),
    );
    canvas.drawRRect(r, Paint()..color = color.withOpacity(0.2));
    canvas.drawRRect(
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: text,
      center: center,
      fontSize: 11.5,
      color: Colors.white,
      weight: FontWeight.bold,
      mono: false,
    );
  }

  @override
  bool shouldRepaint(covariant _FriendlyDockerPainter oldDelegate) =>
      oldDelegate.scene != scene ||
      oldDelegate.includeEngine != includeEngine ||
      oldDelegate.includeLibraries != includeLibraries ||
      oldDelegate.activeClones != activeClones ||
      oldDelegate.isBeginnerMode != isBeginnerMode;
}
