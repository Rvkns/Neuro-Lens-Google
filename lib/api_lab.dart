// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODULO 02 // LABORATORIO ACCADEMICO CHIAMATE API
// Spiega visivamente: Cosa sono le API, Come funzionano (Client ⇄ Gateway ⇄ Server)
// e Come si integrano nel codice reale (cURL, Python, JS, Dart).
// ─────────────────────────────────────────────────────────────────────────────

enum ApiStep {
  idle,
  clientSerialize, // 1. Il client prepara Headers + Body JSON
  networkTransit,  // 2. Viaggio su HTTPS/TLS verso l'endpoint
  gatewayAuth,     // 3. L'API Gateway controlla API Key e Rate Limit
  serverInference, // 4. Il Server AI elabora il payload JSON
  responseTransit, // 5. Il Server restituisce Status Code + JSON Response
  clientParsed,    // 6. Il Client deserializza il JSON e aggiorna la UI
}

enum ApiScenario {
  success200,      // 200 OK — Chiamata completata con successo
  unauthorized401, // 401 Unauthorized — API Key mancante o invalida
  rateLimit429,    // 429 Too Many Requests — Quota superata
  badRequest400,   // 400 Bad Request — JSON malformato o parametri errati
}

class ApiStepInfo {
  final int number;
  final String title;
  final String subtitle;
  final String academicExplanation;
  final String analogy;
  final Color color;

  const ApiStepInfo({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.academicExplanation,
    required this.analogy,
    required this.color,
  });
}

const Map<ApiStep, ApiStepInfo> kApiStepDetails = {
  ApiStep.idle: ApiStepInfo(
    number: 0,
    title: 'SISTEMA PRONTO // IN ATTESA DI CHIAMATA',
    subtitle: 'Configura i parametri o premi "INVIA API" / "Avanza Step"',
    academicExplanation:
        'Un\'API (Application Programming Interface) è un contratto di comunicazione tra due software. '
        'Permette alla tua applicazione (Client) di chiedere un servizio o un calcolo a un sistema remoto (Server) '
        'senza dover conoscere come è costruito internamente.',
    analogy:
        'Metafora del Ristorante: Tu sei il Client, la cucina è il Server AI. L\'API è il cameriere: '
        'prende la tua ordinazione scritta secondo il menu (Request JSON), la porta in cucina e ti riporta il piatto pronto (Response JSON).',
    color: Colors.cyanAccent,
  ),
  ApiStep.clientSerialize: ApiStepInfo(
    number: 1,
    title: 'FASE 1 // SERIALIZZAZIONE DELLA REQUEST (CLIENT)',
    subtitle: 'Costruzione di Metodo HTTP, Endpoint URL, Headers e Payload JSON',
    academicExplanation:
        'Prima di inviare qualsiasi dato sulla rete, la tua app raccoglie i parametri (es. il testo del prompt e la temperatura) '
        'e li trasforma in una stringa strutturata in formato JSON (serializzazione). '
        'Aggiunge inoltre gli Header HTTP: metadati fondamentali come "Content-Type: application/json" e la chiave segreta "x-goog-api-key".',
    analogy:
        'Come compilare una busta raccomandata: scrivi l\'indirizzo esatto sul fronte (URL Endpoint), alleghi il tuo passaporto (API Key) e inserisci il modulo compilato dentro la busta (Body JSON).',
    color: Color(0xFF00E5FF),
  ),
  ApiStep.networkTransit: ApiStepInfo(
    number: 2,
    title: 'FASE 2 // TRASMISSIONE SU TUNNEL HTTPS / TLS',
    subtitle: 'I pacchetti viaggiano cifrati attraverso Internet verso il server remoto',
    academicExplanation:
        'La richiesta lascia il dispositivo tramite il protocollo HTTPS. Il livello TLS cifra l\'intero pacchetto (inclusi Header e API Key) '
        'affinché nessun nodo intermedio sulla rete possa leggere il contenuto o rubare le credenziali durante il tragitto.',
    analogy:
        'Il furgone blindato: la busta viaggia in un tunnel protetto da crittografia fino all\'ingresso del data center.',
    color: Color(0xFF40C4FF),
  ),
  ApiStep.gatewayAuth: ApiStepInfo(
    number: 3,
    title: 'FASE 3 // API GATEWAY: AUTENTICAZIONE & QUOTA',
    subtitle: 'Verifica validità API Key, permessi e limiti di traffico (Rate Limiting)',
    academicExplanation:
        'Prima di toccare i costosi server GPU del modello AI, la richiesta viene intercettata dall\'API Gateway. '
        'Il Gateway verifica: 1) Chi sei? (Autenticazione tramite API Key → se fallisce restituisce 401 Unauthorized); '
        '2) Quante richieste stai facendo? (Rate Limit → se esageri restituisce 429 Too Many Requests); '
        '3) Il JSON è valido? (Altrimenti restituisce 400 Bad Request).',
    analogy:
        'Il buttafuori all\'ingresso: controlla il tuo badge (API Key) e verifica che il tuo abbonamento non abbia superato il limite giornaliero.',
    color: Color(0xFFFFAB40),
  ),
  ApiStep.serverInference: ApiStepInfo(
    number: 4,
    title: 'FASE 4 // ESECUZIONE SUL SERVER (INFERENZA AI)',
    subtitle: 'Il motore legge il JSON, esegue il modello neurale e genera l\'output',
    academicExplanation:
        'Superato il Gateway, il payload JSON raggiunge il microservizio di inferenza. '
        'Il server estrae il campo "contents", tokenizza il testo, lo processa sulla rete neurale con i parametri "generationConfig" '
        '(es. temperature) e calcola i token di risposta e le statistiche di consumo ("usageMetadata").',
    analogy:
        'Lo chef in cucina: legge la comanda approvata, prepara il piatto seguendo le tue preferenze di cottura (Temperature) e lo impiatta.',
    color: Color(0xFFE040FB),
  ),
  ApiStep.responseTransit: ApiStepInfo(
    number: 5,
    title: 'FASE 5 // RITORNO DELLA HTTP RESPONSE',
    subtitle: 'Invio di Status Code (es. 200 OK), Response Headers e Body JSON',
    academicExplanation:
        'Il server impacchetta il risultato in un nuovo oggetto JSON e lo rispedisce al Client accompagnato da un codice numerico standard '
        'detto HTTP Status Code: 200 significa tutto riuscito ("OK"), i codici 4xx indicano un errore del Client, '
        'mentre i codici 5xx indicano un problema interno del Server.',
    analogy:
        'Il cameriere torna al tavolo portando il vassoio con lo scontrino di riepilogo (Status Code + Token consumati) e la portata richiesta.',
    color: Color(0xFF69F0AE),
  ),
  ApiStep.clientParsed: ApiStepInfo(
    number: 6,
    title: 'FASE 6 // DESERIALIZZAZIONE & INTEGRAZIONE UI',
    subtitle: 'Il codice dell\'app legge il JSON ricevuto e mostra il risultato all\'utente',
    academicExplanation:
        'Il codice della tua app (es. "final data = jsonDecode(response.body)") trasforma il testo JSON ricevuto in oggetti nativi '
        'del linguaggio di programmazione (Dizionario in Python, Oggetto in JS, Map in Dart), estrae il testo generato '
        'in "candidates[0].content.parts[0].text" e aggiorna l\'interfaccia grafica!',
    analogy:
        'L\'apertura del pacco: l\'app scarta l\'involucro tecnico JSON e mostra all\'utente finale solo la risposta pulita ed elegante.',
    color: Colors.cyanAccent,
  ),
};

class ApiLabWorkspace extends StatefulWidget {
  final GenerativeModel? geminiModel;
  final bool hasValidKey;

  const ApiLabWorkspace({
    super.key,
    required this.geminiModel,
    required this.hasValidKey,
  });

  @override
  State<ApiLabWorkspace> createState() => _ApiLabWorkspaceState();
}

class _ApiLabWorkspaceState extends State<ApiLabWorkspace>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  // Parametri configurabili della chiamata API
  final TextEditingController _promptCtrl = TextEditingController(
    text: 'Spiega in 2 frasi cos\'è un\'API a uno studente universitario.',
  );
  double _temperature = 0.7;
  final int _maxTokens = 256;
  bool _useStreaming = false;
  bool _useLiveGemini = false;
  ApiScenario _scenario = ApiScenario.success200;

  // Controllo flusso didattico
  ApiStep _currentStep = ApiStep.idle;
  bool _isRunning = false;
  double _speedMultiplier = 1.0;

  // Telemetria chiamata
  int _statusCode = 200;
  String _statusText = '200 OK';
  int _latencyMs = 0;
  int _promptTokens = 14;
  int _completionTokens = 48;
  String _responseText =
      'Un\'API (Application Programming Interface) è un ponte standardizzato che consente a due programmi software diversi di dialogare e scambiarsi dati in modo sicuro. Funziona tramite richieste strutturate (Request) inviate a un indirizzo specifico (Endpoint) che restituiscono risposte prevedibili (Response), solitamente in formato JSON.';

  // Tab selezionati
  int _rightTabIndex = 0; // 0 = Ispettore HTTP/JSON, 1 = Codice Integrazione, 2 = Glossario
  int _codeLangIndex = 0; // 0 = Python, 1 = JavaScript, 2 = Dart/Flutter, 3 = cURL

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

    final stepDelay = Duration(milliseconds: (750 / _speedMultiplier).round());

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
        setState(() {
          _statusCode = 500;
          _statusText = 'ERRORE API LIVE';
          _responseText = 'Errore durante la chiamata reale: $e';
          _latencyMs = sw.elapsedMilliseconds;
        });
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
            'API key not valid. Please pass a valid API key in header "x-goog-api-key".';
        break;
      case ApiScenario.rateLimit429:
        _statusCode = 429;
        _statusText = '429 TOO MANY REQUESTS';
        _latencyMs = 55;
        _promptTokens = 0;
        _completionTokens = 0;
        _responseText =
            'Resource has been exhausted (e.g. check quota or rate limit: 15 RPM exceeded).';
        break;
      case ApiScenario.badRequest400:
        _statusCode = 400;
        _statusText = '400 BAD REQUEST';
        _latencyMs = 38;
        _promptTokens = 0;
        _completionTokens = 0;
        _responseText =
            'Invalid JSON payload received. Unknown name "contenuti" at "contents[0]": Cannot find field.';
        break;
    }
  }

  String _generateSimulatedAnswer(String prompt) {
    if (prompt.isEmpty) {
      return 'Inserisci un testo nel campo prompt per osservare come viene incapsulato nel payload JSON.';
    }
    return 'Risposta elaborata dal Server per: "$prompt". '
        'I parametri (temperature: ${_temperature.toStringAsFixed(1)}, maxOutputTokens: $_maxTokens) '
        'sono stati letti correttamente dal payload JSON e trasformati in questo messaggio.';
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
  // PANNELLO SINISTRO: VISUALIZZATORE DI FLUSSO + GUIDA ACCADEMICA
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLeftVisualPanel(bool wide) {
    final stepInfo = kApiStepDetails[_currentStep]!;
    return Container(
      padding: EdgeInsets.all(wide ? 22 : 16),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF0E192D), Color(0xFF06060F)],
          radius: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header modulo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                child: Text(
                  'LAB 02 // ARCHITETTURA API',
                  style: GoogleFonts.spaceMono(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cosa sono, come viaggiano i pacchetti HTTP/JSON e come si integrano',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra dei 3 pilastri accademici ("Cosa sono", "Come funzionano", "Come si integrano")
          _buildAcademicPillarsBar(),
          const SizedBox(height: 12),

          // Canvas Animato del flusso Client -> HTTPS -> Gateway -> Server
          if (wide)
            Expanded(child: _buildAnimatedFlowCanvas())
          else
            SizedBox(height: 310, child: _buildAnimatedFlowCanvas()),

          const SizedBox(height: 12),

          // Stepper interattivo a 6 fasi + controlli di riproduzione
          _buildStepControlsBar(),
          const SizedBox(height: 12),

          // Box Spiegazione Accademica + Metafora visiva dello step corrente
          _buildStepExplanationCard(stepInfo),
        ],
      ),
    );
  }

  Widget _buildAcademicPillarsBar() {
    return Row(
      children: [
        _pillarChip(
          icon: Icons.hub_outlined,
          title: '1. COSA SONO',
          desc: 'Ponte standard tra Client e Server remoto',
          color: Colors.cyanAccent,
        ),
        const SizedBox(width: 8),
        _pillarChip(
          icon: Icons.sync_alt,
          title: '2. COME FUNZIONANO',
          desc: 'Ciclo HTTP Request (JSON) ⇄ Response',
          color: const Color(0xFFB388FF),
        ),
        const SizedBox(width: 8),
        _pillarChip(
          icon: Icons.code,
          title: '3. COME SI INTEGRANO',
          desc: 'SDK / Fetch + API Key in .env + JSON parsing',
          color: const Color(0xFF69F0AE),
          onTap: () => setState(() => _rightTabIndex = 1),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceMono(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 11.5),
                      maxLines: 1,
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
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.06), blurRadius: 18),
        ],
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ApiFlowPainter(
                  currentStep: _currentStep,
                  scenario: _scenario,
                  animPhase: _animCtrl.value,
                  isStreaming: _useStreaming,
                ),
              );
            },
          ),
          // Badge in alto a sinistra con Metodo + Endpoint
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'POST',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'generativelanguage.googleapis.com/v1beta/...:${_useStreaming ? "streamGenerateContent" : "generateContent"}',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Badge Status Code & Latenza in alto a destra
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
            'HTTP $_statusText',
            style: GoogleFonts.spaceMono(
              color: col,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_latencyMs > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${_latencyMs}ms',
              style: GoogleFonts.spaceMono(
                color: Colors.white70,
                fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: steps.map((s) {
              final info = kApiStepDetails[s]!;
              final bool isCurrent = _currentStep == s;
              final bool isPassed = ApiStep.values.indexOf(_currentStep) > ApiStep.values.indexOf(s);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
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
                      'Step ${info.number}',
                      style: GoogleFonts.spaceMono(
                        color: isCurrent
                            ? info.color
                            : (isPassed ? Colors.white : Colors.white60),
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
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
                label: 'Avanza Step',
                onTap: _isRunning ? null : _stepForward,
                highlight: true,
              ),
              const SizedBox(width: 10),
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
                    _speedMultiplier < 1.0 ? '🐢 SLOW-MO (0.4x)' : '⚡ VELOCITÀ 1x',
                    style: GoogleFonts.spaceMono(
                      color: _speedMultiplier < 1.0 ? Colors.amberAccent : Colors.white,
                      fontSize: 11,
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
            Text(label, style: GoogleFonts.spaceMono(color: col, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepExplanationCard(ApiStepInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
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
                  info.title,
                  style: GoogleFonts.spaceMono(
                    color: info.color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                info.subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            info.academicExplanation,
            style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: info.color.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: info.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.analogy,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
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
  // PANNELLO DESTRO: CONFIGURATORE + ISPETTORE JSON + GENERATORE CODICE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRightInspectorPanel(bool wide) {
    return Container(
      padding: EdgeInsets.all(wide ? 22 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestBuilderCard(),
          const SizedBox(height: 12),
          _buildRightTabBar(),
          const SizedBox(height: 12),
          if (wide)
            Expanded(child: _buildSelectedTabContent())
          else
            SizedBox(height: 500, child: _buildSelectedTabContent()),
        ],
      ),
    );
  }

  Widget _buildRequestBuilderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'COSTRUTTORE CHIAMATA API (REQUEST BUILDER)',
                style: GoogleFonts.spaceMono(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
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
                    _useLiveGemini ? '● LIVE GEMINI API' : '○ SANDBOX DIDATTICA',
                    style: GoogleFonts.spaceMono(
                      color: _useLiveGemini ? const Color(0xFF69F0AE) : Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Payload JSON -> contents[0].parts[0].text',
                    labelStyle: TextStyle(color: Colors.cyanAccent.withOpacity(0.85), fontSize: 12),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _executeApiCall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                  foregroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  side: const BorderSide(color: Colors.cyanAccent, width: 1.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(_isRunning ? Icons.hourglass_top : Icons.play_arrow, size: 18),
                label: Text(
                  _isRunning ? 'IN CORSO...' : 'INVIA API',
                  style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Simula Status:', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  const SizedBox(width: 8),
                  _scenarioChip(ApiScenario.success200, '200 OK', const Color(0xFF69F0AE)),
                  const SizedBox(width: 5),
                  _scenarioChip(ApiScenario.unauthorized401, '401 Auth', const Color(0xFFFF5252)),
                  const SizedBox(width: 5),
                  _scenarioChip(ApiScenario.rateLimit429, '429 Quota', Colors.amberAccent),
                  const SizedBox(width: 5),
                  _scenarioChip(ApiScenario.badRequest400, '400 JSON', Colors.orangeAccent),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Temp: ${_temperature.toStringAsFixed(1)}',
                    style: GoogleFonts.spaceMono(color: Colors.purpleAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 95,
                    height: 26,
                    child: Slider(
                      value: _temperature,
                      min: 0.0,
                      max: 1.5,
                      divisions: 15,
                      activeColor: Colors.purpleAccent,
                      onChanged: (v) => setState(() => _temperature = v),
                    ),
                  ),
                ],
              ),

              InkWell(
                onTap: () => setState(() => _useStreaming = !_useStreaming),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _useStreaming
                        ? Colors.purpleAccent.withOpacity(0.22)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _useStreaming ? Colors.purpleAccent : Colors.white24,
                    ),
                  ),
                  child: Text(
                    _useStreaming ? 'MODALITÀ: SSE STREAM' : 'MODALITÀ: REST UNICO',
                    style: GoogleFonts.spaceMono(
                      color: _useStreaming ? Colors.purpleAccent : Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
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
      (Icons.data_object, '1. ISPETTORE HTTP / JSON'),
      (Icons.terminal, '2. COME SI INTEGRA (CODICE)'),
      (Icons.menu_book_outlined, '3. ATLANTE & CONCETTI API'),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.cyanAccent.withOpacity(0.18) : Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? Colors.cyanAccent : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$1, size: 16, color: active ? Colors.cyanAccent : Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[i].$2,
                        style: GoogleFonts.spaceMono(
                          color: active ? Colors.cyanAccent : Colors.white,
                          fontSize: 11,
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
        return _buildHttpJsonInspector();
      case 1:
        return _buildCodeIntegrationTab();
      default:
        return _buildApiGlossaryTab();
    }
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
                  badge: 'OUTGOING // HTTP REQUEST',
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
                  badge: 'INCOMING // HTTP RESPONSE ($_statusText)',
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
                  'HTTP HEADERS (Metadati Busta)',
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
            'JSON PAYLOAD (Corpo Dati)',
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
                          fontSize: 11.5,
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
              '② Prepara URL Endpoint + Headers   '
              '③ Invia il Body JSON con POST   '
              '④ Gestisci errori (try/catch) e leggi il JSON di risposta.',
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
        return '''# 1. Importa le librerie per leggere .env ed effettuare chiamate HTTP
import os
import requests

# 2. Recupera la chiave segreta dall'ambiente (NON scriverla in chiaro nel codice!)
API_KEY = os.environ.get("GEMINI_API_KEY")
ENDPOINT = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:$action"

# 3. Definisci gli Header HTTP (Metadati e Autenticazione)
headers = {
    "Content-Type": "application/json",
    "x-goog-api-key": API_KEY,
}

# 4. Costruisci il Payload JSON con il tuo prompt e i parametri
payload = {
    "contents": [{"role": "user", "parts": [{"text": "$safePrompt"}]}],
    "generationConfig": {"temperature": $temp, "maxOutputTokens": $_maxTokens}
}

# 5. Invia la richiesta POST e gestisci gli Status Code HTTP
response = requests.post(ENDPOINT, headers=headers, json=payload, timeout=15)

if response.status_code == 200:
    data = response.json()  # Deserializzazione JSON -> Dizionario Python
    risposta = data["candidates"][0]["content"]["parts"][0]["text"]
    print("Risposta AI:", risposta)
else:
    print(f"Errore API ({response.status_code}):", response.text)''';

      case 1:
        return '''// 1. Endpoint API e chiave caricata dalle variabili d'ambiente
const API_KEY = process.env.GEMINI_API_KEY;
const ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:$action";

async function chiamaModelloAI() {
  try {
    // 2. Esegui la chiamata HTTP POST con Headers e Body serializzato in JSON
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

    // 3. Controlla lo Status Code HTTP (es. 200 OK vs 401/429)
    if (!response.ok) {
      throw new Error(`HTTP Error \${response.status}: \${await response.text()}`);
    }

    // 4. Deserializza il JSON ricevuto e aggiorna la UI
    const data = await response.json();
    const text = data.candidates[0].content.parts[0].text;
    console.log("Risposta ricevuta:", text);
  } catch (err) {
    console.error("Integrazione fallita:", err);
  }
}

chiamaModelloAI();''';

      case 2:
        return '''// Come è integrato in questo stesso progetto Flutter (Neural Lens)!
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> inviaStimoloAllaRete() async {
  // 1. Legge la chiave API dal file .env
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // 2. Inizializza l'SDK che incapsula automaticamente le chiamate HTTPS/JSON
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: $temp,
      maxOutputTokens: $_maxTokens,
    ),
  );

  try {
    // 3. Invia il prompt (${_useStreaming ? "in modalità Streaming token-per-token" : "in modalità Request/Response singola"})
    ${_useStreaming ? '''final stream = model.generateContentStream([Content.text('$safePrompt')]);
    await for (final chunk in stream) {
      print('Token ricevuto: \${chunk.text}');
    }''' : '''final response = await model.generateContent([Content.text('$safePrompt')]);
    print('Risposta completa: \${response.text}');'''}
  } catch (e) {
    print('Errore di rete o autenticazione API: \$e');
  }
}''';

      default:
        return '''# Test rapido da Terminale con cURL (senza scrivere codice!)
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

  // ── TAB 3: Glossario e Concetti Accademici sulle API ──
  Widget _buildApiGlossaryTab() {
    final concepts = [
      (
        'ENDPOINT & METODO HTTP',
        'L\'Endpoint è l\'URL specifico a cui bussa il programma (es. /v1beta/models/...). Il Metodo indica l\'azione: GET (leggi dati), POST (invia dati o chiedi un\'elaborazione), PUT/PATCH (aggiorna), DELETE (elimina).',
        Colors.cyanAccent,
      ),
      (
        'JSON (JavaScript Object Notation)',
        'Il linguaggio universale con cui i programmi si scambiano dati: coppie "chiave": "valore" leggibili sia dagli umani sia da qualsiasi linguaggio (Python, JS, Dart, C++, Java).',
        const Color(0xFFB388FF),
      ),
      (
        'API KEY & SICUREZZA (.ENV)',
        'La chiave segreta identifica il tuo account e addebita la quota. Va custodita in variabili d\'ambiente (.env) o su un server backend: se la pubblichi su GitHub o nel frontend pubblico, chiunque può usarla!',
        Colors.amberAccent,
      ),
      (
        'CODICI DI STATO HTTP (STATUS CODES)',
        '200 OK = Successo • 400 Bad Request = JSON scritto male • 401 Unauthorized = API Key assente o errata • 429 Too Many Requests = Hai superato il limite di chiamate al minuto • 500 = Problema interno del Server.',
        const Color(0xFFFF5252),
      ),
      (
        'REST UNICO vs STREAMING (SSE)',
        'In una chiamata REST classica aspetti che l\'intera risposta sia pronta prima di riceverla. Con Server-Sent Events (Streaming) il server tiene aperto il canale e invia un token alla volta appena generato (come nella vista Rete Neurale!).',
        const Color(0xFF69F0AE),
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
                    fontSize: 13,
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
// CUSTOM PAINTER: VISUALIZZATORE ARCHITETTURALE DEL FLUSSO API
// ─────────────────────────────────────────────────────────────────────────────
class _ApiFlowPainter extends CustomPainter {
  final ApiStep currentStep;
  final ApiScenario scenario;
  final double animPhase;
  final bool isStreaming;

  _ApiFlowPainter({
    required this.currentStep,
    required this.scenario,
    required this.animPhase,
    required this.isStreaming,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.04)
      ..strokeWidth = 1;
    const double step = 32;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

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
      title: 'CLIENT APP',
      subtitle: 'Flutter / Web / Mobile',
      detail: 'Serializza JSON',
      color: const Color(0xFF00E5FF),
      active: currentStep == ApiStep.clientSerialize || currentStep == ApiStep.clientParsed,
    );

    _drawArchNode(
      canvas,
      pos: tlsPos,
      title: 'TUNNEL HTTPS',
      subtitle: 'TLS 1.3 Encryption',
      detail: 'Pacchetto Cifrato',
      color: const Color(0xFF40C4FF),
      active: currentStep == ApiStep.networkTransit,
    );

    _drawArchNode(
      canvas,
      pos: gatewayPos,
      title: 'API GATEWAY',
      subtitle: 'Auth & Rate Limit',
      detail: isError ? 'BLOCCATO (${_scenarioCode(scenario)})' : 'API Key Valida ✓',
      color: isError && (currentStep == ApiStep.gatewayAuth || currentStep == ApiStep.responseTransit)
          ? errColor
          : const Color(0xFFFFAB40),
      active: currentStep == ApiStep.gatewayAuth,
    );

    _drawArchNode(
      canvas,
      pos: serverPos,
      title: 'SERVER AI',
      subtitle: 'Gemini 2.5 Flash',
      detail: isStreaming ? 'SSE Token Stream' : 'Inferenza GPU',
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
      '───► HTTP REQUEST (Headers + Body JSON) ───►',
      Offset((p1.dx + p4.dx) / 2, p1.dy - 66),
      Colors.cyanAccent.withOpacity(0.88),
      11.5,
      bold: true,
    );
    _drawText(
      canvas,
      isError
          ? '◄─── HTTP ERROR RESPONSE (${_scenarioCode(scenario)}) DAL GATEWAY ◄───'
          : (isStreaming
              ? '◄═══ SSE STREAMING: CHUNK TOKEN-PER-TOKEN ◄═══'
              : '◄─── HTTP RESPONSE (200 OK + Risultato JSON) ◄───'),
      Offset((p1.dx + p4.dx) / 2, p1.dy + 66),
      (isError ? const Color(0xFFFF5252) : const Color(0xFF69F0AE)).withOpacity(0.9),
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
      final Paint pulse = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, clientPos.dy - 22), 5, pulse);
      return;
    }

    Offset? packetPos;
    String packetLabel = '';
    Color packetColor = Colors.cyanAccent;

    switch (currentStep) {
      case ApiStep.clientSerialize:
        packetPos = Offset.lerp(clientPos, tlsPos, animPhase * 0.35)!.translate(0, -22);
        packetLabel = 'JSON + API_KEY';
        packetColor = const Color(0xFF00E5FF);
        break;
      case ApiStep.networkTransit:
        packetPos = Offset.lerp(clientPos, gatewayPos, animPhase)!.translate(0, -22);
        packetLabel = 'TLS ENCRYPTED';
        packetColor = const Color(0xFF40C4FF);
        break;
      case ApiStep.gatewayAuth:
        packetPos = gatewayPos.translate(0, -28);
        packetLabel = isError ? 'REJECT ${_scenarioCode(scenario)}' : 'AUTH OK ✓';
        packetColor = isError ? errColor : const Color(0xFFFFAB40);
        break;
      case ApiStep.serverInference:
        packetPos = Offset.lerp(gatewayPos, serverPos, animPhase)!.translate(0, -22);
        packetLabel = 'INFERENZA LLM';
        packetColor = const Color(0xFFE040FB);
        break;
      case ApiStep.responseTransit:
        final Offset start = isError ? gatewayPos : serverPos;
        packetPos = Offset.lerp(start, clientPos, animPhase)!.translate(0, 22);
        packetLabel = isError ? 'ERR ${_scenarioCode(scenario)}' : (isStreaming ? 'SSE CHUNKS' : '200 OK JSON');
        packetColor = isError ? errColor : const Color(0xFF69F0AE);
        break;
      case ApiStep.clientParsed:
        packetPos = clientPos.translate(0, 28);
        packetLabel = 'UI AGGIORNATA';
        packetColor = isError ? errColor : const Color(0xFF69F0AE);
        break;
      case ApiStep.idle:
        break;
    }

    if (packetPos != null) {
      if (isStreaming && currentStep == ApiStep.responseTransit && !isError) {
        for (int k = 0; k < 4; k++) {
          double t = (animPhase + k * 0.22) % 1.0;
          Offset pos = Offset.lerp(serverPos, clientPos, t)!.translate(0, 22);
          _drawPacketBox(canvas, pos, 'chunk[$k]', const Color(0xFF69F0AE));
        }
      } else {
        _drawPacketBox(canvas, packetPos, packetLabel, packetColor);
      }
    }
  }

  void _drawPacketBox(Canvas canvas, Offset center, String label, Color color) {
    final Paint glow = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 18, glow);

    final RRect box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 112, height: 26),
      const Radius.circular(6),
    );
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
    const double w = 138;
    const double h = 88;
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: w, height: h),
      const Radius.circular(10),
    );

    if (active) {
      final Paint glow = Paint()
        ..color = color.withOpacity(0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawRRect(rect.inflate(6), glow);
    }

    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xFF0A0F1F).withOpacity(0.96),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = active ? color : color.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.2 : 1.2,
    );

    _drawText(canvas, title, pos.translate(0, -22), color, 12, bold: true);
    _drawText(canvas, subtitle, pos.translate(0, -2), Colors.white.withOpacity(0.88), 10.5);
    _drawText(
      canvas,
      detail,
      pos.translate(0, 19),
      active ? Colors.white : Colors.white.withOpacity(0.75),
      10.5,
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
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: 'monospace',
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ApiFlowPainter oldDelegate) => true;
}
