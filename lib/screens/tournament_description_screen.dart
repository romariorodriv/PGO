import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
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

class _TournamentDescriptionScreenState extends State<TournamentDescriptionScreen> {
  TournamentRecord? _tournament;
  bool _isLoading = false;
  String? _loadError;

  TournamentRecord? get _currentTournament => _tournament ?? widget.tournament;
  String get _title => _currentTournament?.title ?? 'Torneo PGO';
  String get _category => _currentTournament?.category ?? '4TA';
  String get _location => _currentTournament?.location ?? 'One Padel Trigal';
  String get _prize => _currentTournament?.prize ?? 'S/ 250 en premios';
  String get _entryFee =>
      _currentTournament != null ? 'S/.${_currentTournament!.entryFee}' : 'S/.60';
  String get _photoUrl => _currentTournament?.photoUrl ?? '';
  int get _playerCapacity => _currentTournament?.playerCapacity ?? 16;
  int get _registrationsCount => _currentTournament?.registrationsCount ?? 0;
  String get _format => _currentTournament?.format ?? 'dobles';
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
    if (_currentTournament?.status == 'PUBLISHED' &&
        _currentTournament?.registrationsOpen == false) {
      return 'inscripciones cerradas';
    }
    switch (_currentTournament?.status) {
      case 'DRAFT':
        return 'borrador';
      case 'PUBLISHED':
        return 'inscripciones abiertas';
      case 'COMPLETED':
        return 'torneo finalizado';
      case 'CANCELED':
        return 'torneo cancelado';
      default:
        return 'torneo activo';
    }
  }

  String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Sin definir';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.isPaid ||
                              _currentTournament?.registrationsOpen == false ||
                              (_currentTournament != null &&
                                  _currentTournament!.registrationsCount >=
                                      _currentTournament!.playerCapacity)) {
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
                          widget.isPaid
                              ? 'IR AL PARTIDO'
                              : (_currentTournament?.registrationsOpen == false
                                  ? 'INSCRIPCIONES CERRADAS'
                                  : (_currentTournament != null &&
                                          _currentTournament!
                                                  .registrationsCount >=
                                              _currentTournament!.playerCapacity
                                      ? 'CUPOS COMPLETOS'
                                      : 'UNIRME')),
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
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TournamentRegisterScreen(
          tournament: currentTournament,
        ),
      ),
    );

    if (result != true || currentTournament == null || !context.mounted) {
      return;
    }

    try {
      final refreshed = await TournamentService().getTournament(currentTournament.id);
      if (!mounted) return;
      setState(() {
        _tournament = refreshed;
      });
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La inscripcion se registro, pero no pudimos refrescar el torneo.',
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
                          'assets/images/trigal_onepadel.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : (bytes != null
                        ? Image.memory(bytes, fit: BoxFit.cover)
                        : Image.asset(
                            'assets/images/trigal_onepadel.png',
                            fit: BoxFit.cover,
                          ))
                : Image.asset(
                    'assets/images/trigal_onepadel.png',
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
                  '${_category.toUpperCase()} categoria',
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
                'Descripcion',
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
        title: 'Aun no hay jugadores inscritos',
        subtitle: 'Los participantes apareceran aqui cuando se unan al torneo.',
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
          Icon(icon, size: 22, color: AppColors.SecondBlue.withValues(alpha: 0.7)),
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
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/Logo_Icono.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : (bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : Image.asset(
                          'assets/images/Logo_Icono.png',
                          fit: BoxFit.cover,
                        )),
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
