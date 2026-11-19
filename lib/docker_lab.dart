// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODULO 04 // LABORATORIO DOCKER & CONTAINER ("LA SCATOLA MAGICA DEL SOFTWARE")
// Spiega visivamente a chi parte da zero:
// 1. Il problema "Sul mio PC funziona, sul Server crasha!" vs La Scatola Sigillata Docker
// 2. La metafora in 3 passi: Ricetta (Dockerfile) ➔ Stampo (Image) ➔ Scatola Viva (Container)
// 3. Differenza visiva tra Macchina Virtuale (Villa pesante) e Container (Appartamento agile)
// 4. Come comunicare con una scatola chiusa: Finestre (Porte) e Cassetti (Volumi)
// ─────────────────────────────────────────────────────────────────────────────

enum DockerStage {
  dockerfile, // 1. La Ricetta (Dockerfile: lista degli ingredienti)
  buildImage, // 2. Lo Stampo Sigillato (docker build -> Docker Image a strati)
  registry,   // 3. Il Magazzino Cloud (docker push/pull -> Docker Hub)
  runHost,    // 4. Le Scatole in Azione (docker run -> Container isolati sul Server)
}

class DockerLayerItem {
  final int index;
  final String simpleName;
  final String techName;
  final String dockerfileLine;
  final String simpleDesc;
  final String sizeLabel;
  final Color color;

  const DockerLayerItem({
    required this.index,
    required this.simpleName,
    required this.techName,
    required this.dockerfileLine,
    required this.simpleDesc,
    required this.sizeLabel,
    required this.color,
  });
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

  // false = Mostra il disastro "Senza Docker ("Sul mio PC funzionava!")"
  // true  = Mostra la soluzione "Con Docker (Funziona ovunque al 1° colpo!)"
  bool _useDockerMode = true;

  DockerStage _currentStage = DockerStage.runHost;
  bool _isAnimatingPipeline = false;
  int _rightTabIndex = 0; // 0 = Perché Docker & VM vs Container, 1 = Gli Strati & Porte, 2 = Dockerfile & 4 Comandi
  int _selectedLayerIdx = 3;
  int _activeContainersCount = 2; // Da 1 a 3 container attivi contemporaneamente sul server
  bool _portWindowOpen = true;

  static const Color _dockerBlue = Color(0xFF38BDF8);
  static const Color _dockerCyan = Color(0xFF00F0FF);

  static const List<DockerLayerItem> _layers = [
    DockerLayerItem(
      index: 1,
      simpleName: 'Strato 1 · Il Pavimento (Mini-Sistema Linux)',
      techName: 'Layer 1 · Base OS Image (Alpine / Ubuntu Slim)',
      dockerfileLine: 'FROM python:3.11-slim',
      simpleDesc:
          'È la base della scatola: un sistema operativo leggerissimo e pulito, uguale su tutti i computer del mondo.',
      sizeLabel: '45 MB',
      color: Color(0xFF38BDF8),
    ),
    DockerLayerItem(
      index: 2,
      simpleName: 'Strato 2 · Gli Attrezzi da Cucina (Librerie & AI)',
      techName: 'Layer 2 · Dependencies (pip / npm / CUDA)',
      dockerfileLine: 'RUN pip install fastapi google-genai uvicorn',
      simpleDesc:
          'Dentro la scatola installiamo già tutte le librerie che servono. Così chi riceve la scatola non dovrà installare nulla!',
      sizeLabel: '68 MB',
      color: Color(0xFF818CF8),
    ),
    DockerLayerItem(
      index: 3,
      simpleName: 'Strato 3 · Il Tuo Programma (Codice dell\'App)',
      techName: 'Layer 3 · Application Source Code',
      dockerfileLine: 'COPY ./app /app',
      simpleDesc:
          'Inseriamo i file della nostra applicazione dentro la scatola sigillata, pronti per essere usati.',
      sizeLabel: '4 MB',
      color: Color(0xFF34D399),
    ),
    DockerLayerItem(
      index: 4,
      simpleName: 'Strato 4 · La Finestra & Il Pulsante di Avvio',
      techName: 'Layer 4 · Port Expose & Entrypoint CMD',
      dockerfileLine: 'EXPOSE 8080\nCMD ["python", "main.py"]',
      simpleDesc:
          'Apriamo una "finestra" (Porta 8080) per far entrare gli utenti e diciamo alla scatola quale pulsante premere quando si accende.',
      sizeLabel: '0 MB (Config)',
      color: Color(0xFFFBBF24),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _runFullDockerJourney() async {
    if (_isAnimatingPipeline) return;
    setState(() {
      _useDockerMode = true;
      _isAnimatingPipeline = true;
      _currentStage = DockerStage.dockerfile;
    });

    for (final stage in DockerStage.values) {
      if (!mounted) return;
      setState(() => _currentStage = stage);
      await Future.delayed(const Duration(milliseconds: 1450));
    }

    if (mounted) {
      setState(() => _isAnimatingPipeline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final bool wide = constraints.maxWidth > 980;
        if (wide) {
          return Row(
            children: [
              Expanded(flex: 11, child: _buildLeftVisualPanel()),
              Container(width: 1, color: _dockerBlue.withOpacity(0.22)),
              Expanded(flex: 10, child: _buildRightEducationalPanel()),
            ],
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 690, child: _buildLeftVisualPanel()),
                Container(height: 1, color: _dockerBlue.withOpacity(0.22)),
                SizedBox(height: 760, child: _buildRightEducationalPanel()),
              ],
            ),
          );
        }
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COLONNA SINISTRA: SIMULATORE VISIVO "SENZA DOCKER" vs "CON DOCKER"
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLeftVisualPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(),
          const SizedBox(height: 10),
          _buildModeAndStageBar(),
          const SizedBox(height: 10),
          Expanded(
            flex: 6,
            child: _buildInteractiveDockerCanvas(),
          ),
          const SizedBox(height: 10),
          _buildLiveExplanationCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _dockerBlue.withOpacity(0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _dockerBlue.withOpacity(0.5)),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: _dockerBlue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isBeginnerMode
                    ? 'LAB 04 // COS\'È DOCKER? ("LA SCATOLA MAGICA DEL SOFTWARE")'
                    : 'LAB 04 // DOCKER ENGINE, IMMAGINI OCI & ISOLAMENTO CONTAINER',
                style: AuroraPalette.headingStyle(
                  size: 15.5,
                  color: _dockerBlue,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.isBeginnerMode
                    ? 'Impacchetta la tua App insieme a tutto ciò che le serve: funzionerà su qualsiasi computer del mondo!'
                    : 'Dalla build multi-layer del Dockerfile al deployment isolato con Port Forwarding e Container Runtime',
                style: AuroraPalette.bodyStyle(
                  color: Colors.white.withOpacity(0.84),
                  size: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeAndStageBar() {
    final stages = [
      (
        DockerStage.dockerfile,
        widget.isBeginnerMode ? '① LA RICETTA' : '① DOCKERFILE',
        widget.isBeginnerMode ? 'Lista ingredienti' : 'Istruzioni testo',
      ),
      (
        DockerStage.buildImage,
        widget.isBeginnerMode ? '② LO STAMPO' : '② DOCKER IMAGE',
        widget.isBeginnerMode ? 'Pacco sigillato' : 'Layer immutabili',
      ),
      (
        DockerStage.registry,
        widget.isBeginnerMode ? '③ IL MAGAZZINO' : '③ DOCKER HUB',
        widget.isBeginnerMode ? 'Spedisci sul Cloud' : 'Cloud Registry',
      ),
      (
        DockerStage.runHost,
        widget.isBeginnerMode ? '④ LA SCATOLA VIVA' : '④ CONTAINER RUN',
        widget.isBeginnerMode ? 'Accesa sul Server!' : 'Istanza isolata',
      ),
    ];

    return AuroraGlassCard(
      accentColor: _useDockerMode ? _dockerBlue : const Color(0xFFF43F5E),
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riga 1: Confronto immediato "❌ Senza Docker" vs "✅ Con Docker" + Pulsante Animazione
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeToggleBtn(
                    active: !_useDockerMode,
                    label: '❌ SENZA DOCKER ("Sul mio PC andava!")',
                    color: const Color(0xFFF43F5E),
                    onTap: () => setState(() => _useDockerMode = false),
                  ),
                  const SizedBox(width: 8),
                  _modeToggleBtn(
                    active: _useDockerMode,
                    label: '✅ CON DOCKER ("Funziona Ovunque!")',
                    color: AuroraPalette.mint,
                    onTap: () => setState(() => _useDockerMode = true),
                  ),
                ],
              ),
              InkWell(
                onTap: _isAnimatingPipeline ? null : _runFullDockerJourney,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _dockerBlue.withOpacity(0.28),
                        AuroraPalette.cyan.withOpacity(0.18),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _dockerCyan),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAnimatingPipeline ? Icons.autorenew_rounded : Icons.play_arrow_rounded,
                        size: 16,
                        color: _dockerCyan,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isAnimatingPipeline ? 'VIAGGIO IN CORSO...' : '▶ ANIMA I 4 PASSI DOCKER',
                        style: AuroraPalette.headingStyle(size: 10.5, color: _dockerCyan),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_useDockerMode) ...[
            const SizedBox(height: 9),
            // Riga 2: Selettore dei 4 passi della pipeline Docker
            Row(
              children: stages.map((s) {
                final bool active = _currentStage == s.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _currentStage = s.$1),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                        decoration: BoxDecoration(
                          color: active ? _dockerBlue.withOpacity(0.22) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? _dockerCyan : Colors.white12,
                            width: active ? 1.4 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              s.$2,
                              style: AuroraPalette.headingStyle(
                                size: 10,
                                color: active ? _dockerCyan : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              s.$3,
                              style: AuroraPalette.bodyStyle(
                                size: 9.5,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeToggleBtn({
    required bool active,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.22) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : Colors.white24,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AuroraPalette.headingStyle(
            size: 10.5,
            color: active ? color : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveDockerCanvas() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF060916),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_useDockerMode ? _dockerBlue : const Color(0xFFF43F5E)).withOpacity(0.38),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (_useDockerMode ? _dockerBlue : const Color(0xFFF43F5E)).withOpacity(0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _DockerFlowPainter(
                animCtrl: _animCtrl,
                useDockerMode: _useDockerMode,
                stage: _currentStage,
                isBeginnerMode: widget.isBeginnerMode,
                activeContainersCount: _activeContainersCount,
                portWindowOpen: _portWindowOpen,
              ),
            ),
          ),
          // Controlli rapidi in sovrimpressione sul canvas quando siamo in modalità Docker
          if (_useDockerMode)
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B19).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _dockerBlue.withOpacity(0.45)),
                  ),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isBeginnerMode ? '🚢 Scatole (Container) accese:' : '🚢 Repliche Container:',
                            style: AuroraPalette.bodyStyle(size: 10.5, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          for (int c = 1; c <= 3; c++)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: InkWell(
                                onTap: () => setState(() {
                                  _activeContainersCount = c;
                                  _currentStage = DockerStage.runHost;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _activeContainersCount == c
                                        ? _dockerBlue.withOpacity(0.3)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: _activeContainersCount == c ? _dockerCyan : Colors.white24,
                                    ),
                                  ),
                                  child: Text(
                                    '${c}x',
                                    style: AuroraPalette.monoStyle(
                                      size: 10,
                                      color: _activeContainersCount == c ? _dockerCyan : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      InkWell(
                        onTap: () => setState(() => _portWindowOpen = !_portWindowOpen),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _portWindowOpen ? Icons.sensor_window_rounded : Icons.disabled_by_default_rounded,
                              size: 14,
                              color: _portWindowOpen ? AuroraPalette.mint : const Color(0xFFF43F5E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _portWindowOpen
                                  ? 'Finestra Porta 8080: APERTA ✓'
                                  : 'Finestra Porta 8080: CHIUSA ✗',
                              style: AuroraPalette.headingStyle(
                                size: 10,
                                color: _portWindowOpen ? AuroraPalette.mint : const Color(0xFFF43F5E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveExplanationCard() {
    if (!_useDockerMode) {
      return AuroraGlassCard(
        accentColor: const Color(0xFFF43F5E),
        highlightBorder: true,
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PERCHÉ SENZA DOCKER IL PROGRAMMA SI ROMPE? ("SUL MIO PC FUNZIONAVA!")',
                    style: AuroraPalette.headingStyle(size: 12, color: const Color(0xFFF43F5E)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Immagina di aver preparato una torta perfetta a casa tua usando il tuo forno speciale e i tuoi ingredienti. '
              'Se mandi a un amico SOLO il foglietto della ricetta (il file del tuo programma), ma nella sua cucina '
              'manca il lievito giusto o il forno ha una temperatura diversa (versione di Python o Windows/Linux differente), '
              'il programma va in CRASH appena prova ad avviarlo!',
              style: AuroraPalette.bodyStyle(size: 12, color: Colors.white.withOpacity(0.92)),
            ),
          ],
        ),
      );
    }

    String title;
    String body;
    String analogy;

    switch (_currentStage) {
      case DockerStage.dockerfile:
        title = widget.isBeginnerMode
            ? 'PASSO ① // LA RICETTA COMPLETA (IL FILE "Dockerfile")'
            : 'STEP ① // DOCKERFILE SPECIFICATION';
        body = widget.isBeginnerMode
            ? 'Invece di mandare il programma da solo, scriviamo un piccolo biglietto di 5 righe chiamato "Dockerfile". '
                'In questo biglietto elenchiamo tutti gli ingredienti esatti: quale sistema usare, quali librerie installare e dove copiare la nostra App.'
            : 'Il Dockerfile definisce in modo dichiarativo e riproducibile l\'ambiente di esecuzione: immagine base (FROM), dipendenze di sistema (RUN), file applicativi (COPY) e comando di avvio (CMD).';
        analogy = '💡 È come scrivere la lista precisa di ogni singolo ingrediente E dell\'attrezzatura da mettere nella scatola.';
        break;
      case DockerStage.buildImage:
        title = widget.isBeginnerMode
            ? 'PASSO ② // LO STAMPO SIGILLATO ("Docker Image")'
            : 'STEP ② // DOCKER BUILD & IMMUTABLE LAYERED IMAGE';
        body = widget.isBeginnerMode
            ? 'Con il comando "docker build", Docker legge la ricetta e costruisce un Pacco Sigillato a strati chiamato IMMAGINE (Image). '
                'Dentro questo pacco ci sono SIA la tua App SIA la versione esatta di Python e delle librerie, congelate e pronte all\'uso!'
            : 'Il motore esegue il build creando un file system stratificato (UnionFS) a sola lettura. Ogni istruzione genera un layer con hash SHA-256 riutilizzabile nella cache.';
        analogy = '💡 È come surgelare la pizza già pronta col suo vassoio: non può più rovinarsi durante il trasporto!';
        break;
      case DockerStage.registry:
        title = widget.isBeginnerMode
            ? 'PASSO ③ // IL MAGAZZINO MONDIALE ("Docker Hub")'
            : 'STEP ③ // CONTAINER REGISTRY (PUSH / PULL)';
        body = widget.isBeginnerMode
            ? 'Ora carichiamo il nostro pacco sigillato su un magazzino online chiamato Docker Hub (proprio come si carica un codice su GitHub o un video su YouTube). '
                'Chiunque nel mondo (o qualsiasi server Cloud) può scaricare il pacco identico con un solo comando!'
            : 'L\'immagine OCI viene distribuita su un Container Registry (Docker Hub, GHCR, Google Artifact Registry). I server di produzione scaricano (docker pull) solo i layer mancanti.';
        analogy = '💡 È il porto commerciale dove i container navali standardizzati vengono spediti verso qualsiasi nave del mondo.';
        break;
      case DockerStage.runHost:
        title = widget.isBeginnerMode
            ? 'PASSO ④ // LA SCATOLA VIVA IN AZIONE ("Docker Container")'
            : 'STEP ④ // CONTAINER RUNTIME, ISOLAMENTO & PORT MAPPING';
        body = widget.isBeginnerMode
            ? 'Con "docker run", il server apre lo stampo e accende uno o più CONTAINER: sono scatole vive e isolate che girano alla massima velocità! '
                'Anche se sul server ci sono 3 scatole diverse accese insieme, non si danno mai fastidio tra loro.'
            : 'Il runtime avvia processi isolati tramite Linux Namespaces e cgroups condividendo il kernel dell\'host, esponendo i servizi tramite Port Forwarding (-p 8080:80).';
        analogy = '💡 Dall\'unico stampo (Image) puoi accendere 1, 2 o 100 scatole gemelle (Container) in meno di un secondo!';
        break;
    }

    return AuroraGlassCard(
      accentColor: _dockerBlue,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AuroraPalette.headingStyle(size: 12, color: _dockerCyan),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: AuroraPalette.bodyStyle(size: 12, color: Colors.white.withOpacity(0.93)),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _dockerBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _dockerBlue.withOpacity(0.35)),
            ),
            child: Text(
              analogy,
              style: AuroraPalette.headingStyle(size: 11, color: AuroraPalette.mint),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COLONNA DESTRA: 3 SCHEDE DIDATTICHE PER CHI PARTE DA ZERO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRightEducationalPanel() {
    final tabs = [
      (0, Icons.compare_arrows_rounded, '🌱 1. PERCHÉ DOCKER?'),
      (1, Icons.layers_rounded, '🧱 2. STRATI & PORTE'),
      (2, Icons.terminal_rounded, '💻 3. I 4 COMANDI'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: tabs.map((t) {
              final bool active = _rightTabIndex == t.$1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => setState(() => _rightTabIndex = t.$1),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      decoration: BoxDecoration(
                        color: active ? _dockerBlue.withOpacity(0.22) : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? _dockerCyan : Colors.white12,
                          width: active ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t.$2, size: 15, color: active ? _dockerCyan : Colors.white70),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              t.$3,
                              style: AuroraPalette.headingStyle(
                                size: 10.5,
                                color: active ? _dockerCyan : Colors.white70,
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
            }).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _rightTabIndex == 0
                ? _buildTab1WhyDockerAndVmComparison()
                : (_rightTabIndex == 1
                    ? _buildTab2LayersAndPortsInspector()
                    : _buildTab3CommandsAndDockerfile()),
          ),
        ],
      ),
    );
  }

  // ── TAB 1: LA METAFORA DEI CONTAINER NAVALI + VM vs CONTAINER ──
  Widget _buildTab1WhyDockerAndVmComparison() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuroraGlassCard(
            accentColor: _dockerBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚢 LA METAFORA DEL CONTAINER NAVALE (SPIEGATA DA ZERO)',
                  style: AuroraPalette.headingStyle(size: 13, color: _dockerCyan),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prima del 1950, caricare una nave era un incubo: sacchi di caffè, barili di vino e casse di legno avevano tutti forme diverse e si rompevano.\n'
                  'Poi hanno inventato il CONTAINER METALLICO STANDARD: non importa cosa ci metti dentro (un\'auto, vestiti o computer), '
                  'ogni gru, treno o nave del mondo può spostarlo a occhi chiusi!\n\n'
                  '👉 Docker fa la stessa identica cosa per i programmi: chiude il tuo sito o la tua AI dentro una scatola digitale standard.',
                  style: AuroraPalette.bodyStyle(size: 12.5, color: Colors.white.withOpacity(0.92)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dizionario visuale delle 3 parole chiave
          AuroraGlassCard(
            accentColor: AuroraPalette.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔑 LE 3 PAROLE DI DOCKER CHE SENTIRAI SEMPRE',
                  style: AuroraPalette.headingStyle(size: 12.5, color: AuroraPalette.mint),
                ),
                const SizedBox(height: 10),
                _conceptRow(
                  badge: '1. Dockerfile',
                  humanTitle: '📜 La Ricetta scritta su carta',
                  desc: 'Un file di testo di poche righe che dice a Docker cosa mettere nella scatola.',
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(height: 8),
                _conceptRow(
                  badge: '2. Image',
                  humanTitle: '📦 Lo Stampo Sigillato (Surgelato)',
                  desc: 'Il pacchetto pronto e chiuso costruito seguendo la ricetta. Da uno stampo puoi creare infinite scatole!',
                  color: const Color(0xFFA78BFA),
                ),
                const SizedBox(height: 8),
                _conceptRow(
                  badge: '3. Container',
                  humanTitle: '🚢 La Scatola Viva e Accesa',
                  desc: 'Il programma vero e proprio mentre sta girando dentro la sua scatola protetta.',
                  color: AuroraPalette.mint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Confronto visivo: Macchina Virtuale (Villa) vs Container Docker (Appartamento)
          AuroraGlassCard(
            accentColor: AuroraPalette.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏠 MACCHINA VIRTUALE (VM) vs 🏢 CONTAINER DOCKER',
                  style: AuroraPalette.headingStyle(size: 12.5, color: AuroraPalette.amber),
                ),
                const SizedBox(height: 4),
                Text(
                  'Spesso chi inizia chiede: "Ma un Container è come una Macchina Virtuale?". Ecco la differenza:',
                  style: AuroraPalette.bodyStyle(size: 11.5, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏠 MACCHINA VIRTUALE',
                              style: AuroraPalette.headingStyle(size: 11.5, color: const Color(0xFFF43F5E)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Come costruire una VILLA INTERA da zero: per ogni app ricrea tutto un intero sistema Windows/Linux pesantissimo.',
                              style: AuroraPalette.bodyStyle(size: 11.5),
                            ),
                            const SizedBox(height: 8),
                            _statPill('Peso:', '15 - 25 GB (Pesante)', const Color(0xFFF43F5E)),
                            const SizedBox(height: 4),
                            _statPill('Avvio:', '1 - 2 Minuti 🐢', const Color(0xFFF43F5E)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AuroraPalette.mint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AuroraPalette.mint.withOpacity(0.45)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏢 CONTAINER DOCKER',
                              style: AuroraPalette.headingStyle(size: 11.5, color: AuroraPalette.mint),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Come un APPARTAMENTO in condominio: condivide le fondamenta del computer ma ha la sua porta blindata!',
                              style: AuroraPalette.bodyStyle(size: 11.5),
                            ),
                            const SizedBox(height: 8),
                            _statPill('Peso:', '50 - 120 MB (Piuma!)', AuroraPalette.mint),
                            const SizedBox(height: 4),
                            _statPill('Avvio:', '0.5 Secondi ⚡', AuroraPalette.mint),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conceptRow({
    required String badge,
    required String humanTitle,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: AuroraPalette.monoStyle(size: 10.5, color: color, weight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  humanTitle,
                  style: AuroraPalette.headingStyle(size: 12, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AuroraPalette.bodyStyle(size: 11.5, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String val, Color color) {
    return Row(
      children: [
        Text(label, style: AuroraPalette.bodyStyle(size: 10.5, color: Colors.white70)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            val,
            style: AuroraPalette.monoStyle(size: 10.5, color: color, weight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── TAB 2: LA TORTA A STRATI (LAYERS) + FINESTRE (PORTE) & CASSETTI (VOLUMI) ──
  Widget _buildTab2LayersAndPortsInspector() {
    final selected = _layers[_selectedLayerIdx];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuroraGlassCard(
            accentColor: _dockerBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎂 LA SCATOLA È FATTA A STRATI (CLICCA UNO STRATO!)',
                  style: AuroraPalette.headingStyle(size: 12.5, color: _dockerCyan),
                ),
                const SizedBox(height: 4),
                Text(
                  'Docker costruisce il pacchetto impilando 4 strati uno sopra l\'altro. Se cambi solo il tuo codice (Strato 3), Docker non riscarica gli strati sotto: risparmia tempo prezioso!',
                  style: AuroraPalette.bodyStyle(size: 11.5, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                // Visualizzazione dal più alto (Strato 4) alla base (Strato 1)
                ..._layers.reversed.map((layer) {
                  final int idx = layer.index - 1;
                  final bool isSel = _selectedLayerIdx == idx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: InkWell(
                      onTap: () => setState(() => _selectedLayerIdx = idx),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel ? layer.color.withOpacity(0.22) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? layer.color : layer.color.withOpacity(0.35),
                            width: isSel ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSel ? Icons.radio_button_checked : Icons.layers_outlined,
                              size: 16,
                              color: layer.color,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isBeginnerMode ? layer.simpleName : layer.techName,
                                    style: AuroraPalette.headingStyle(size: 11.5, color: Colors.white),
                                  ),
                                  Text(
                                    layer.dockerfileLine.replaceAll('\n', ' · '),
                                    style: AuroraPalette.monoStyle(size: 10.5, color: layer.color),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                layer.sizeLabel,
                                style: AuroraPalette.monoStyle(size: 10, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: selected.color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected.color.withOpacity(0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 COSA FA QUESTO STRATO:',
                        style: AuroraPalette.headingStyle(size: 11, color: selected.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selected.simpleDesc,
                        style: AuroraPalette.bodyStyle(size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Finestre (Port Mapping) e Cassetti (Volumes)
          AuroraGlassCard(
            accentColor: AuroraPalette.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🪟 SE LA SCATOLA È CHIUSA, COME CI PARLIAMO?',
                  style: AuroraPalette.headingStyle(size: 12.5, color: AuroraPalette.mint),
                ),
                const SizedBox(height: 8),
                _conceptRow(
                  badge: '-p 8080:80',
                  humanTitle: '🪟 Le Porte (Port Mapping) = La Finestra',
                  desc:
                      'Di base un Container è chiuso a chiave. Con "-p 8080:80" apriamo una finestra che collega la porta 8080 del tuo PC alla porta 80 dentro la scatola! Prova a chiuderla sul canvas a sinistra.',
                  color: AuroraPalette.mint,
                ),
                const SizedBox(height: 8),
                _conceptRow(
                  badge: '-v /dati:/app',
                  humanTitle: '🗄️ I Volumi (Volumes) = Il Cassetto Esterno',
                  desc:
                      'Quando spegni un Container, tutto quello che aveva scritto sulla sua lavagna interna si cancella. Un Volume collega una cartella vera del tuo PC alla scatola, così i dati importanti restano salvati per sempre!',
                  color: AuroraPalette.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: I 4 COMANDI FONDAMENTALI & IL DOCKERFILE COPIABILE ──
  Widget _buildTab3CommandsAndDockerfile() {
    const String dockerfileSample = '''# 1. Scegliamo il sistema base con Python 3.11 già pronto
FROM python:3.11-slim

# 2. Creiamo la cartella di lavoro dentro la scatola
WORKDIR /app

# 3. Installiamo le librerie (es. Gemini AI e server web)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copiamo il nostro programma dentro la scatola
COPY . .

# 5. Apriamo la finestra sulla porta 8080 e avviamo l'app!
EXPOSE 8080
CMD ["python", "main.py"]''';

    final commands = [
      (
        'docker build -t mia-app-ai .',
        '📦 1. Costruisci lo Stampo (Image)',
        'Legge la ricetta (Dockerfile) nella cartella attuale e crea il pacco sigillato chiamato "mia-app-ai".',
        DockerStage.buildImage,
      ),
      (
        'docker push utente/mia-app-ai',
        '☁️ 2. Spedisci sul Magazzino Cloud',
        'Carica il tuo pacco sigillato su Docker Hub così qualsiasi server può scaricarlo.',
        DockerStage.registry,
      ),
      (
        'docker run -p 8080:80 mia-app-ai',
        '🚢 3. Accendi la Scatola (Container)',
        'Avvia il programma isolato in meno di 1 secondo e apre la finestra sulla porta 8080!',
        DockerStage.runHost,
      ),
      (
        'docker compose up',
        '🎼 4. Accendi Tutta la Squadra Insieme',
        'Hai un Sito Web + un Server AI + un Database? Docker Compose accende tutte e 3 le scatole insieme e le collega tra loro!',
        DockerStage.runHost,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuroraGlassCard(
            accentColor: _dockerBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💻 I 4 COMANDI DOCKER CHE BASTANO PER IL 95% DEL LAVORO',
                  style: AuroraPalette.headingStyle(size: 12.5, color: _dockerCyan),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clicca su un comando qui sotto per vederlo subito animato sul simulatore a sinistra:',
                  style: AuroraPalette.bodyStyle(size: 11.5, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                ...commands.map((cmd) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _useDockerMode = true;
                          _currentStage = cmd.$4;
                          if (cmd.$1.contains('compose')) {
                            _activeContainersCount = 3;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _dockerBlue.withOpacity(0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    cmd.$2,
                                    style: AuroraPalette.headingStyle(size: 11.5, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _dockerBlue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '▶ Simula',
                                    style: AuroraPalette.monoStyle(size: 9.5, color: _dockerCyan),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '\$ ${cmd.$1}',
                                style: AuroraPalette.monoStyle(size: 11, color: AuroraPalette.mint),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cmd.$3,
                              style: AuroraPalette.bodyStyle(size: 11.5, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          AuroraGlassCard(
            accentColor: AuroraPalette.violet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📜 ESEMPIO REALE DI "Dockerfile" COMMENTATO',
                      style: AuroraPalette.headingStyle(size: 12, color: const Color(0xFFC4B5FD)),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: dockerfileSample));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dockerfile copiato negli appunti!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AuroraPalette.violet.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AuroraPalette.violet),
                        ),
                        child: Text(
                          'COPIA CODICE',
                          style: AuroraPalette.monoStyle(size: 9.5, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050814),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    dockerfileSample,
                    style: AuroraPalette.monoStyle(
                      size: 11,
                      color: const Color(0xFFE2E8F0),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER AD ALTE PRESTAZIONI (0 MaskFilter.blur · 0 TextPainter.layout)
// ─────────────────────────────────────────────────────────────────────────────
class _DockerFlowPainter extends CustomPainter {
  final Animation<double> animCtrl;
  final bool useDockerMode;
  final DockerStage stage;
  final bool isBeginnerMode;
  final int activeContainersCount;
  final bool portWindowOpen;

  _DockerFlowPainter({
    required this.animCtrl,
    required this.useDockerMode,
    required this.stage,
    required this.isBeginnerMode,
    required this.activeContainersCount,
    required this.portWindowOpen,
  }) : super(repaint: animCtrl);

  double get phase => animCtrl.value;

  @override
  void paint(Canvas canvas, Size size) {
    FastCanvasEffects.drawSubtleTechGrid(
      canvas,
      size,
      color: const Color(0xFF38BDF8).withOpacity(0.04),
      spacing: 32,
    );

    if (!useDockerMode) {
      _paintWithoutDockerScenario(canvas, size);
    } else {
      _paintWithDockerPipeline(canvas, size);
    }
  }

  // ── SCENARIO 1: SENZA DOCKER ("SUL MIO PC FUNZIONA, SUL SERVER CRASHA!") ──
  void _paintWithoutDockerScenario(Canvas canvas, Size size) {
    final double cy = size.height * 0.52;
    final Offset devPc = Offset(size.width * 0.24, cy);
    final Offset prodServer = Offset(size.width * 0.76, cy);

    TextLayoutCache.paintBadge(
      canvas,
      text: '❌ SENZA DOCKER: SPEDISCI SOLO IL CODICE SENza LE SUE LIBRERIE',
      center: Offset(size.width * 0.5, 24),
      textColor: const Color(0xFFF43F5E),
      borderColor: const Color(0xFFF43F5E).withOpacity(0.65),
      fontSize: 10.5,
    );

    // Linea di spedizione che si interrompe con errore a metà strada
    final Paint linePaint = Paint()
      ..color = const Color(0xFFF43F5E).withOpacity(0.45)
      ..strokeWidth = 2.5;
    canvas.drawLine(devPc, prodServer, linePaint);

    // Pacchetto "Solo app.py" che viaggia e va in crash sul server
    final double t = phase;
    final Offset pktPos = Offset.lerp(devPc, prodServer, t)!;
    final bool crashed = t > 0.68;

    TextLayoutCache.paintBadge(
      canvas,
      text: crashed ? '💥 ERRORE: Manca Python 3.11!' : '📄 Solo file: app.py (Nudo)',
      center: pktPos.translate(0, -24),
      textColor: crashed ? const Color(0xFFF43F5E) : AuroraPalette.amber,
      borderColor: crashed ? const Color(0xFFF43F5E) : AuroraPalette.amber,
      fontSize: 10.5,
    );
    FastCanvasEffects.drawSoftGlowCircle(
      canvas,
      pktPos,
      6.0,
      crashed ? const Color(0xFFF43F5E) : AuroraPalette.amber,
      intensity: 0.9,
      rings: 2,
    );
    canvas.drawCircle(
      pktPos,
      5.0,
      Paint()..color = crashed ? const Color(0xFFF43F5E) : AuroraPalette.amber,
    );

    // Box 1: Il Tuo PC (Tutto funziona)
    _drawBoxNode(
      canvas,
      center: devPc,
      width: 190,
      height: 122,
      title: '💻 1. IL TUO COMPUTER',
      line1: '✅ Python 3.11 Installato',
      line2: '✅ Librerie AI Presenti',
      footer: '"Sul mio PC funziona! ✓"',
      color: AuroraPalette.mint,
      highlighted: true,
    );

    // Box 2: Il Server o PC del Collega (Ambiente diverso -> Crash!)
    _drawBoxNode(
      canvas,
      center: prodServer,
      width: 198,
      height: 122,
      title: '☁️ 2. SERVER / ALTRO PC',
      line1: '❌ Ha un vecchio Python 3.7',
      line2: '❌ Mancano le Librerie AI',
      footer: '💥 CRASH ALL\'AVVIO!',
      color: const Color(0xFFF43F5E),
      highlighted: true,
    );
  }

  // ── SCENARIO 2: CON DOCKER (I 4 PASSI DALLA RICETTA AI CONTAINER VIVI) ──
  void _paintWithDockerPipeline(Canvas canvas, Size size) {
    final double cy = size.height * 0.46;
    final Offset p1 = Offset(size.width * 0.13, cy);
    final Offset p2 = Offset(size.width * 0.36, cy);
    final Offset p3 = Offset(size.width * 0.59, cy);
    final Offset p4 = Offset(size.width * 0.84, cy);

    TextLayoutCache.paintBadge(
      canvas,
      text: isBeginnerMode
          ? '✅ CON DOCKER: RICETTA ➔ STAMPO SIGILLATO ➔ MAGAZZINO CLOUD ➔ SCATOLE VIVE'
          : '✅ DOCKER PIPELINE: DOCKERFILE ➔ IMAGE (LAYERS) ➔ REGISTRY ➔ HOST CONTAINERS',
      center: Offset(size.width * 0.5, 22),
      textColor: const Color(0xFF38BDF8),
      borderColor: const Color(0xFF38BDF8).withOpacity(0.55),
      fontSize: 10.0,
    );

    // Connessioni tra le 4 stazioni
    final Paint trackPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.28)
      ..strokeWidth = 2.4;
    canvas.drawLine(p1, p2, trackPaint);
    canvas.drawLine(p2, p3, trackPaint);
    canvas.drawLine(p3, p4, trackPaint);

    // Etichette comandi sulle frecce
    TextLayoutCache.paintCentered(
      canvas,
      text: 'docker build ➔',
      center: Offset((p1.dx + p2.dx) * 0.5, cy - 58),
      fontSize: 10,
      color: const Color(0xFF38BDF8),
      weight: FontWeight.bold,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: 'docker push ➔',
      center: Offset((p2.dx + p3.dx) * 0.5, cy - 58),
      fontSize: 10,
      color: const Color(0xFFA78BFA),
      weight: FontWeight.bold,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: 'docker run ➔',
      center: Offset((p3.dx + p4.dx) * 0.5, cy - 58),
      fontSize: 10,
      color: AuroraPalette.mint,
      weight: FontWeight.bold,
    );

    // 1. Stazione 1: Dockerfile (La Ricetta)
    _drawBoxNode(
      canvas,
      center: p1,
      width: 132,
      height: 102,
      title: isBeginnerMode ? '① LA RICETTA' : '① DOCKERFILE',
      line1: 'FROM python:3.11',
      line2: 'RUN pip install...',
      footer: 'COPY app / CMD',
      color: const Color(0xFF38BDF8),
      highlighted: stage == DockerStage.dockerfile,
    );

    // 2. Stazione 2: Docker Image (Lo Stampo a 4 Strati)
    _drawLayeredImageNode(
      canvas,
      center: p2,
      highlighted: stage == DockerStage.buildImage,
    );

    // 3. Stazione 3: Docker Hub Registry
    _drawBoxNode(
      canvas,
      center: p3,
      width: 132,
      height: 102,
      title: isBeginnerMode ? '③ MAGAZZINO' : '③ DOCKER HUB',
      line1: '☁️ Cloud Registry',
      line2: 'Pacco Sigillato',
      footer: 'Pronto al Download',
      color: const Color(0xFFA78BFA),
      highlighted: stage == DockerStage.registry,
    );

    // 4. Stazione 4: Server Host con 1..3 Container isolati + Finestra Porta 8080
    _drawHostWithContainers(
      canvas,
      center: p4,
      highlighted: stage == DockerStage.runHost,
    );

    // Impulso animato lungo il segmento attivo
    Offset startP = p1;
    Offset endP = p2;
    Color pulseCol = const Color(0xFF38BDF8);
    if (stage == DockerStage.registry) {
      startP = p2;
      endP = p3;
      pulseCol = const Color(0xFFA78BFA);
    } else if (stage == DockerStage.runHost) {
      startP = p3;
      endP = p4;
      pulseCol = AuroraPalette.mint;
    }
    final Offset moving = Offset.lerp(startP, endP, phase)!;
    FastCanvasEffects.drawSoftGlowCircle(canvas, moving, 5.5, pulseCol, intensity: 0.9, rings: 2);
    canvas.drawCircle(moving, 4.0, Paint()..color = Colors.white);
  }

  void _drawLayeredImageNode(
    Canvas canvas, {
    required Offset center,
    required bool highlighted,
  }) {
    const double w = 138;
    const double h = 104;
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(11),
    );
    const Color col = Color(0xFF00F0FF);
    if (highlighted) {
      FastCanvasEffects.drawSoftGlowRRect(canvas, rect, col, intensity: 0.95);
    }
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF0A1024));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = highlighted ? col : col.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2.1 : 1.2,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: isBeginnerMode ? '② STAMPO IMAGE' : '② DOCKER IMAGE',
      center: center.translate(0, -36),
      fontSize: 10.5,
      color: col,
      weight: FontWeight.bold,
    );

    // 3 strati colorati impilati dentro lo stampo
    final layers = [
      ('3. La Tua App', const Color(0xFF34D399), -14.0),
      ('2. Librerie AI', const Color(0xFF818CF8), 6.0),
      ('1. Base Linux', const Color(0xFF38BDF8), 26.0),
    ];

    for (final l in layers) {
      final RRect lr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, l.$3), width: w - 20, height: 16),
        const Radius.circular(4),
      );
      canvas.drawRRect(lr, Paint()..color = l.$2.withOpacity(0.22));
      canvas.drawRRect(
        lr,
        Paint()
          ..color = l.$2.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      TextLayoutCache.paintCentered(
        canvas,
        text: l.$1,
        center: center.translate(0, l.$3),
        fontSize: 9.2,
        color: Colors.white,
        weight: FontWeight.bold,
      );
    }
  }

  void _drawHostWithContainers(
    Canvas canvas, {
    required Offset center,
    required bool highlighted,
  }) {
    const double w = 166;
    const double h = 132;
    final RRect hostRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(12),
    );
    const Color col = AuroraPalette.mint;

    if (highlighted) {
      FastCanvasEffects.drawSoftGlowRRect(canvas, hostRect, col, intensity: 0.95);
    }

    canvas.drawRRect(hostRect, Paint()..color = const Color(0xFF0A1024));
    canvas.drawRRect(
      hostRect,
      Paint()
        ..color = highlighted ? col : col.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2.1 : 1.2,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: isBeginnerMode ? '④ SERVER QUALSIASI' : '④ DOCKER HOST',
      center: center.translate(0, -50),
      fontSize: 10.5,
      color: col,
      weight: FontWeight.bold,
    );

    // Disegna da 1 a 3 Container vivi dentro il server
    for (int i = 0; i < activeContainersCount; i++) {
      final double yOff = -22.0 + i * 24.0;
      final RRect cBox = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, yOff), width: w - 22, height: 19),
        const Radius.circular(5),
      );
      canvas.drawRRect(cBox, Paint()..color = col.withOpacity(0.18));
      canvas.drawRRect(
        cBox,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      TextLayoutCache.paintCentered(
        canvas,
        text: '🚢 Container #${i + 1} · ATTIVO ✓',
        center: center.translate(0, yOff),
        fontSize: 9.3,
        color: Colors.white,
        weight: FontWeight.bold,
      );
    }

    // Stato Finestra Porta 8080
    TextLayoutCache.paintCentered(
      canvas,
      text: portWindowOpen ? '🪟 Porta 8080➔80 APERTA ✓' : '🔒 Porta 8080 CHIUSA ✗',
      center: center.translate(0, 51),
      fontSize: 9.2,
      color: portWindowOpen ? AuroraPalette.mint : const Color(0xFFF43F5E),
      weight: FontWeight.bold,
    );
  }

  void _drawBoxNode(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required String title,
    required String line1,
    required String line2,
    required String footer,
    required Color color,
    required bool highlighted,
  }) {
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(11),
    );
    if (highlighted) {
      FastCanvasEffects.drawSoftGlowRRect(canvas, rect, color, intensity: 0.9);
    }
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF0A1024));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = highlighted ? color : color.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 2.1 : 1.2,
    );

    TextLayoutCache.paintCentered(
      canvas,
      text: title,
      center: center.translate(0, -height * 0.33),
      fontSize: 10.5,
      color: color,
      weight: FontWeight.bold,
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: line1,
      center: center.translate(0, -height * 0.08),
      fontSize: 9.8,
      color: Colors.white.withOpacity(0.92),
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: line2,
      center: center.translate(0, height * 0.12),
      fontSize: 9.8,
      color: Colors.white.withOpacity(0.85),
    );
    TextLayoutCache.paintCentered(
      canvas,
      text: footer,
      center: center.translate(0, height * 0.33),
      fontSize: 9.8,
      color: color,
      weight: FontWeight.bold,
    );
  }

  @override
  bool shouldRepaint(covariant _DockerFlowPainter oldDelegate) =>
      oldDelegate.useDockerMode != useDockerMode ||
      oldDelegate.stage != stage ||
      oldDelegate.isBeginnerMode != isBeginnerMode ||
      oldDelegate.activeContainersCount != activeContainersCount ||
      oldDelegate.portWindowOpen != portWindowOpen;
}
