import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'profile_public_preview_screen.dart';
import 'tournament_bracket_screen.dart';
import 'tournament_description_screen.dart';
import 'tournament_live_screen.dart';

class TournamentProfileScreen extends StatefulWidget {
  const TournamentProfileScreen({
    super.key,
    this.tournament,
  });

  final TournamentRecord? tournament;

  @override
  State<TournamentProfileScreen> createState() =>
      _TournamentProfileScreenState();
}

class _TournamentProfileScreenState extends State<TournamentProfileScreen> {
  TournamentRecord? _tournament;
  bool _isLoading = false;
  String? _loadError;
  final Set<String> _followingIds = <String>{};

  TournamentRecord? get _currentTournament => _tournament ?? widget.tournament;
  String get _title => _currentTournament?.title ?? 'Torneo PGO';
  String get _category => _currentTournament?.category ?? '4TA';
  String get _photoUrl => _currentTournament?.photoUrl ?? '';
  String get _createdByName =>
      _currentTournament?.createdByName ?? 'Organizador';
  String get _location => _currentTournament?.location ?? 'One Padel Trigal';
  List<TournamentPlayer> get _players =>
      _currentTournament?.registeredPlayers ?? const [];

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _loadTournament();
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

  void _toggleFollow(TournamentPlayer player) {
    setState(() {
      if (_followingIds.contains(player.id)) {
        _followingIds.remove(player.id);
      } else {
        _followingIds.add(player.id);
      }
    });
  }

  Future<void> _openPlayerProfile(TournamentPlayer player) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfilePublicPreviewScreen(
          profile: ProfileSummary(
            id: player.id,
            name: player.name,
            email: player.email ?? '',
            photoUrl: player.photoUrl,
            experiencePoints: 0,
            category: player.category,
            preferredClub: player.preferredClub,
            preferredSide: null,
            racketModel: null,
            experienceLevel: null,
            rankingPosition: player.rankingPosition,
            matchesPlayed: 0,
            wins: 0,
            winRate: 0,
            weeklyStreak: 0,
            friendsCount: 0,
            followersCount: 0,
            followingCount: 0,
            socialNotificationsCount: 0,
            matchHistory: const [],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        primaryTextTheme:
            GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
      ),
      child: PgoHeaderScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Actividad',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
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
                  padding: const EdgeInsets.fromLTRB(30, 14, 30, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTabs(context),
                      const SizedBox(height: 8),
                      _buildFriendsRegisteredBadge(),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_loadError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildInfoTile(
                            icon: Icons.warning_amber_rounded,
                            title: 'No pudimos actualizar los jugadores',
                            subtitle: _loadError!,
                          ),
                        ),
                      _buildOrganizerCard(),
                      const SizedBox(height: 16),
                      const Text(
                        'Jugadores',
                        style: TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_players.isEmpty)
                        _buildInfoTile(
                          icon: Icons.person_off_outlined,
                          title: 'Aun no hay jugadores visibles',
                          subtitle:
                              'Cuando existan inscripciones confirmadas apareceran aqui.',
                        )
                      else
                        ..._players.map(
                          (player) => _RegisteredPlayerTile(
                            player: player,
                            isFollowing: _followingIds.contains(player.id),
                            onFollowTap: () => _toggleFollow(player),
                            onProfileTap: () => _openPlayerProfile(player),
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
    );
  }

  Widget _buildHero() {
    final bytes = tryDecodeDataUrl(_photoUrl);
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(34)),
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
                  '${_category.toUpperCase()} categoria',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => TournamentDescriptionScreen(
                      tournament: _currentTournament,
                    ),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Descripcion',
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
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Jugadores',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsRegisteredBadge() {
    final count = _players.length;

    return Center(
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 13,
              color: Color(0xFFFF9800),
            ),
            const SizedBox(width: 3),
            Text(
              '$count amigos inscritos',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const _AvatarCircle(selected: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _createdByName,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Organizador del torneo',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD7FF59),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _category.toUpperCase(),
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
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
          Icon(
            icon,
            size: 22,
            color: AppColors.SecondBlue.withValues(alpha: 0.7),
          ),
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
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    this.selected = false,
    this.size = 40,
  });

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.PrimaryGreen,
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/Logo_Icono.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _RegisteredPlayerTile extends StatelessWidget {
  const _RegisteredPlayerTile({
    required this.player,
    required this.isFollowing,
    required this.onFollowTap,
    required this.onProfileTap,
  });

  final TournamentPlayer player;
  final bool isFollowing;
  final VoidCallback onFollowTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onProfileTap,
                customBorder: const CircleBorder(),
                child: const _AvatarCircle(size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Amigo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.58),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isFollowing) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3E6EA7),
                        Color(0xFF10192A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onFollowTap,
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: 58,
                        height: 21,
                        child: Center(
                          child: Text(
                            '+ Seguir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFD7FF59),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#${player.rankingPosition}',
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 44, top: 5),
            color: AppColors.SecondBlue.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}
