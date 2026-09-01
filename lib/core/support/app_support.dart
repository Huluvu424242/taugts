import 'package:flutter/material.dart';
import 'package:taugts/core/presentation/formular_fehler.dart';
import 'package:taugts/core/support/app_info.dart';
import 'package:taugts/core/support/app_info_service.dart';
import 'package:taugts/core/support/external_url_service.dart';
import 'package:taugts/core/support/support_kontexte.dart';

const _appRepository = 'Huluvu424242/taugts';
const _projektseiteUrl = 'https://github.com/Huluvu424242/taugts';
const _projektdokumentationUrl = 'https://huluvu424242.github.io/taugts/';
const appLogoAsset = 'assets/icons/app_icon_source.png';

class AppLogo extends StatelessWidget {
  const AppLogo({
    required this.size,
    this.semanticLabel,
    super.key,
  });

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      appLogoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    final label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: logo);
    }
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(child: logo),
    );
  }
}

class AppSupportMenu extends StatelessWidget {
  const AppSupportMenu({
    required this.contextName,
    this.appInfoGateway,
    this.externalUrlGateway,
    super.key,
  });

  final String contextName;
  final AppInfoGateway? appInfoGateway;
  final ExternalUrlGateway? externalUrlGateway;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_SupportAktion>(
        tooltip: 'App-Menü öffnen',
        onSelected: (aktion) async {
          switch (aktion) {
            case _SupportAktion.bugMelden:
              await zeigeBugMeldung(
                context,
                contextName: contextName,
                appInfoGateway: appInfoGateway,
                externalUrlGateway: externalUrlGateway,
              );
            case _SupportAktion.ueber:
              await zeigeUeberDialog(
                context,
                appInfoGateway: appInfoGateway,
                externalUrlGateway: externalUrlGateway,
              );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _SupportAktion.bugMelden,
            child: Text('Bug melden'),
          ),
          PopupMenuItem(
            value: _SupportAktion.ueber,
            child: Text('Über'),
          ),
        ],
      );
}

enum _SupportAktion { bugMelden, ueber }

class BugMeldenButton extends StatelessWidget {
  const BugMeldenButton({
    required this.contextName,
    this.appInfoGateway,
    this.externalUrlGateway,
    super.key,
  });

  final String contextName;
  final AppInfoGateway? appInfoGateway;
  final ExternalUrlGateway? externalUrlGateway;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => zeigeBugMeldung(
          context,
          contextName: contextName,
          appInfoGateway: appInfoGateway,
          externalUrlGateway: externalUrlGateway,
        ),
        icon: const Icon(Icons.bug_report_outlined),
        label: const Text('Bug melden'),
      );
}

Future<void> zeigeUeberDialog(
  BuildContext context, {
  AppInfoGateway? appInfoGateway,
  ExternalUrlGateway? externalUrlGateway,
}) async {
  final gateway = appInfoGateway ?? AppInfoService();
  final urlGateway = externalUrlGateway ?? ExternalUrlService();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      String? linkFehler;
      bool oeffnetLink = false;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> oeffneExternesZiel({
            required String url,
            required String zielName,
          }) async {
            setDialogState(() {
              oeffnetLink = true;
              linkFehler = null;
            });
            try {
              await urlGateway.oeffnen(url);
              if (!context.mounted) {
                return;
              }
              setDialogState(() => oeffnetLink = false);
            } catch (error) {
              if (!context.mounted) {
                return;
              }
              setDialogState(() {
                oeffnetLink = false;
                linkFehler = '$zielName konnte nicht geöffnet werden: $error';
              });
            }
          }

          return AlertDialog(
            title: const Text('Über Taugt’s?'),
            content: FutureBuilder<AppInfo>(
              future: gateway.laden(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Semantics(
                    liveRegion: true,
                    child: Text(
                      'Releaseversion konnte nicht geladen werden: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Semantics(
                      label: 'Releaseversion wird geladen',
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Taugt’s?'),
                    const SizedBox(height: 8),
                    Text('Releaseversion ${snapshot.data!.displayVersion}'),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Projektseite extern öffnen',
                      child: TextButton.icon(
                        onPressed: oeffnetLink
                            ? null
                            : () => oeffneExternesZiel(
                                  url: _projektseiteUrl,
                                  zielName: 'Projektseite',
                                ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Projektseite'),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Projektdokumentation extern öffnen',
                      child: TextButton.icon(
                        onPressed: oeffnetLink
                            ? null
                            : () => oeffneExternesZiel(
                                  url: _projektdokumentationUrl,
                                  zielName: 'Projektdokumentation',
                                ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Projektdokumentation'),
                      ),
                    ),
                    if (linkFehler != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          linkFehler!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            actions: [
              BugMeldenButton(
                contextName: SupportKontexte.ueberDialog,
                appInfoGateway: gateway,
                externalUrlGateway: externalUrlGateway,
              ),
              TextButton(
                onPressed: () => zeigeBarrierefreiheitserklaerung(
                  dialogContext,
                  appInfoGateway: gateway,
                  externalUrlGateway: externalUrlGateway,
                ),
                child: const Text('Barrierefreiheitserklärung'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Stack(
                  key: Key('ueber-schliessen-mit-logo'),
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Text('Schließen'),
                    Positioned(
                      left: -16,
                      child: AppLogo(size: 14),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> zeigeBarrierefreiheitserklaerung(
  BuildContext context, {
  AppInfoGateway? appInfoGateway,
  ExternalUrlGateway? externalUrlGateway,
}) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Barrierefreiheitserklärung'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'Stand: 29. August 2026',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Taugt’s? wird nach den im Projekt festgelegten UX- und '
                'Barrierefreiheitsregeln entwickelt. Die App unterstützt '
                'verständliche Beschriftungen, ausreichend große Touch-Ziele, '
                'große Systemschrift sowie wahrnehmbare Lade-, Fehler- und '
                'Erfolgszustände.',
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: const Text(
                  'Bekannte Barrieren',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Die vollständige praktische Prüfung aller Abläufe mit '
                'TalkBack, Schaltersteuerungen und unterschiedlichen '
                'Android-Geräten ist noch nicht abgeschlossen. Die '
                'Plattformintegration für Windows und Linux ist vorbereitet, '
                'aber noch nicht vollständig umgesetzt. Externe GitHub-Seiten '
                'liegen außerhalb des Einflussbereichs dieser App.',
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: const Text(
                  'Barrieren melden',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Über „Bug melden“ kann eine Barriere mit installierter '
                'App-Version und dem Kontext dieser Erklärung gemeldet werden.',
              ),
            ],
          ),
        ),
        actions: [
          BugMeldenButton(
            contextName: SupportKontexte.barrierefreiheitserklaerung,
            appInfoGateway: appInfoGateway,
            externalUrlGateway: externalUrlGateway,
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );

Future<void> zeigeBugMeldung(
  BuildContext context, {
  required String contextName,
  AppInfoGateway? appInfoGateway,
  ExternalUrlGateway? externalUrlGateway,
}) async {
  final gateway = appInfoGateway ?? AppInfoService();
  AppInfo appInfo;
  try {
    appInfo = await gateway.laden();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Releaseversion konnte nicht geladen werden: $error',
        ),
      ),
    );
    return;
  }
  if (!context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _BugMeldungDialog(
      contextName: contextName,
      appInfo: appInfo,
      externalUrlGateway: externalUrlGateway ?? ExternalUrlService(),
    ),
  );
}

class _BugMeldungDialog extends StatefulWidget {
  const _BugMeldungDialog({
    required this.contextName,
    required this.appInfo,
    required this.externalUrlGateway,
  });

  final String contextName;
  final AppInfo appInfo;
  final ExternalUrlGateway externalUrlGateway;

  @override
  State<_BugMeldungDialog> createState() => _BugMeldungDialogState();
}

class _BugMeldungDialogState extends State<_BugMeldungDialog> {
  static const _beschreibungMaxLength = 2000;

  final _formularKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _fehlerFokus = FocusNode(debugLabel: 'Bugreport-Fehlersammler');
  final _typFokus = FocusNode(debugLabel: 'Fehlerart');
  final _beschreibung = TextEditingController();

  String? _fehlerart;
  bool _zeigtFehler = false;
  bool _oeffnet = false;
  String? _fehlermeldung;

  @override
  void dispose() {
    _scrollController.dispose();
    _fehlerFokus.dispose();
    _typFokus.dispose();
    _beschreibung.dispose();
    super.dispose();
  }

  Future<void> _absenden() async {
    final gueltig = _formularKey.currentState?.validate() ?? false;
    if (!gueltig) {
      setState(() => _zeigtFehler = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte markierte Pflichtfelder prüfen.')),
      );
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      if (!mounted) {
        return;
      }
      _fehlerFokus.requestFocus();
      return;
    }

    setState(() {
      _oeffnet = true;
      _fehlermeldung = null;
    });

    final titel = '[$_fehlerart] App-Fehler in ${widget.contextName}';
    final beschreibung = _beschreibung.text.trim();
    final inhalt = [
      '## Fehlerart',
      _fehlerart!,
      '',
      '## Kontext',
      widget.contextName,
      '',
      '## Releaseversion',
      widget.appInfo.displayVersion,
      '',
      '## Beschreibung',
      beschreibung.isEmpty
          ? 'Keine zusätzliche Beschreibung angegeben.'
          : beschreibung,
    ].join('\n');
    final uri = Uri.https(
      'github.com',
      '/$_appRepository/issues/new',
      {
        'template': 'app_bug_report.md',
        'labels': 'bug',
        'title': titel,
        'body': inhalt,
      },
    );

    try {
      await widget.externalUrlGateway.oeffnen(uri.toString());
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _oeffnet = false;
        _fehlermeldung =
            'Bugreport konnte nicht auf GitHub geöffnet werden: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Bug melden'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: _formularKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (_) => _zeigtFehler && _fehlerart == null
                        ? FormularFehlersammler(
                            focusNode: _fehlerFokus,
                            fehler: [
                              ('Fehlerart: Bitte auswählen', _typFokus),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  Text('Kontext: ${widget.contextName}'),
                  Text(
                    'Releaseversion: ${widget.appInfo.displayVersion}',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    focusNode: _typFokus,
                    initialValue: _fehlerart,
                    hint: const Text('Bitte auswählen'),
                    decoration: const InputDecoration(
                      labelText: 'Fehlerart *',
                      helperText: 'Bitte eine Fehlerart auswählen.',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Barrierefreiheitsfehler',
                        child: Text('Barrierefreiheitsfehler'),
                      ),
                      DropdownMenuItem(
                        value: 'Darstellungsfehler',
                        child: Text('Darstellungsfehler'),
                      ),
                      DropdownMenuItem(
                        value: 'Funktionsfehler',
                        child: Text('Funktionsfehler'),
                      ),
                      DropdownMenuItem(
                        value: 'Sonstiges',
                        child: Text('Sonstiges'),
                      ),
                    ],
                    onChanged: _oeffnet
                        ? null
                        : (wert) => setState(() => _fehlerart = wert),
                    validator: (wert) =>
                        wert == null ? 'Bitte eine Fehlerart auswählen.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _beschreibung,
                    enabled: !_oeffnet,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: _beschreibungMaxLength,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      helperText:
                          'Keine Zugangsdaten oder persönlichen Daten eintragen.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    container: true,
                    child: const Text(
                      'Zum Absenden ist eine Anmeldung bei GitHub erforderlich. '
                      'Der vorbereitete Bericht kann auf GitHub geprüft und '
                      'erst dort endgültig abgesendet werden.',
                    ),
                  ),
                  if (_fehlermeldung != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _fehlermeldung!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _oeffnet ? null : () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: _oeffnet ? null : _absenden,
            icon: const Icon(Icons.open_in_new),
            label: Text(
              _oeffnet ? 'Wird geöffnet …' : 'Auf GitHub prüfen',
            ),
          ),
        ],
      );
}
