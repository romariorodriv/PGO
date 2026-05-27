import 'package:flutter/material.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tournament_admin_matches.dart';
import '../models/profile_summary.dart';
import '../models/tournament_record.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../utils/tournament_share_link.dart';
import '../utils/tournament_rules.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'tournament_bracket_screen.dart';
import 'tournament_live_screen.dart';
import 'tournament_profile_screen.dart';
import 'tournament_register_screen.dart';

class TournamentDescriptionScreen extends StatefulWidget {
  const TournamentDescriptionScreen({
    super.key,
    this.tournament,
    this.isPaid = false,
  });

  final TournamentRecord? tournament;
  final bool isPaid;

  @override
  State<TournamentDescriptionScreen> createState() =>
      _TournamentDescriptionScreenState();
}

class _TournamentDescriptionScreenState
    extends State<TournamentDescriptionScreen> {
  TournamentRecord? _tournament;
  ProfileSummary? _profile;
  bool _isLoading = false;
  bool _isLoadingProfile = false;
  String? _loadError;
  TournamentAdminMatchesData? _matchesData;

  TournamentRecord? get _currentTournament => _tournament ?? widget.tournament;
  String get _title => _currentTournament?.title ?? 'Torneo PGO';
  String get _category => _currentTournament?.category ?? '4TA';
  String get _location => _currentTournament?.location ?? 'One Padel Trigal';
  String get _prize => _currentTournament?.prize ?? 'S/ 250 en premios';
  String get _entryFee => _currentTournament != null
      ? 'S/.${_currentTournament!.entryFee}'
      : 'S/.60';
  String get _photoUrl => _currentTournament?.photoUrl ?? '';
  int get _playerCapacity => _currentTournament?.playerCapacity ?? 16;
  int get _registrationsCount => _currentTournament?.registrationsCount ?? 0;
  String get _format => _currentTournament?.format ?? 'dobles';
  List<TournamentPlayer> get _players =>
      _currentTournament?.registeredPlayers ?? const [];
  List<TournamentAdminMatch> get _matches =>
      _matchesData?.matches ?? const <TournamentAdminMatch>[];

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _loadTournament();
    _loadProfile();
    _loadMatches();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final profile = await ProfileService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
      });
    } catch (_) {
      // If profile loading fails, keep the previous CTA behavior.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadTournament() async {
    final tournamentId = widget.tournament?.id;
    if (tournamentId == null || tournamentId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final tournament = await TournamentService().getTournament(tournamentId);
      if (!mounted) return;
      setState(() {
        _tournament = tournament;
      });
      _loadMatches();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _formattedDate {
    if (_currentTournament == null) return 'Lunes 19 Dic';

    const weekDays = [
      'Lunes',
      'Martes',
      'Miercoles',
      'Jueves',
      'Viernes',
      'Sabado',
      'Domingo',
    ];
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    final date = _currentTournament!.startsAt.toLocal();
    final weekday = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$weekday ${date.day} $month - $hour:$minute';
  }

  String get _statusChipText {
    final tournament = _currentTournament;
    if (tournament == null) return 'torneo activo';
    return TournamentRules.statusLabel(tournament);
  }

  String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Sin definir';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  bool get _isCurrentUserRegistered {
    final userId = _profile?.id;
    final tournament = _currentTournament;
    if (userId == null || userId.isEmpty || tournament == null) {
      return false;
    }
    return tournament.registrationUserIds.contains(userId);
  }

  bool get _showJoinAction => !_isLoadingProfile && !_isCurrentUserRegistered;

  TournamentAdminMatch? get _myMatch {
    final manageable = _matches.where((match) => match.canManage).toList();
    if (manageable.isNotEmpty) {
      manageable.sort(_compareUserMatches);
      return manageable.first;
    }

    final profileName = (_profile?.name ?? '').trim().toLowerCase();
    if (profileName.isEmpty) return null;
    final relevant = _matches.where((match) {
      final teamOne = match.teamOne.toLowerCase();
      final teamTwo = match.teamTwo.toLowerCase();
      return teamOne.contains(profileName) || teamTwo.contains(profileName);
    }).toList();
    if (relevant.isEmpty) return null;
    relevant.sort(_compareUserMatches);
    return relevant.first;
  }

  int _compareUserMatches(
      TournamentAdminMatch left, TournamentAdminMatch right) {
    int rank(String status) => switch (status) {
          'LIVE' => 0,
          'PENDING' => 1,
          'FINISHED' => 2,
          _ => 3,
        };
    final statusCompare = rank(left.status).compareTo(rank(right.status));
    if (statusCompare != 0) return statusCompare;
    return left.scheduledAt.compareTo(right.scheduledAt);
  }

  TournamentPlayer? get _pairedPlayer {
    final userId = _profile?.id;
    final tournament = _currentTournament;
    if (userId == null || tournament == null) return null;
    for (final entry in tournament.registrationEntries) {
      if (entry.user.id == userId) return entry.partnerUser;
      if (entry.partnerUser?.id == userId) return entry.user;
    }
    return null;
  }

  Future<void> _loadMatches() async {
    final tournament = _currentTournament;
    if (tournament == null) return;
    try {
      final data =
          await TournamentService().getMyTournamentMatches(tournament.id);
      if (!mounted) return;
      setState(() {
        _matchesData = data;
      });
    } catch (_) {}
  }

  Future<void> _openClubInMaps() async {
    final tournament = _currentTournament;
    final query = [
      tournament?.location ?? _location,
      tournament?.address,
      tournament?.district,
      tournament?.city,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(', ');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir Maps.')),
      );
    }
  }

  Future<void> _shareTournament() async {
    final tournament = _currentTournament;
    if (tournament == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todavía no hay un link para compartir.')),
      );
      return;
    }

    final link = buildTournamentShareLink(tournament);
    await Share.share(link, subject: _title);
  }

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Actividad',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: const [PgoOptionsMenuButton()],
      bottomNavigationBar: _buildBottomNavigation(context),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 14, 30, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTabs(context),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildMessageCard(
                          icon: Icons.warning_amber_rounded,
                          title: 'No pudimos actualizar el torneo',
                          subtitle: _loadError!,
                        ),
                      ),
                    const SizedBox(height: 6),
                    _buildLocationRow(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openClubInMaps,
                            icon: const Icon(Icons.near_me_rounded, size: 17),
                            label: const Text('Ver club en Maps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.SecondBlue,
                              side: const BorderSide(
                                color: Color(0xFFD3DAE3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareTournament,
                            icon: const Icon(Icons.share_outlined, size: 17),
                            label: const Text('Compartir'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.SecondBlue,
                              side: const BorderSide(
                                color: Color(0xFFD3DAE3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildPlayersProgress(),
                    const SizedBox(height: 18),
                    _buildSimpleRow(
                      icon: Icons.emoji_events_outlined,
                      text: _prize,
                    ),
                    const SizedBox(height: 12),
                    _buildSimpleRow(
                      icon: Icons.monetization_on_outlined,
                      text: _entryFee,
                    ),
                    const SizedBox(height: 22),
                    _buildPlayersPreview(),
                    if (_isCurrentUserRegistered) ...[
                      const SizedBox(height: 18),
                      if (_pairedPlayer != null) ...[
                        _buildPairedNotification(_pairedPlayer!),
                        const SizedBox(height: 12),
                      ],
                      _buildMyMatchCard(),
                    ],
                    const SizedBox(height: 24),
                    if (_showJoinAction)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            final tournament = _currentTournament;
                            if (widget.isPaid || tournament == null) {
                              return;
                            }
                            if (!TournamentRules.canJoin(tournament)) {
                              return;
                            }
                            _handleRegisterTap(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD7FF59),
                            foregroundColor: AppColors.SecondBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            TournamentRules.joinLabel(
                              _currentTournament,
                              isPaid: widget.isPaid,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
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

  Future<void> _handleRegisterTap(BuildContext context) async {
    final currentTournament = _currentTournament;
    if (currentTournament == null ||
        !TournamentRules.canJoin(currentTournament)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TournamentRules.joinLabel(currentTournament))),
      );
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.84,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            child: TournamentRegisterScreen(
              tournament: currentTournament,
              isModal: true,
              scrollController: scrollController,
            ),
          );
        },
      ),
    );

    if (result != true || !context.mounted) {
      return;
    }

    try {
      final refreshed =
          await TournamentService().getTournament(currentTournament.id);
      if (!mounted) return;
      setState(() {
        _tournament = refreshed;
      });
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La inscripción se registró, pero no pudimos refrescar el torneo.',
          ),
        ),
      );
    }
  }

  Widget _buildHero() {
    final bytes = tryDecodeDataUrl(_photoUrl);
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _photoUrl.isNotEmpty
                ? _photoUrl.startsWith('http')
                    ? Image.network(
                        _photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          AppAssets.defaultTournamentImage,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (bytes != null
                        ? Image.memory(bytes, fit: BoxFit.cover)
                        : Image.asset(
                            AppAssets.defaultTournamentImage,
                            fit: BoxFit.cover,
                          ))
                : Image.asset(
                    AppAssets.defaultTournamentImage,
                    fit: BoxFit.cover,
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_category.toUpperCase()} categoría',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HeroChip(text: _statusChipText),
                    const SizedBox(width: 10),
                    _HeroChip(text: _capitalize(_format)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Descripción',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        TournamentBracketScreen(tournament: _currentTournament),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Bracket',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        TournamentLiveScreen(tournament: _currentTournament),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'En vivo',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        TournamentProfileScreen(tournament: _currentTournament),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Jugadores',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 22,
          color: Color(0xFFA8B1C1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _location,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formattedDate,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersProgress() {
    final progress = _playerCapacity <= 0
        ? 0.0
        : (_registrationsCount / _playerCapacity).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.groups_2_outlined,
          size: 22,
          color: Color(0xFFA8B1C1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_registrationsCount de $_playerCapacity jugadores',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFFAAB5CB)),
                      FractionallySizedBox(
                        widthFactor: progress,
                        alignment: Alignment.centerLeft,
                        child: const ColoredBox(color: AppColors.PrimaryGreen),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFFA8B1C1),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersPreview() {
    if (_players.isEmpty) {
      return _buildMessageCard(
        icon: Icons.person_off_outlined,
        title: 'Aún no hay jugadores inscritos',
        subtitle: 'Los participantes aparecerán aquí cuando se unan al torneo.',
      );
    }

    final previewPlayers = _players.take(4).toList();
    final remaining = _players.length - previewPlayers.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...previewPlayers.map(
            (player) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PreviewPlayer(
                label: player.name,
                photoUrl: player.photoUrl,
              ),
            ),
          ),
          if (remaining > 0) _PreviewMore(text: '+$remaining mas'),
        ],
      ),
    );
  }

  Widget _buildMyMatchCard() {
    final match = _myMatch;
    final hasGeneratedMatches = _matches.isNotEmpty;
    if (match == null) {
      return _buildMessageCard(
        icon: Icons.sports_tennis,
        title: hasGeneratedMatches
            ? 'Tu partido por ser asignado'
            : 'Tu partido se mostrará aquí',
        subtitle: hasGeneratedMatches
            ? 'Los cruces ya fueron generados. Cuando tengas cancha asignada, tu partido aparecerá aquí.'
            : 'Cuando el organizador genere cruces, tu próximo partido aparecerá aquí.',
      );
    }

    final statusLabel = switch (match.status) {
      'LIVE' => 'En curso',
      'FINISHED' => 'Finalizado',
      _ => 'Pendiente',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_tennis, color: AppColors.SecondBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  match.status == 'LIVE'
                      ? 'Tu próximo partido ya empezó'
                      : 'Tu próximo partido',
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: match.status == 'LIVE'
                      ? AppColors.PrimaryGreen
                      : const Color(0xFFE7EBF0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${match.courtLabel} - ${match.stageLabel}',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            match.teamOne,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Divider(height: 16),
          Text(
            match.teamTwo,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (match.status == 'PENDING' || match.status == 'LIVE') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  final tournament = _currentTournament;
                  if (tournament == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          TournamentLiveScreen(tournament: tournament),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'IR AL PARTIDO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (match.status == 'PENDING')
                  Expanded(
                    child: _SmallActionButton(
                      label: 'Iniciar',
                      onTap: () => _startUserMatch(match),
                    ),
                  ),
                if (match.status == 'PENDING') const SizedBox(width: 10),
                Expanded(
                  child: _SmallActionButton(
                    label: 'Registrar puntaje',
                    onTap: () => _showUserWinnerDialog(match),
                  ),
                ),
              ],
            ),
          ],
          if (match.status == 'FINISHED') ...[
            const SizedBox(height: 10),
            Text(
              'Ganador: ${match.winnerLabel ?? 'Por definir'}${(match.score ?? '').trim().isNotEmpty ? ' - ${match.score!.trim()}' : ''}',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPairedNotification(TournamentPlayer player) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7D8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: AppColors.SecondBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ya tienes dupla: ${player.name}',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ahora sigues a ${player.name}')),
            ),
            child: const Text('Seguir'),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mensajes aún no disponible')),
            ),
            child: const Text('Mensaje'),
          ),
        ],
      ),
    );
  }

  Future<void> _startUserMatch(TournamentAdminMatch match) async {
    final tournament = _currentTournament;
    if (tournament == null) return;
    try {
      await TournamentService().startTournamentMatch(
        tournamentId: tournament.id,
        matchId: match.id,
      );
      await _loadMatches();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showUserWinnerDialog(TournamentAdminMatch match) async {
    final scoreController = TextEditingController(text: match.score ?? '');
    var winner = match.teamOne;
    final result = await showDialog<({String winner, String score})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar resultado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogWinnerOption(
                label: match.teamOne,
                selected: winner == match.teamOne,
                onTap: () => setDialogState(() => winner = match.teamOne),
              ),
              _DialogWinnerOption(
                label: match.teamTwo,
                selected: winner == match.teamTwo,
                onTap: () => setDialogState(() => winner = match.teamTwo),
              ),
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Puntaje',
                  hintText: 'Ej. 6-4, 4-2, 11-9',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                (winner: winner, score: scoreController.text.trim()),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    scoreController.dispose();
    if (result == null || _currentTournament == null) return;
    try {
      await TournamentService().finishTournamentMatch(
        tournamentId: _currentTournament!.id,
        matchId: match.id,
        winnerLabel: result.winner,
        score: result.score,
      );
      await _loadMatches();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 22, color: AppColors.SecondBlue.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.68),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return PgoBottomNav(
      currentTab: PgoNavTab.tournaments,
      onHomeTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      },
      onTournamentsTap: () {},
      onProfileTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: const Color(0xFFD3DAE3),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PrimaryGreen,
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DialogWinnerOption extends StatelessWidget {
  const _DialogWinnerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.PrimaryGreen : const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: AppColors.SecondBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPlayer extends StatelessWidget {
  const _PreviewPlayer({
    required this.label,
    this.photoUrl,
  });

  final String label;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(photoUrl);
    final hasNetwork = photoUrl != null && photoUrl!.startsWith('http');

    return SizedBox(
      width: 42,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.PrimaryGreen,
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: hasNetwork
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackAvatar(),
                    )
                  : (bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : _fallbackAvatar()),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFE7EBF0),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: AppColors.SecondBlue.withValues(alpha: 0.42),
        size: 22,
      ),
    );
  }
}

class _PreviewMore extends StatelessWidget {
  const _PreviewMore({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.whatshot,
            size: 14,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
