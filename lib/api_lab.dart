// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'core_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODULO 02 // LABORATORIO CHIAMATE API (PERFETTO PER CHI PARTE DA ZERO)
// Spiega visivamente: Cosa sono le API, Come viaggia la "Busta" (Indirizzo,
// Passaporto, Ordinazione) e Come si integrano nel codice reale.
// ─────────────────────────────────────────────────────────────────────────────

enum ApiStep {
  idle,
  clientSerialize, // 1. Il client prepara la "Busta" (Headers + Body JSON)
  networkTransit,  // 2. Viaggio nel tunnel protetto HTTPS
  gatewayAuth,     // 3. Il "Buttafuori" (API Gateway) controlla il badge API Key
  serverInference, // 4. La "Cucina AI" (Server) prepara la risposta
  responseTransit, // 5. Il "Cameriere" riporta il vassoio col bollino Status Code
  clientParsed,    // 6. L'app apre il pacco e mostra il testo pulito sullo schermo
}

enum ApiScenario {
  success200,      // 200 OK — Tutto funziona!
  unauthorized401, // 401 Unauthorized — Password/API Key sbagliata
  rateLimit429,    // 429 Too Many Requests — Troppe richieste insieme
  badRequest400,   // 400 Bad Request — Modulo compilato male (JSON rotto)
}

class ApiStepInfo {
  final int number;
  final String simpleTitle;
  final String techTitle;
  final String subtitle;
  final String simpleExplanation;
  final String academicExplanation;
  final String analogy;
  final Color color;

  const ApiStepInfo({
    required this.number,
    required this.simpleTitle,
    required this.techTitle,
    required this.subtitle,
    required this.simpleExplanation,
    required this.academicExplanation,
    required this.analogy,
    required this.color,
  });
}

const Map<ApiStep, ApiStepInfo> kApiStepDetails = {
  ApiStep.idle: ApiStepInfo(
    number: 0,
    simpleTitle: 'PRONTO A PARTIRE // COS\'È UNA CHIAMATA API?',
    techTitle: 'SISTEMA PRONTO // IN ATTESA DI CHIAMATA HTTP',
    subtitle: 'Premi il pulsante azzurro "INVIA CHIAMATA API" o "Avanza Passo ▶"',
    simpleExplanation:
        'Immagina che la tua app sul telefono o sul computer voglia usare un super-cervello AI che si trova nei computer di Google. '
        'Come fanno a parlarsi a distanza? Usano un "messaggero" chiamato API! '
        'La tua app spedisce una busta con la domanda (Request) e il computer di Google risponde con una busta che contiene la risposta (Response).',
    academicExplanation:
        'Un\'API (Application Programming Interface) è un contratto di comunicazione standardizzato tra due software: '
        'consente a un\'applicazione (Client) di richiedere dati o calcoli a una macchina remota (Server) tramite pacchetti HTTP/JSON.',
    analogy:
        '🍽️ Metafora del Ristorante: Tu al tavolo sei l\'App (Client), la cucina è il Server AI. L\'API è il CAMERIERE: '
        'prende il tuo ordine scritto sul blocchetto (Request), lo porta in cucina e ti riporta il piatto pronto (Response)!',
    color: Colors.cyanAccent,
  ),
  ApiStep.clientSerialize: ApiStepInfo(
    number: 1,
    simpleTitle: 'PASSO 1 // LA TUA APP PREPARA LA "BUSTA"',
    techTitle: 'FASE 1 // SERIALIZZAZIONE DELLA REQUEST (CLIENT)',
    subtitle: 'Si scrivono: 1) Indirizzo  2) Badge Segreto  3) La Domanda',
    simpleExplanation:
        'Prima di spedire il messaggio su Internet, la tua app infila tutto in una busta digitale ordinata: '
        'sulla busta scrive l\'indirizzo esatto del server (URL), allega il tuo tesserino di riconoscimento segreto (API Key) '
        'e dentro mette il foglio con la tua domanda scritta in un formato universale chiamato JSON.',
    academicExplanation:
        'Il Client raccoglie i parametri (prompt, temperatura) e li serializza in formato JSON nel Body della richiesta HTTP POST, '
        'aggiungendo gli Header ("Content-Type: application/json" e "x-goog-api-key").',
    analogy:
        '✉️ Come preparare una raccomandata: scrivi l\'indirizzo sul fronte (Endpoint), alleghi il documento d\'identità (API Key) e chiudi il modulo nella busta (JSON).',
    color: Color(0xFF00E5FF),
  ),
  ApiStep.networkTransit: ApiStepInfo(
    number: 2,
    simpleTitle: 'PASSO 2 // IL VIAGGIO NEL TUNNEL BLINDATO SU INTERNET',
    techTitle: 'FASE 2 // TRASMISSIONE SU TUNNEL HTTPS / TLS',
    subtitle: 'Il pacchetto viaggia protetto da lucchetto fino ai server remoti',
    simpleExplanation:
        'La busta parte dal tuo dispositivo e viaggia attraverso Internet. '
        'Per evitare che qualche curioso lungo la strada legga la tua domanda o ti rubi la chiave segreta, '
        'la busta viaggia chiusa a chiave dentro un tunnel blindato (il famoso lucchetto HTTPS dei siti web).',
    academicExplanation:
        'La richiesta viaggia sul protocollo HTTPS: il livello crittografico TLS 1.3 cifra l\'intero pacchetto (Header, API Key e Body) '
        'garantendo riservatezza e integrità tra Client e Server.',
    analogy:
        '🚚 Il furgone portavalori: nessuno per strada può aprire la cassaforte finché non arriva a destinazione.',
    color: Color(0xFF40C4FF),
  ),
  ApiStep.gatewayAuth: ApiStepInfo(
    number: 3,
    simpleTitle: 'PASSO 3 // IL "BUTTAFUORI" CONTROLLA IL TUO BADGE',
    techTitle: 'FASE 3 // API GATEWAY: AUTENTICAZIONE & RATE LIMIT',
    subtitle: 'Controllo della chiave segreta (API Key) e del numero di richieste',
    simpleExplanation:
        'Prima di far entrare la tua richiesta nel super-computer AI, c\'è una guardia all\'ingresso (API Gateway) che fa 3 controlli:\n'
        '1) Hai il badge segreto (API Key) valido? Se è falso ti rimanda indietro con il codice errore 401!\n'
        '2) Stai facendo troppe domande al secondo? Se esageri ti ferma con il codice 429!\n'
        '3) Il foglio dell\'ordine è leggibile? Se è scritto male ti dà errore 400!',
    academicExplanation:
        'L\'API Gateway valida l\'autenticazione ("x-goog-api-key" → altrimenti 401 Unauthorized), '
        'verifica le quote di utilizzo (Rate Limit → altrimenti 429 Too Many Requests) e la sintassi del JSON (altrimenti 400 Bad Request).',
    analogy:
        '🛂 Il controllo passaporti: se hai il biglietto valido entri subito; se il documento è scaduto vieni respinto al cancello.',
    color: Color(0xFFFFAB40),
  ),
  ApiStep.serverInference: ApiStepInfo(
    number: 4,
    simpleTitle: 'PASSO 4 // IL CERVELLO AI LEGGE L\'ORDINE E LAVORA',
    techTitle: 'FASE 4 // ESECUZIONE SUL SERVER (INFERENZA AI)',
    subtitle: 'Il super-computer elabora la domanda e genera la risposta',
    simpleExplanation:
        'Superato il controllo all\'ingresso, la busta arriva finalmente al cervello AI (il Server). '
        'Il Server apre la busta, legge la tua domanda e usa le sue schede grafiche (GPU) per calcolare la risposta parola per parola '
        '(proprio come hai visto nel Laboratorio 01!).',
    academicExplanation:
        'Il microservizio di inferenza estrae il campo "contents", esegue il modello neurale con i parametri "generationConfig" '
        'e produce il testo di output insieme ai contatori di utilizzo ("usageMetadata").',
    analogy:
        '👨‍🍳 Lo chef in cucina: legge la comanda approvata, cucina il piatto seguendo le tue indicazioni e lo mette sul vassoio.',
    color: Color(0xFFE040FB),
  ),
  ApiStep.responseTransit: ApiStepInfo(
    number: 5,
    simpleTitle: 'PASSO 5 // LA RISPOSTA TORNA INDIETRO COL "BOLLINO"',
    techTitle: 'FASE 5 // RITORNO DELLA HTTP RESPONSE & STATUS CODE',
    subtitle: 'Torna il pacchetto con il codice numerico (es. 200 = Tutto OK!)',
    simpleExplanation:
        'Il Server mette la risposta pronta in una nuova busta e la rispedisce verso la tua app. '
        'Fuori dalla busta attacca sempre un bollino numerico universale chiamato "Status Code":\n'
        '• 200 OK = Tutto è andato benissimo!\n'
        '• Numeri che iniziano per 4 (400, 401, 429) = Hai sbagliato qualcosa tu nella richiesta.',
    academicExplanation:
        'Il Server restituisce la HTTP Response contenente lo Status Code (200 OK o 4xx/5xx), i Response Headers e il Body JSON '
        '(o un flusso continuo di pacchetti in modalità Streaming SSE).',
    analogy:
        '🏃 Il cameriere torna al tuo tavolo portando il piatto fumante e lo scontrino che conferma che è tutto pagato (200 OK).',
    color: Color(0xFF69F0AE),
  ),
  ApiStep.clientParsed: ApiStepInfo(
    number: 6,
    simpleTitle: 'PASSO 6 // L\'APP APRE LA BUSTA E TI MOSTRA LA RISPOSTA!',
    techTitle: 'FASE 6 // DESERIALIZZAZIONE JSON & AGGIORNAMENTO UI',
    subtitle: 'Il testo viene estratto dalla busta tecnica e mostrato sullo schermo',
    simpleExplanation:
        'La busta arriva finalmente alla tua app! L\'utente però non vuole vedere codici o parentesi graffe: '
        'la tua app apre quindi la busta JSON, butta via l\'involucro tecnico, prende solo la frase di risposta '
        'e la fa apparire pulita nel fumetto della chat!',
    academicExplanation:
        'Il Client deserializza la stringa JSON ricevuta in un oggetto nativo (es. jsonDecode), '
        'legge il campo "candidates[0].content.parts[0].text" e aggiorna l\'interfaccia grafica.',
    analogy:
        '🎁 Scartare il regalo: togli la scatola di cartone e la carta da imballaggio per tenere solo l\'oggetto bello dentro.',
    color: Colors.cyanAccent,
  ),
};

class ApiLabWorkspace extends StatefulWidget {
  final GenerativeModel? geminiModel;
  final bool hasValidKey;
  final bool isBeginnerMode;

  const ApiLabWorkspace({
    super.key,
    required this.geminiModel,
    required this.hasValidKey,
    this.isBeginnerMode = true,
  });

  @override
  State<ApiLabWorkspace> createState() => _ApiLabWorkspaceState();
}

class _ApiLabWorkspaceState extends State<ApiLabWorkspace>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  final TextEditingController _promptCtrl = TextEditingController(
    text: 'Spiega in 2 frasi cos\'è un\'API a chi parte da zero.',
  );
  final double _temperature = 0.7;
  final int _maxTokens = 256;
  final bool _useStreaming = false;
  bool _useLiveGemini = false;
  ApiScenario _scenario = ApiScenario.success200;

  ApiStep _currentStep = ApiStep.idle;
  bool _isRunning = false;
  double _speedMultiplier = 1.0;

  int _statusCode = 200;
  String _statusText = '200 OK';
  int _latencyMs = 210;
  int _promptTokens = 14;
  int _completionTokens = 48;
  String _responseText =
      'Un\'API è come un cameriere digitale che porta la tua domanda dalla tua applicazione fino a un super-computer lontano e ti riporta indietro la risposta pronta in pochi millisecondi.';

  // 0 = Vista Semplice (La Busta senza codice), 1 = Ispettore JSON, 2 = Codice Integrazione, 3 = Glossario
  int _rightTabIndex = 0;
  int _codeLangIndex = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeApiCall() async {
    if (_isRunning) return;
    final sw = Stopwatch()..start();

    setState(() {
      _isRunning = true;
      _currentStep = ApiStep.clientSerialize;
    });

    final stepDelay = Duration(milliseconds: (800 / _speedMultiplier).round());

    await Future.delayed(stepDelay);
    if (!mounted) return;
    setState(() => _currentStep = ApiStep.networkTransit);

    await Future.delayed(stepDelay);
    if (!mounted) return;
    setState(() => _currentStep = ApiStep.gatewayAuth);

    await Future.delayed(stepDelay);
    if (!mounted) return;

    if (_scenario != ApiScenario.success200) {
      _applyScenarioOutcome(sw.elapsedMilliseconds);
      setState(() => _currentStep = ApiStep.responseTransit);
      await Future.delayed(stepDelay);
      if (!mounted) return;
      setState(() {
        _currentStep = ApiStep.clientParsed;
        _isRunning = false;
      });
      return;
    }

    setState(() => _currentStep = ApiStep.serverInference);

    if (_useLiveGemini && widget.geminiModel != null && widget.hasValidKey) {
      try {
        final res = await widget.geminiModel!.generateContent(
          [Content.text(_promptCtrl.text.trim())],
          generationConfig: GenerationConfig(
            temperature: _temperature,
            maxOutputTokens: _maxTokens,
          ),
        );
        if (!mounted) return;
        final txt = res.text ?? 'Risposta vuota dal modello.';
        setState(() {
          _statusCode = 200;
          _statusText = '200 OK (LIVE GEMINI)';
          _responseText = txt;
          _promptTokens = max(4, _promptCtrl.text.trim().split(' ').length + 3);
          _completionTokens = max(6, txt.split(' ').length + 4);
          _latencyMs = sw.elapsedMilliseconds;
        });
      } catch (e) {
        if (!mounted) return;
        _applyScenarioOutcome(sw.elapsedMilliseconds);
      }
    } else {
      await Future.delayed(stepDelay);
      if (!mounted) return;
      _applyScenarioOutcome(sw.elapsedMilliseconds);
    }

    setState(() => _currentStep = ApiStep.responseTransit);
    await Future.delayed(stepDelay);
    if (!mounted) return;

    setState(() {
      _currentStep = ApiStep.clientParsed;
      _isRunning = false;
    });
  }

  void _applyScenarioOutcome(int elapsedMs) {
    final promptWords = _promptCtrl.text.trim().isEmpty
        ? 5
        : _promptCtrl.text.trim().split(RegExp(r'\s+')).length;
    switch (_scenario) {
      case ApiScenario.success200:
        _statusCode = 200;
        _statusText = '200 OK';
        _latencyMs = max(180, elapsedMs);
        _promptTokens = (promptWords * 1.3).round();
        _responseText = _generateSimulatedAnswer(_promptCtrl.text.trim());
        _completionTokens = (_responseText.split(' ').length * 1.3).round();
        break;
      case ApiScenario.unauthorized401:
        _statusCode = 401;
        _statusText = '401 UNAUTHORIZED';
        _latencyMs = 42;
        _promptTokens = 0;
        _completionTokens = 0;
        _responseText =
            'Accesso negato dal Buttafuori (API Gateway): la tua chiave segreta (API Key) è mancante o sbagliata!';
        break;
      case ApiScenario.rateLimit429:
        _statusCode = 429;
        _statusText = '429 TOO MANY REQUESTS';
        _latencyMs = 55;
        _promptTokens = 0;
        _completionTokens = 0;
        _responseText =
            'Troppe richieste! Hai superato il limite massimo di domande al minuto consentite dal tuo abbonamento.';
        break;
      case ApiScenario.badRequest400:
        _statusCode = 400;
        _statusText = '400 BAD REQUEST';
        _latencyMs = 38;
        _promptTokens = 0;
        _completionTokens = 0;
        _responseText =
            'Modulo d\'ordine illeggibile: il pacchetto JSON inviato contiene un errore di scrittura ("contenuti_errati" invece di "contents").';
        break;
    }
  }

  String _generateSimulatedAnswer(String prompt) {
    if (prompt.isEmpty) {
      return 'Scrivi una domanda nel campo qui sopra per vedere come viaggia nella busta API.';
    }
    return 'Ecco la risposta del Server AI alla tua domanda ("$prompt"), '
        'elaborata con livello di fantasia ${_temperature.toStringAsFixed(1)} e rispedita col bollino 200 OK!';
  }

  void _stepForward() {
    const order = ApiStep.values;
    int idx = order.indexOf(_currentStep);
    if (idx < order.length - 1) {
      int nextIdx = idx + 1;
      if (_currentStep == ApiStep.gatewayAuth && _scenario != ApiScenario.success200) {
        _applyScenarioOutcome(48);
        nextIdx = order.indexOf(ApiStep.responseTransit);
      } else if (order[nextIdx] == ApiStep.serverInference) {
        _applyScenarioOutcome(310);
      }
      setState(() => _currentStep = order[nextIdx]);
    } else {
      setState(() => _currentStep = ApiStep.clientSerialize);
    }
  }

  void _stepBackward() {
    const order = ApiStep.values;
    int idx = order.indexOf(_currentStep);
    if (idx > 0) {
      setState(() => _currentStep = order[idx - 1]);
    }
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
            Container(width: 1, color: Colors.cyan.withOpacity(0.2)),
            Expanded(flex: 10, child: _buildRightInspectorPanel(true)),
          ],
        );
      } else {
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildLeftVisualPanel(false),
              Container(height: 1, color: Colors.cyan.withOpacity(0.2)),
              _buildRightInspectorPanel(false),
            ],
          ),
        );
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PANNELLO SINISTRO: VISUALIZZATORE DI FLUSSO + GUIDA PASSO-PASSO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLeftVisualPanel(bool wide) {
    final stepInfo = kApiStepDetails[_currentStep]!;
    return Container(
      padding: EdgeInsets.all(wide ? 20 : 14),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF0E192D), Color(0xFF06060F)],
          radius: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // I 3 Pilastri spiegati in modo semplicissimo
          _buildAcademicPillarsBar(),
          const SizedBox(height: 10),

          // Canvas Animato del flusso Client -> HTTPS -> Gateway -> Server
          if (wide)
            Expanded(child: _buildAnimatedFlowCanvas())
          else
            SizedBox(height: 300, child: _buildAnimatedFlowCanvas()),

          const SizedBox(height: 10),

          // Stepper interattivo a 6 fasi + controlli di riproduzione
          _buildStepControlsBar(),
          const SizedBox(height: 10),

          // Box Spiegazione + Metafora del Ristorante dello step corrente
          _buildStepExplanationCard(stepInfo),
        ],
      ),
    );
  }

  Widget _buildAcademicPillarsBar() {
    return Row(
      children: [
        _pillarChip(
          icon: Icons.restaurant_menu,
          title: '1. COS\'È UN\'API?',
          desc: 'È il "cameriere" che porta domande e risposte tra due programmi',
          color: Colors.cyanAccent,
          onTap: () => setState(() => _rightTabIndex = 0),
        ),
        const SizedBox(width: 8),
        _pillarChip(
          icon: Icons.mail_outline,
          title: '2. COSA C\'È NELLA BUSTA?',
          desc: 'Indirizzo (URL) + Badge Segreto (API Key) + Domanda (JSON)',
          color: const Color(0xFFB388FF),
          onTap: () => setState(() => _rightTabIndex = 0),
        ),
        const SizedBox(width: 8),
        _pillarChip(
          icon: Icons.code,
          title: '3. COME SI USA NEL CODICE?',
          desc: 'Bastano 10 righe in Python, JS o Flutter (Clicca per vederle)',
          color: const Color(0xFF69F0AE),
          onTap: () => setState(() => _rightTabIndex = 2),
        ),
      ],
    );
  }

  Widget _pillarChip({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceMono(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildAnimatedFlowCanvas() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF050711),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.06), blurRadius: 18),
        ],
      ),
      child: Stack(
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ApiFlowPainter(
                animCtrl: _animCtrl,
                currentStep: _currentStep,
                scenario: _scenario,
                isStreaming: _useStreaming,
                isBeginnerMode: widget.isBeginnerMode,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.isBeginnerMode ? 'INVIO ORDINE (POST)' : 'POST',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF00E5FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isBeginnerMode
                        ? 'Indirizzo Server Google: .../models/gemini-2.5-flash'
                        : 'generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: _buildStatusBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color col = _statusCode == 200
        ? const Color(0xFF69F0AE)
        : (_statusCode >= 400 ? const Color(0xFFFF5252) : Colors.amberAccent);
    String beginnerLabel = _statusCode == 200
        ? '200 TUTTO OK ✓'
        : (_statusCode == 401
            ? '401 CHIAVE ERRATA ✗'
            : (_statusCode == 429 ? '429 TROPPE RICHIESTE ⏳' : '400 ORDINE ERRATO ✗'));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.82),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            widget.isBeginnerMode ? 'ESITO: $beginnerLabel' : 'HTTP $_statusText',
            style: GoogleFonts.spaceMono(
              color: col,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_latencyMs > 0) ...[
            const SizedBox(width: 8),
            Text(
              '(${_latencyMs}ms)',
              style: GoogleFonts.spaceMono(
                color: Colors.white70,
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepControlsBar() {
    const steps = [
      ApiStep.clientSerialize,
      ApiStep.networkTransit,
      ApiStep.gatewayAuth,
      ApiStep.serverInference,
      ApiStep.responseTransit,
      ApiStep.clientParsed,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: steps.map((s) {
              final info = kApiStepDetails[s]!;
              final bool isCurrent = _currentStep == s;
              final bool isPassed = ApiStep.values.indexOf(_currentStep) > ApiStep.values.indexOf(s);
              return InkWell(
                onTap: () => setState(() => _currentStep = s),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? info.color.withOpacity(0.25)
                        : (isPassed
                            ? info.color.withOpacity(0.10)
                            : Colors.white.withOpacity(0.06)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent
                          ? info.color
                          : (isPassed ? info.color.withOpacity(0.45) : Colors.white24),
                    ),
                  ),
                  child: Text(
                    'Passo ${info.number}',
                    style: GoogleFonts.spaceMono(
                      color: isCurrent
                          ? info.color
                          : (isPassed ? Colors.white : Colors.white70),
                      fontSize: 10.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _smallActionBtn(
                icon: Icons.skip_previous,
                label: 'Indietro',
                onTap: _isRunning ? null : _stepBackward,
              ),
              const SizedBox(width: 6),
              _smallActionBtn(
                icon: Icons.skip_next,
                label: 'Avanza Passo ▶',
                onTap: _isRunning ? null : _stepForward,
                highlight: true,
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _speedMultiplier = _speedMultiplier == 1.0 ? 0.45 : 1.0;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _speedMultiplier < 1.0
                        ? Colors.amber.withOpacity(0.22)
                        : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _speedMultiplier < 1.0 ? Colors.amberAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    _speedMultiplier < 1.0 ? '🐢 RALLENTATORE ATTIVO' : '⚡ VELOCITÀ NORMALE',
                    style: GoogleFonts.spaceMono(
                      color: _speedMultiplier < 1.0 ? Colors.amberAccent : Colors.white,
                      fontSize: 10.5,
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

  Widget _smallActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool highlight = false,
  }) {
    final Color col = highlight ? Colors.cyanAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlight ? Colors.cyanAccent.withOpacity(0.15) : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: col.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: col),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.spaceMono(color: col, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepExplanationCard(ApiStepInfo info) {
    final title = widget.isBeginnerMode ? info.simpleTitle : info.techTitle;
    final explanation = widget.isBeginnerMode ? info.simpleExplanation : info.academicExplanation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.68),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: info.color.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceMono(
                    color: info.color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: info.color.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: info.color, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.analogy,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
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

  // ───────────────────────────────────────────────────────────────────────────
  // PANNELLO DESTRO: PROVA LA CHIAMATA + VISTA BUSTA SEMPLICE / JSON / CODICE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRightInspectorPanel(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 20 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestBuilderCard(),
          const SizedBox(height: 10),
          _buildRightTabBar(),
          const SizedBox(height: 10),
          if (wide)
            Expanded(child: _buildSelectedTabContent())
          else
            SizedBox(height: 520, child: _buildSelectedTabContent()),
        ],
      ),
    );
  }

  Widget _buildRequestBuilderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.isBeginnerMode
                      ? '① PROVA TU: SCRIVI L\'ORDINE E PREMI "INVIA CHIAMATA API"'
                      : 'COSTRUTTORE CHIAMATA API (REQUEST BUILDER)',
                  style: GoogleFonts.spaceMono(
                    color: Colors.cyanAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _useLiveGemini = !_useLiveGemini),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _useLiveGemini
                        ? const Color(0xFF69F0AE).withOpacity(0.18)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _useLiveGemini ? const Color(0xFF69F0AE) : Colors.white38,
                    ),
                  ),
                  child: Text(
                    _useLiveGemini ? '● GEMINI VERO ATTIVO' : '○ MODALITÀ SIMULATA',
                    style: GoogleFonts.spaceMono(
                      color: _useLiveGemini ? const Color(0xFF69F0AE) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: widget.isBeginnerMode
                        ? 'Cosa vuoi chiedere al Server AI?'
                        : 'Payload JSON -> contents[0].parts[0].text',
                    labelStyle: TextStyle(color: Colors.cyanAccent.withOpacity(0.85), fontSize: 11.5),
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
                onPressed: _isRunning ? null : _executeApiCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.22),
                  foregroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  side: const BorderSide(color: Colors.cyanAccent, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(_isRunning ? Icons.hourglass_top : Icons.send, size: 17),
                label: Text(
                  _isRunning ? 'IN VIAGGIO...' : 'INVIA CHIAMATA API',
                  style: GoogleFonts.spaceMono(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.isBeginnerMode ? 'Prova a simulare cosa succede se:' : 'Simula Status HTTP:',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
              ),
              _scenarioChip(
                ApiScenario.success200,
                widget.isBeginnerMode ? '✅ Tutto Giusto (200)' : '200 OK',
                const Color(0xFF69F0AE),
              ),
              _scenarioChip(
                ApiScenario.unauthorized401,
                widget.isBeginnerMode ? '❌ Password Errata (401)' : '401 Auth',
                const Color(0xFFFF5252),
              ),
              _scenarioChip(
                ApiScenario.rateLimit429,
                widget.isBeginnerMode ? '⏳ Troppe Domande (429)' : '429 Quota',
                Colors.amberAccent,
              ),
              _scenarioChip(
                ApiScenario.badRequest400,
                widget.isBeginnerMode ? '⚠️ Ordine Scritto Male (400)' : '400 JSON',
                Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scenarioChip(ApiScenario sc, String label, Color col) {
    final bool selected = _scenario == sc;
    return InkWell(
      onTap: () {
        setState(() {
          _scenario = sc;
          _applyScenarioOutcome(_latencyMs > 0 ? _latencyMs : 120);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? col.withOpacity(0.25) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? col : Colors.white24),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            color: selected ? col : Colors.white70,
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRightTabBar() {
    final tabs = [
      (Icons.mail_lock_outlined, '🌱 1. BUSTA SEMPLICE'),
      (Icons.data_object, '2. PACCHETTO JSON'),
      (Icons.terminal, '3. CODICE PRONTO'),
      (Icons.menu_book_outlined, '4. DIZIONARIO'),
    ];
    return Row(
      children: List.generate(tabs.length, (i) {
        final bool active = _rightTabIndex == i;
        final Color col = i == 0 ? const Color(0xFF69F0AE) : Colors.cyanAccent;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 6.0 : 0),
            child: InkWell(
              onTap: () => setState(() => _rightTabIndex = i),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: active ? col.withOpacity(0.2) : Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? col : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$1, size: 15, color: active ? col : Colors.white70),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        tabs[i].$2,
                        style: GoogleFonts.spaceMono(
                          color: active ? col : Colors.white,
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

  Widget _buildSelectedTabContent() {
    switch (_rightTabIndex) {
      case 0:
        return _buildBeginnerEnvelopeVisualizer();
      case 1:
        return _buildHttpJsonInspector();
      case 2:
        return _buildCodeIntegrationTab();
      default:
        return _buildApiGlossaryTab();
    }
  }

  // ── TAB 0 (NUOVA!): Visualizzatore "Senza Codice" della Busta API per chi parte da 0 ──
  Widget _buildBeginnerEnvelopeVisualizer() {
    final bool isOk = _statusCode == 200;
    final Color statusCol = isOk ? const Color(0xFF69F0AE) : const Color(0xFFFF5252);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.35)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📬 COSA VIAGGIA DAVVERO DENTRO UNA CHIAMATA API? (TRADUZIONE UMANA ↔ COMPUTER)',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF69F0AE),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Anche se i programmatori usano paroloni inglesi (Endpoint, Header, JSON), ogni chiamata API del mondo '
              'è fatta semplicemente da questi 3 pezzi in andata + 1 pezzo di ritorno:',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 12),

            _envelopePieceCard(
              stepNumber: 'PEZZO 1 (SULLA BUSTA)',
              humanTitle: '📍 L\'Indirizzo del Ristorante a cui bussi',
              techName: 'Si chiama: ENDPOINT URL + METODO POST',
              humanMeaning: 'Dice a Internet esattamente a quale computer di Google consegnare la busta e che stai inviando una domanda ("POST").',
              computerString: 'POST https://generativelanguage.googleapis.com/.../gemini-2.5-flash:generateContent',
              color: Colors.cyanAccent,
            ),
            const SizedBox(height: 10),

            _envelopePieceCard(
              stepNumber: 'PEZZO 2 (IL BADGE D\'INGRESSO)',
              humanTitle: '🪪 Il tuo Passaporto Segreto per farti aprire',
              techName: 'Si chiama: HEADER HTTP & API KEY',
              humanMeaning: _scenario == ApiScenario.unauthorized401
                  ? '⚠️ Hai messo una chiave sbagliata! Il buttafuori (API Gateway) bloccherà la busta con Errore 401.'
                  : 'È il codice segreto che dimostra a Google che sei autorizzato a usare il servizio.',
              computerString: _scenario == ApiScenario.unauthorized401
                  ? 'x-goog-api-key: CHIAVE_FALSA_ERRATA (❌ Verrà respinta!)'
                  : 'x-goog-api-key: AIzaSy•••••••••••• (✅ Valida, custodita nel file .env)',
              color: _scenario == ApiScenario.unauthorized401 ? const Color(0xFFFF5252) : Colors.amberAccent,
            ),
            const SizedBox(height: 10),

            _envelopePieceCard(
              stepNumber: 'PEZZO 3 (DENTRO LA BUSTA)',
              humanTitle: '📝 Il Foglietto con la tua Ordinazione',
              techName: 'Si chiama: PAYLOAD JSON (Body)',
              humanMeaning: 'Contiene la frase che hai scritto sopra ("${_promptCtrl.text}") racchiusa tra parentesi graffe { } così qualsiasi computer sa leggerla.',
              computerString: _scenario == ApiScenario.badRequest400
                  ? '{ "contenuti_errati": "${_promptCtrl.text}" }  <-- ❌ Parola chiave sbagliata!'
                  : '{ "contents": [{ "text": "${_promptCtrl.text}" }], "temperature": ${_temperature.toStringAsFixed(1)} }',
              color: const Color(0xFFB388FF),
            ),
            const SizedBox(height: 12),

            // Freccia verso la risposta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusCol.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusCol.withOpacity(0.55), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isOk ? Icons.check_circle : Icons.error_outline, color: statusCol, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🎁 COSA TORNA INDIETRO DAL SERVER (HTTP RESPONSE: $_statusText)',
                          style: GoogleFonts.spaceMono(
                            color: statusCol,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _responseText,
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _envelopePieceCard({
    required String stepNumber,
    required String humanTitle,
    required String techName,
    required String humanMeaning,
    required String computerString,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stepNumber,
                  style: GoogleFonts.spaceMono(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  humanTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                techName,
                style: GoogleFonts.spaceMono(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            humanMeaning,
            style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF05070E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(
              'Come lo scrive il computer:  $computerString',
              style: GoogleFonts.spaceMono(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 1: Ispettore affiancato Request JSON vs Response JSON ──
  Widget _buildHttpJsonInspector() {
    final String requestJson = const JsonEncoder.withIndent('  ').convert({
      if (_scenario == ApiScenario.badRequest400)
        'contenuti_errati': [
          {
            'parts': [
              {'text': _promptCtrl.text}
            ]
          }
        ]
      else
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': _promptCtrl.text}
            ]
          }
        ],
      'generationConfig': {
        'temperature': double.parse(_temperature.toStringAsFixed(1)),
        'maxOutputTokens': _maxTokens,
      }
    });

    final Map<String, dynamic> responseMap = _scenario == ApiScenario.success200
        ? {
            'candidates': [
              {
                'content': {
                  'role': 'model',
                  'parts': [
                    {'text': _responseText}
                  ]
                },
                'finishReason': 'STOP',
              }
            ],
            'usageMetadata': {
              'promptTokenCount': _promptTokens,
              'candidatesTokenCount': _completionTokens,
              'totalTokenCount': _promptTokens + _completionTokens,
            },
            'modelVersion': 'gemini-2.5-flash',
          }
        : {
            'error': {
              'code': _statusCode,
              'message': _responseText,
              'status': _statusText.split(' ').skip(1).join('_'),
            }
          };

    final String responseJson = const JsonEncoder.withIndent('  ').convert(responseMap);

    final String authHeaderValue = _scenario == ApiScenario.unauthorized401
        ? 'AIzaSy_CHIAVE_ERRATA_XXX'
        : 'AIzaSy•••••••••••••••••••• (da .env)';

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _jsonPanel(
                  badge: 'BUSTA IN USCITA // HTTP REQUEST',
                  color: const Color(0xFF00E5FF),
                  headers: [
                    'POST /v1beta/models/gemini-2.5-flash:${_useStreaming ? "streamGenerateContent" : "generateContent"} HTTP/1.1',
                    'Host: generativelanguage.googleapis.com',
                    'Content-Type: application/json',
                    'x-goog-api-key: $authHeaderValue',
                  ],
                  jsonBody: requestJson,
                  footerNote:
                      'Gli Header dicono al server chi sei (API Key) e in che formato parli (JSON). Il Body contiene i dati veri e propri.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _jsonPanel(
                  badge: 'BUSTA DI RITORNO // RESPONSE ($_statusText)',
                  color: _statusCode == 200 ? const Color(0xFF69F0AE) : const Color(0xFFFF5252),
                  headers: [
                    'HTTP/1.1 $_statusText',
                    'Content-Type: ${_useStreaming ? "text/event-stream" : "application/json; charset=UTF-8"}',
                    'Date: ${DateTime.now().toUtc().toString().substring(0, 19)} GMT',
                    'X-Latency-Ms: ${_latencyMs}ms',
                  ],
                  jsonBody: responseJson,
                  footerNote: _statusCode == 200
                      ? 'Il server risponde con codice 200 OK, il testo generato in candidates[0] e il conteggio dei token usati.'
                      : 'Quando qualcosa non va, il server restituisce un codice 4xx/5xx e un oggetto "error" che spiega la causa.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _jsonPanel({
    required String badge,
    required Color color,
    required List<String> headers,
    required String jsonBody,
    required String footerNote,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            badge,
            style: GoogleFonts.spaceMono(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HTTP HEADERS (Sulla Busta)',
                  style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                ...headers.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        h,
                        style: GoogleFonts.spaceMono(
                          color: h.contains('x-goog-api-key') ? Colors.amberAccent : Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'JSON PAYLOAD (Dentro la Busta)',
            style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF05060C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonBody,
                  style: GoogleFonts.spaceMono(
                    color: color.withOpacity(0.95),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            footerNote,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Generatore Codice Multi-Linguaggio (Come si integrano) ──
  Widget _buildCodeIntegrationTab() {
    final languages = ['Python', 'JavaScript (Fetch)', 'Dart / Flutter', 'cURL (Terminale)'];
    final code = _generateCodeSnippet(_codeLangIndex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(languages.length, (i) {
                final bool sel = _codeLangIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _codeLangIndex = i),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF69F0AE).withOpacity(0.22)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: sel ? const Color(0xFF69F0AE) : Colors.white24,
                        ),
                      ),
                      child: Text(
                        languages[i],
                        style: GoogleFonts.spaceMono(
                          color: sel ? const Color(0xFF69F0AE) : Colors.white,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Snippet di codice copiato negli appunti!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 14, color: Colors.cyanAccent),
                      const SizedBox(width: 6),
                      Text(
                        'COPIA CODICE',
                        style: GoogleFonts.spaceMono(
                          color: Colors.cyanAccent,
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
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Text(
              'COME SI INTEGRA IN 4 PASSI:  '
              '① Salva la API_KEY in un file .env (mai nel codice pubblico!)   '
              '② Prepara Indirizzo URL + Header   '
              '③ Invia il Body JSON con POST   '
              '④ Leggi il JSON di risposta.',
              style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF05070E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  code,
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF69F0AE),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateCodeSnippet(int langIndex) {
    final safePrompt = _promptCtrl.text.replaceAll('"', '\\"').replaceAll("'", "\\'");
    final temp = _temperature.toStringAsFixed(1);
    final action = _useStreaming ? 'streamGenerateContent' : 'generateContent';

    switch (langIndex) {
      case 0:
        return '''# 1. Importa la libreria per fare chiamate su Internet
import os
import requests

# 2. Prendi il tuo Badge Segreto (API Key) dal file .env
API_KEY = os.environ.get("GEMINI_API_KEY")
INDIRIZZO_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:$action"

# 3. Prepara l'esterno della Busta (Header HTTP)
headers = {
    "Content-Type": "application/json",
    "x-goog-api-key": API_KEY,
}

# 4. Prepara il foglio dell'ordine dentro la Busta (JSON)
ordine_json = {
    "contents": [{"role": "user", "parts": [{"text": "$safePrompt"}]}],
    "generationConfig": {"temperature": $temp, "maxOutputTokens": $_maxTokens}
}

# 5. Spedisci la busta con POST e leggi la risposta!
response = requests.post(INDIRIZZO_URL, headers=headers, json=ordine_json, timeout=15)

if response.status_code == 200:
    dati = response.json()  # Apre la busta JSON ricevuta
    risposta = dati["candidates"][0]["content"]["parts"][0]["text"]
    print("Risposta AI:", risposta)
else:
    print(f"Errore ({response.status_code}):", response.text)''';

      case 1:
        return '''// 1. Indirizzo del Server e Badge Segreto (API Key)
const API_KEY = process.env.GEMINI_API_KEY;
const ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:$action";

async function chiamaModelloAI() {
  try {
    // 2. Spedisci la busta (POST) con Header e Ordine JSON
    const response = await fetch(ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": API_KEY,
      },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: "$safePrompt" }] }],
        generationConfig: { temperature: $temp, maxOutputTokens: $_maxTokens },
      }),
    });

    // 3. Controlla il bollino Status Code (200 OK vs 401/429)
    if (!response.ok) {
      throw new Error(`Errore HTTP \${response.status}: \${await response.text()}`);
    }

    // 4. Apri la busta JSON e mostra la risposta
    const data = await response.json();
    const text = data.candidates[0].content.parts[0].text;
    console.log("Risposta ricevuta:", text);
  } catch (err) {
    console.error("Chiamata fallita:", err);
  }
}

chiamaModelloAI();''';

      case 2:
        return '''// Come è integrato dentro questa stessa app Flutter (Neural Lens)!
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> inviaDomandaAllaRete() async {
  // 1. Legge la chiave segreta dal file .env
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // 2. Prepara il collegamento al modello Gemini
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: $temp,
      maxOutputTokens: $_maxTokens,
    ),
  );

  try {
    // 3. Invia la domanda e attende la busta di risposta
    final response = await model.generateContent([Content.text('$safePrompt')]);
    print('Risposta AI: \${response.text}');
  } catch (e) {
    print('Errore di rete o chiave errata: \$e');
  }
}''';

      default:
        return '''# Comando rapido da Terminale (cURL) per testare la chiamata API:
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:$action" \\
  -H "Content-Type: application/json" \\
  -H "x-goog-api-key: \$GEMINI_API_KEY" \\
  -d '{
    "contents": [{
      "role": "user",
      "parts": [{"text": "$safePrompt"}]
    }],
    "generationConfig": {
      "temperature": $temp,
      "maxOutputTokens": $_maxTokens
    }
  }' ''';
    }
  }

  // ── TAB 3: Dizionario Semplice dei Termini API ──
  Widget _buildApiGlossaryTab() {
    final concepts = [
      (
        'API (Application Programming Interface) = IL CAMERIERE',
        'È il messaggero che permette a due programmi diversi (es. la tua App e il Server di Google) di parlarsi senza dover sapere come sono costruiti al loro interno.',
        Colors.cyanAccent,
      ),
      (
        'ENDPOINT URL & POST = L\'INDIRIZZO DEL RISTORANTE',
        'L\'Endpoint è l\'indirizzo web esatto a cui spedire la richiesta. "POST" significa "ti sto inviando dei dati dentro una busta per farli elaborare" (mentre "GET" serve solo per leggere una pagina).',
        const Color(0xFF00E5FF),
      ),
      (
        'JSON = IL FOGLIO DELL\'ORDINAZIONE UNIVERSALE',
        'È un modo semplicissimo di scrivere i dati usando coppie "nome": "valore" tra parentesi graffe, ad esempio {"domanda": "Ciao"}. Lo capiscono tutti i linguaggi del mondo!',
        const Color(0xFFB388FF),
      ),
      (
        'API KEY & FILE .ENV = IL TUO PASSAPORTO SEGRETO',
        'È un codice personale (es. AIzaSy...) che dice al server chi sei. Va tenuto nascosto in un file privato chiamato .env: non va mai pubblicato su Internet, altrimenti altri useranno il tuo abbonamento!',
        Colors.amberAccent,
      ),
      (
        'STATUS CODE (200, 401, 429) = IL BOLLINO DEL RISULTATO',
        '200 OK = Tutto riuscito! • 400 Bad Request = Hai scritto male il JSON • 401 Unauthorized = Chiave API sbagliata • 429 Too Many Requests = Stai facendo troppe domande troppo in fretta.',
        const Color(0xFFFF5252),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.35)),
      ),
      child: ListView.separated(
        itemCount: concepts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = concepts[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.$3.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.$1,
                  style: GoogleFonts.spaceMono(
                    color: c.$3,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.$2,
                  style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13, height: 1.45),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: VISUALIZZATORE DEL FLUSSO API
// ─────────────────────────────────────────────────────────────────────────────
class _ApiFlowPainter extends CustomPainter {
  final Animation<double> animCtrl;
  final ApiStep currentStep;
  final ApiScenario scenario;
  final bool isStreaming;
  final bool isBeginnerMode;

  _ApiFlowPainter({
    required this.animCtrl,
    required this.currentStep,
    required this.scenario,
    required this.isStreaming,
    required this.isBeginnerMode,
  }) : super(repaint: animCtrl);

  double get animPhase => animCtrl.value;

  @override
  void paint(Canvas canvas, Size size) {
    FastCanvasEffects.drawSubtleTechGrid(
      canvas,
      size,
      color: AuroraPalette.cyan.withOpacity(0.038),
      spacing: 32,
    );

    final double cy = size.height * 0.55;
    final Offset clientPos = Offset(size.width * 0.14, cy);
    final Offset tlsPos = Offset(size.width * 0.38, cy);
    final Offset gatewayPos = Offset(size.width * 0.62, cy);
    final Offset serverPos = Offset(size.width * 0.86, cy);

    final bool isError = scenario != ApiScenario.success200;
    const Color errColor = Color(0xFFFF5252);

    _drawConnectionTrack(canvas, clientPos, tlsPos, gatewayPos, serverPos, isError);
    _drawActivePackets(canvas, clientPos, tlsPos, gatewayPos, serverPos, isError, errColor);

    _drawArchNode(
      canvas,
      pos: clientPos,
      title: isBeginnerMode ? '1. LA TUA APP' : 'CLIENT APP',
      subtitle: isBeginnerMode ? 'Telefono / Browser' : 'Flutter / Web / Mobile',
      detail: isBeginnerMode ? 'Prepara la Busta' : 'Serializza JSON',
      color: const Color(0xFF00E5FF),
      active: currentStep == ApiStep.clientSerialize || currentStep == ApiStep.clientParsed,
    );

    _drawArchNode(
      canvas,
      pos: tlsPos,
      title: isBeginnerMode ? '2. TUNNEL WEB' : 'TUNNEL HTTPS',
      subtitle: isBeginnerMode ? 'Lucchetto Sicuro' : 'TLS 1.3 Encryption',
      detail: isBeginnerMode ? 'Viaggio Protetto' : 'Pacchetto Cifrato',
      color: const Color(0xFF40C4FF),
      active: currentStep == ApiStep.networkTransit,
    );

    _drawArchNode(
      canvas,
      pos: gatewayPos,
      title: isBeginnerMode ? '3. GUARDIA API' : 'API GATEWAY',
      subtitle: isBeginnerMode ? 'Controlla il Badge' : 'Auth & Rate Limit',
      detail: isError ? 'RESPINTO (${_scenarioCode(scenario)})' : 'Badge Valido ✓',
      color: isError && (currentStep == ApiStep.gatewayAuth || currentStep == ApiStep.responseTransit)
          ? errColor
          : const Color(0xFFFFAB40),
      active: currentStep == ApiStep.gatewayAuth,
    );

    _drawArchNode(
      canvas,
      pos: serverPos,
      title: isBeginnerMode ? '4. CERVELLO AI' : 'SERVER AI',
      subtitle: isBeginnerMode ? 'Computer di Google' : 'Gemini 2.5 Flash',
      detail: isBeginnerMode ? 'Calcola Risposta' : 'Inferenza GPU',
      color: const Color(0xFFE040FB),
      active: currentStep == ApiStep.serverInference,
    );
  }

  int _scenarioCode(ApiScenario s) {
    switch (s) {
      case ApiScenario.success200:
        return 200;
      case ApiScenario.unauthorized401:
        return 401;
      case ApiScenario.rateLimit429:
        return 429;
      case ApiScenario.badRequest400:
        return 400;
    }
  }

  void _drawConnectionTrack(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Offset p3,
    Offset p4,
    bool isError,
  ) {
    final Paint reqTrack = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.28)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final Paint resTrack = Paint()
      ..color = (isError ? const Color(0xFFFF5252) : const Color(0xFF69F0AE)).withOpacity(0.28)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(p1.translate(0, -22), p3.translate(0, -22), reqTrack);
    if (!isError) {
      canvas.drawLine(p3.translate(0, -22), p4.translate(0, -22), reqTrack);
    }

    canvas.drawLine(
      (isError ? p3 : p4).translate(0, 22),
      p1.translate(0, 22),
      resTrack,
    );

    _drawText(
      canvas,
      isBeginnerMode
          ? '───► ANDATA: La Busta con la tua Domanda (HTTP Request) ───►'
          : '───► HTTP REQUEST (Headers + Body JSON) ───►',
      Offset((p1.dx + p4.dx) / 2, p1.dy - 66),
      Colors.cyanAccent.withOpacity(0.9),
      11.5,
      bold: true,
    );
    _drawText(
      canvas,
      isError
          ? '◄─── RITORNO: Richiesta Bloccata dalla Guardia (Errore ${_scenarioCode(scenario)}) ◄───'
          : (isBeginnerMode
              ? '◄─── RITORNO: Il Vassoio con la Risposta Pronta (200 Tutto OK) ◄───'
              : '◄─── HTTP RESPONSE (200 OK + Risultato JSON) ◄───'),
      Offset((p1.dx + p4.dx) / 2, p1.dy + 66),
      (isError ? const Color(0xFFFF5252) : const Color(0xFF69F0AE)).withOpacity(0.92),
      11.5,
      bold: true,
    );
  }

  void _drawActivePackets(
    Canvas canvas,
    Offset clientPos,
    Offset tlsPos,
    Offset gatewayPos,
    Offset serverPos,
    bool isError,
    Color errColor,
  ) {
    if (currentStep == ApiStep.idle) {
      final double x = clientPos.dx + (serverPos.dx - clientPos.dx) * animPhase;
      final Offset pulsePos = Offset(x, clientPos.dy - 22);
      FastCanvasEffects.drawSoftGlowCircle(
        canvas,
        pulsePos,
        5.0,
        Colors.cyanAccent,
        intensity: 0.75,
        rings: 2,
      );
      canvas.drawCircle(pulsePos, 3.5, Paint()..color = Colors.cyanAccent);
      return;
    }

    Offset? packetPos;
    String packetLabel = '';
    Color packetColor = Colors.cyanAccent;

    switch (currentStep) {
      case ApiStep.clientSerialize:
        packetPos = Offset.lerp(clientPos, tlsPos, animPhase * 0.35)!.translate(0, -22);
        packetLabel = isBeginnerMode ? '✉️ BUSTA PRONTA' : 'JSON + API_KEY';
        packetColor = const Color(0xFF00E5FF);
        break;
      case ApiStep.networkTransit:
        packetPos = Offset.lerp(clientPos, gatewayPos, animPhase)!.translate(0, -22);
        packetLabel = isBeginnerMode ? '🔒 IN VIAGGIO' : 'TLS ENCRYPTED';
        packetColor = const Color(0xFF40C4FF);
        break;
      case ApiStep.gatewayAuth:
        packetPos = gatewayPos.translate(0, -28);
        packetLabel = isError ? '❌ BLOCCATO ${_scenarioCode(scenario)}' : '✅ BADGE OK';
        packetColor = isError ? errColor : const Color(0xFFFFAB40);
        break;
      case ApiStep.serverInference:
        packetPos = Offset.lerp(gatewayPos, serverPos, animPhase)!.translate(0, -22);
        packetLabel = isBeginnerMode ? '🧠 CALCOLO AI' : 'INFERENZA LLM';
        packetColor = const Color(0xFFE040FB);
        break;
      case ApiStep.responseTransit:
        final Offset start = isError ? gatewayPos : serverPos;
        packetPos = Offset.lerp(start, clientPos, animPhase)!.translate(0, 22);
        packetLabel = isError ? 'ERRORE ${_scenarioCode(scenario)}' : '🎁 RISPOSTA 200';
        packetColor = isError ? errColor : const Color(0xFF69F0AE);
        break;
      case ApiStep.clientParsed:
        packetPos = clientPos.translate(0, 28);
        packetLabel = '✨ MOSTRATA!';
        packetColor = isError ? errColor : const Color(0xFF69F0AE);
        break;
      case ApiStep.idle:
        break;
    }

    if (packetPos != null) {
      _drawPacketBox(canvas, packetPos, packetLabel, packetColor);
    }
  }

  void _drawPacketBox(Canvas canvas, Offset center, String label, Color color) {
    final RRect box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 128, height: 26),
      const Radius.circular(6),
    );
    FastCanvasEffects.drawSoftGlowRRect(canvas, box, color, intensity: 0.9);
    canvas.drawRRect(box, Paint()..color = const Color(0xFF090D1A));
    canvas.drawRRect(
      box,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    _drawText(canvas, label, center, color, 10.5, bold: true);
  }

  void _drawArchNode(
    Canvas canvas, {
    required Offset pos,
    required String title,
    required String subtitle,
    required String detail,
    required Color color,
    required bool active,
  }) {
    const double w = 144;
    const double h = 88;
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(12),
    );

    if (active) {
      FastCanvasEffects.drawSoftGlowRRect(canvas, rect, color, intensity: 0.95);
    }

    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xFF0A1024).withOpacity(0.96),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = active ? color : color.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.2 : 1.2,
    );

    _drawText(canvas, title, pos.translate(0, -22), color, 11.5, bold: true);
    _drawText(canvas, subtitle, pos.translate(0, -2), Colors.white.withOpacity(0.88), 10);
    _drawText(
      canvas,
      detail,
      pos.translate(0, 19),
      active ? Colors.white : Colors.white.withOpacity(0.75),
      10,
      bold: active,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double size, {
    bool bold = false,
  }) {
    TextLayoutCache.paintCentered(
      canvas,
      text: text,
      center: center,
      fontSize: size,
      color: color,
      weight: bold ? FontWeight.bold : FontWeight.normal,
    );
  }

  @override
  bool shouldRepaint(covariant _ApiFlowPainter oldDelegate) =>
      oldDelegate.currentStep != currentStep ||
      oldDelegate.scenario != scenario ||
      oldDelegate.isBeginnerMode != isBeginnerMode;
}
