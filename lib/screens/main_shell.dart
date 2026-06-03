import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../models/tournament_alert.dart';
import '../models/profile_summary.dart';
import '../services/tournament_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import 'open_match_alerts_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'tournament_description_screen.dart';
import 'tournament_live_screen.dart';
import 'tournaments_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialTab = PgoNavTab.home,
    this.openProfileFriendsOnStart = false,
    this.initialProfile,
  });

  final PgoNavTab initialTab;
  final bool openProfileFriendsOnStart;
  final ProfileSummary? initialProfile;

  static Route<void> route({
    PgoNavTab initialTab = PgoNavTab.home,
    bool openProfileFriendsOnStart = false,
    ProfileSummary? initialProfile,
  }) {
    return MaterialPageRoute(
      builder: (_) => MainShell(
        initialTab: initialTab,
        openProfileFriendsOnStart: openProfileFriendsOnStart,
        initialProfile: initialProfile,
      ),
    );
  }

  static void openReplacement(
    BuildContext context, {
    PgoNavTab initialTab = PgoNavTab.home,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      route(initialTab: initialTab),
      (route) => false,
    );
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _seenAlertsKey = 'seen_tournament_alert_ids';
  static const _alertsPollInterval = Duration(seconds: 12);

  late PgoNavTab _currentTab;
  final TournamentService _tournamentService = TournamentService();
  final AppLinks _appLinks = AppLinks();
  final Set<String> _seenAlertIds = <String>{};
  Timer? _alertsTimer;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isDialogOpen = false;
  String? _lastHandledTournamentLink;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _bootstrapAlerts();
    _bootstrapDeepLinks();
  }

  @override
  void dispose() {
    _alertsTimer?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (!mounted) return;
      if (initialLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_handleIncomingLink(initialLink));
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir ese torneo.')),
      );
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      unawaited(_handleIncomingLink(uri));
    });
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    final tournamentId = _extractTournamentId(uri);
    if (tournamentId == null || tournamentId.isEmpty) return;
    if (_lastHandledTournamentLink == tournamentId) return;

    _lastHandledTournamentLink = tournamentId;
    await _openTournamentDescription(tournamentId);
  }

  String? _extractTournamentId(Uri uri) {
    if (uri.scheme == 'pgo' &&
        (uri.host == 'tournaments' || uri.host == 'tournament') &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.pathSegments.length >= 3 &&
        uri.pathSegments[0] == 'share' &&
        uri.pathSegments[1] == 'tournaments') {
      return uri.pathSegments[2];
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'torneos') {
      return uri.pathSegments[1];
    }

    return null;
  }

  Future<void> _bootstrapAlerts() async {
    await _loadSeenAlerts();
    if (!mounted) return;
    unawaited(_pollAlerts());
    _alertsTimer = Timer.periodic(_alertsPollInterval, (_) {
      unawaited(_pollAlerts());
    });
  }

  Future<void> _loadSeenAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    _seenAlertIds.addAll(prefs.getStringList(_seenAlertsKey) ?? const []);
  }

  Future<void> _saveSeenAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenAlertsKey, _seenAlertIds.toList());
  }

  Future<void> _pollAlerts() async {
    if (!mounted || _isDialogOpen) {
      return;
    }

    try {
      final response = await _tournamentService.getMyAlerts();
      if (!mounted || _isDialogOpen) return;
      TournamentAlert? alert;
      for (final candidate in response.alerts) {
        if (candidate.eventId.isNotEmpty &&
            !_seenAlertIds.contains(candidate.eventId)) {
          alert = candidate;
          break;
        }
      }

      if (alert == null) {
        return;
      }

      await _showTournamentAlert(alert);
    } catch (_) {
      // Keep polling silently.
    }
  }

  Future<void> _showTournamentAlert(TournamentAlert alert) async {
    if (!mounted) return;
    _isDialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TournamentAlertDialog(
          alert: alert,
          onClose: () {
            Navigator.of(dialogContext).pop();
          },
          onPrimaryTap: () async {
            Navigator.of(dialogContext).pop();
            await _handlePrimaryAction(alert);
          },
          onSecondaryTap: () async {
            Navigator.of(dialogContext).pop();
            await _handleSecondaryAction(alert);
          },
        );
      },
    );

    _seenAlertIds.add(alert.eventId);
    await _saveSeenAlerts();
    _isDialogOpen = false;
  }

  Future<void> _handlePrimaryAction(TournamentAlert alert) async {
    switch (alert.type) {
      case 'BRACKET_READY':
      case 'MATCH_STARTED':
        await _openTournamentLive(alert.tournament.id);
        break;
      case 'MATCH_FINISHED':
        await _openTournamentLive(alert.tournament.id);
        break;
      case 'TOURNAMENT_FINISHED':
        await _openTournamentDescription(alert.tournament.id);
        break;
      default:
        break;
    }
  }

  Future<void> _handleSecondaryAction(TournamentAlert alert) async {
    await _openTournamentDescription(alert.tournament.id);
  }

  Future<void> _openTournamentDescription(String tournamentId) async {
    if (tournamentId.isEmpty || !mounted) return;
    try {
      final tournament = await _tournamentService.getTournament(tournamentId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentDescriptionScreen(tournament: tournament),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No pudimos abrir el partido del torneo.')),
      );
    }
  }

  Future<void> _openTournamentLive(String tournamentId) async {
    if (tournamentId.isEmpty || !mounted) return;
    try {
      final tournament = await _tournamentService.getTournament(tournamentId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentLiveScreen(tournament: tournament),
        ),
      );
    } catch (_) {}
  }

  void _setTab(PgoNavTab tab) {
    if (_currentTab == tab) {
      return;
    }

    setState(() {
      _currentTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Stack(
        children: [
          PgoFooterScope(
            hasShellFooter: true,
            child: IndexedStack(
              index: PgoNavTab.values.indexOf(_currentTab),
              children: [
                HomeScreen(
                  showBottomNav: false,
                  initialProfile: widget.initialProfile,
                  onTournamentsTap: () => _setTab(PgoNavTab.tournaments),
                  onAlertsTap: () => _setTab(PgoNavTab.alerts),
                  onProfileTap: () => _setTab(PgoNavTab.profile),
                ),
                TournamentsScreen(
                  showBottomNav: false,
                  isActive: _currentTab == PgoNavTab.tournaments,
                  onBackTap: () => _setTab(PgoNavTab.home),
                  onHomeTap: () => _setTab(PgoNavTab.home),
                  onProfileTap: () => _setTab(PgoNavTab.profile),
                ),
                OpenMatchAlertsScreen(
                  onBackTap: () => _setTab(PgoNavTab.home),
                ),
                ProfileScreen(
                  showBottomNav: false,
                  openFriendsOnStart: widget.openProfileFriendsOnStart,
                  onBackTap: () => _setTab(PgoNavTab.home),
                  onHomeTap: () => _setTab(PgoNavTab.home),
                  onTournamentsTap: () => _setTab(PgoNavTab.tournaments),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PgoBottomNav(
              currentTab: _currentTab,
              onHomeTap: () => _setTab(PgoNavTab.home),
              onTournamentsTap: () => _setTab(PgoNavTab.tournaments),
              onAlertsTap: () => _setTab(PgoNavTab.alerts),
              onProfileTap: () => _setTab(PgoNavTab.profile),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentAlertDialog extends StatelessWidget {
  const _TournamentAlertDialog({
    required this.alert,
    required this.onClose,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final TournamentAlert alert;
  final VoidCallback onClose;
  final Future<void> Function() onPrimaryTap;
  final Future<void> Function() onSecondaryTap;

  bool get _isStarted => alert.type == 'MATCH_STARTED';
  bool get _isFinished => alert.type == 'MATCH_FINISHED';
  bool get _isTournamentFinished => alert.type == 'TOURNAMENT_FINISHED';

  String get _title {
    if (_isTournamentFinished) return 'Torneo finalizado';
    if (_isStarted) return 'Es tu turno';
    if (_isFinished) return 'Resultado registrado';
    return 'Tu partido está listo';
  }

  String get _subtitle {
    if (_isTournamentFinished) {
      return 'Ya puedes revisar los resultados finales\ndel torneo';
    }
    if (_isStarted) {
      return 'Tu partido está por comenzar\nDirígete a la cancha asignada';
    }
    if (_isFinished) {
      return 'Tu partido ha finalizado\nRevisa tu próximo cruce';
    }
    return 'Ya se generó tu cruce para el torneo';
  }

  String get _primaryLabel {
    if (_isTournamentFinished) return 'Ver resultados';
    if (_isStarted) return 'Entendido';
    if (_isFinished) return 'Ver siguiente partido';
    return 'Ver partido';
  }

  String get _secondaryLabel {
    if (_isTournamentFinished) return 'Ir al torneo';
    if (_isStarted) return 'Ver detalle';
    return 'Ir al torneo';
  }

  String get _matchStatusLabel {
    if (_isTournamentFinished) return 'Finalizado';
    if (_isStarted) return 'En llamado';
    if (_isFinished) return 'Finalizado';
    return 'Pendiente';
  }

  Color get _matchStatusColor {
    if (_isTournamentFinished) return const Color(0xFF9CA3AF);
    if (_isFinished) return const Color(0xFF9CA3AF);
    return const Color(0xFFD8F778);
  }

  String _formatDate(DateTime date) {
    return DateFormat("EEEE d 'de' MMMM", 'es').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final nextOrCurrent = alert.nextMatch ?? alert.match;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(34),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(30),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFAAB6CA),
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.PrimaryGreen,
                child: Icon(
                  _isTournamentFinished
                      ? Icons.emoji_events_rounded
                      : _isStarted
                          ? Icons.sports_tennis
                          : Icons.check_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 45 / 3,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF132742),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3A4760),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.tournament.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF132742),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.PrimaryGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isTournamentFinished
                                ? 'Finalizado'
                                : _isStarted
                                    ? 'En curso'
                                    : _isFinished
                                        ? 'En curso'
                                        : '${alert.tournament.registrationsCount} inscritos',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: Color(0xFF132742),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.tournament.category} categoría',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF243753)),
                    ),
                    Text(
                      _formatDate(alert.tournament.startsAt),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF243753)),
                    ),
                    Text(
                      alert.tournament.location,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF243753)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_isTournamentFinished)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _podiumRow(
                        '#1',
                        'Campeones',
                        alert.champions,
                        highlighted: true,
                      ),
                      const SizedBox(height: 10),
                      _podiumRow('#2', 'Subcampeones', alert.runnersUp),
                    ],
                  ),
                ),
              if (!_isTournamentFinished)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF274F85), Color(0xFF132742)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextOrCurrent.courtLabel.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _teamLine(nextOrCurrent.teamOne),
                            const Divider(
                              color: Color(0xFFD7DEE9),
                              height: 16,
                              thickness: 1,
                            ),
                            _teamLine(nextOrCurrent.teamTwo),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE d MMM', 'es')
                                  .format(nextOrCurrent.scheduledAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _matchStatusColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _matchStatusLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: Color(0xFF132742),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_isTournamentFinished) ...[
                const SizedBox(height: 10),
                Text(
                  'Tu resultado: ${alert.userResult ?? 'Participante'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF132742),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _actionButton(
                label: _primaryLabel,
                onTap: onPrimaryTap,
                filled: true,
              ),
              const SizedBox(height: 10),
              _actionButton(
                label: _secondaryLabel,
                onTap: onSecondaryTap,
                filled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _podiumRow(
    String position,
    String label,
    List<String> players, {
    bool highlighted = false,
  }) {
    final names = List<String>.from(players);
    while (names.length < 2) {
      names.add('Por definir');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFD8F778) : const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$position\n$label',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF132742),
              ),
            ),
          ),
          Expanded(
            child: Text(
              names[0],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF132742),
              ),
            ),
          ),
          Expanded(
            child: Text(
              names[1],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF132742),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamLine(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.isEmpty ? 'Por definir' : text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF132742),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Future<void> Function() onTap,
    required bool filled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => unawaited(onTap()),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? AppColors.PrimaryGreen : const Color(0xFFDDE3EC),
          foregroundColor: const Color(0xFF132742),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
