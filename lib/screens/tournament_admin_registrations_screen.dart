import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'tournament_admin_bracket_generated_screen.dart';
import 'tournament_admin_bracket_screen.dart';
import 'tournament_admin_matches_screen.dart';
import 'tournament_admin_screen.dart';

class TournamentAdminRegistrationsScreen extends StatefulWidget {
  const TournamentAdminRegistrationsScreen({
    super.key,
    required this.tournament,
  });

  final TournamentRecord tournament;

  @override
  State<TournamentAdminRegistrationsScreen> createState() =>
      _TournamentAdminRegistrationsScreenState();
}

class _TournamentAdminRegistrationsScreenState
    extends State<TournamentAdminRegistrationsScreen> {
  TournamentRecord? _tournament;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;
  _AdminRegistrationFilter _filter = _AdminRegistrationFilter.all;

  TournamentRecord get _currentTournament => _tournament ?? widget.tournament;

  List<TournamentRegistrationEntry> get _entries {
    final entries = _currentTournament.registrationEntries;
    switch (_filter) {
      case _AdminRegistrationFilter.all:
        return entries;
      case _AdminRegistrationFilter.withPartner:
        return entries.where((entry) => entry.hasPartner).toList();
      case _AdminRegistrationFilter.solo:
        return entries.where((entry) => !entry.hasPartner).toList();
    }
  }

  int get _soloCount => _currentTournament.registrationEntries
      .where((entry) => !entry.hasPartner)
      .length;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _loadTournament();
  }

  Future<void> _loadTournament() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournament =
          await TournamentService().getTournament(_currentTournament.id);
      if (!mounted) return;
      setState(() {
        _tournament = tournament;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCloseAction() async {
    if (_currentTournament.registrationsOpen) {
      final shouldClose = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => _CloseRegistrationsDialog(
          isComplete: _currentTournament.registrationsCount >=
              _currentTournament.playerCapacity,
          registrationsCount: _currentTournament.registrationsCount,
          playerCapacity: _currentTournament.playerCapacity,
          pendingPairs: _currentTournament.registrationEntries
              .where((entry) => !entry.hasPartner)
              .length,
          canGenerate: _currentTournament.registrationsCount >= 8,
          onGenerateBrackets: () async {
            Navigator.of(context).pop(true);
          },
        ),
      );

      if (shouldClose == true) {
        await _toggleRegistrations(open: false, goToBracket: true);
      }
      return;
    }

    await _toggleRegistrations(open: true, goToBracket: false);
  }

  Future<void> _toggleRegistrations({
    required bool open,
    required bool goToBracket,
  }) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      late TournamentRecord updated;
      if (goToBracket) {
        await TournamentService()
            .closeAndGenerateBracket(_currentTournament.id);
        updated =
            await TournamentService().getTournament(_currentTournament.id);
      } else {
        updated = await TournamentService().updateTournament(
          tournamentId: _currentTournament.id,
          registrationsOpen: open,
        );
      }

      if (!mounted) return;

      setState(() {
        _tournament = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            open
                ? 'Inscripciones abiertas nuevamente'
                : 'Inscripciones cerradas',
          ),
        ),
      );

      if (goToBracket) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TournamentAdminBracketGeneratedScreen(
              tournament: updated,
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showRegistrationDetails(TournamentRegistrationEntry entry) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.hasPartner
                    ? '${entry.user.name} / ${entry.partnerUser?.name ?? ''}'
                    : entry.user.name,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFD8DEE8)),
              const SizedBox(height: 14),
              _DetailLine(label: 'Estado', value: entry.statusLabel),
              _DetailLine(
                label: 'Modo',
                value: entry.hasPartner ? 'Con pareja' : 'Sin pareja',
              ),
              if ((entry.preferredSide ?? '').isNotEmpty)
                _DetailLine(label: 'Lado', value: entry.preferredSide!),
              if ((entry.availability ?? '').isNotEmpty)
                _DetailLine(label: 'Horario', value: entry.availability!),
              _DetailLine(
                label: 'Categoria',
                value: entry.user.category ?? 'Sin categoria',
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE7EBF0),
                    foregroundColor: AppColors.SecondBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeRegistration(TournamentRegistrationEntry entry) async {
    setState(() => _isUpdating = true);
    try {
      final updated = await TournamentService().removeAdminRegistration(
        tournamentId: _currentTournament.id,
        registrationId: entry.id,
      );
      if (!mounted) return;
      setState(() {
        _tournament = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripcion quitada')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _pairRegistration(TournamentRegistrationEntry entry) async {
    final partner = await showModalBottomSheet<TournamentRegistrationEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PairRegistrationSheet(
        currentEntry: entry,
        availableEntries: _currentTournament.registrationEntries
            .where((candidate) =>
                !candidate.hasPartner && candidate.id != entry.id)
            .toList(),
      ),
    );

    if (partner == null) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final updated = await TournamentService().pairAdminRegistrations(
        tournamentId: _currentTournament.id,
        registrationId: entry.id,
        partnerRegistrationId: partner.id,
      );
      if (!mounted) return;
      setState(() {
        _tournament = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${entry.user.name} y ${partner.user.name} ahora forman una dupla',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Panel de torneo',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: const [PgoOptionsMenuButton()],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: RefreshIndicator(
          onRefresh: _loadTournament,
          color: AppColors.SecondBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminHeroCard(tournament: _currentTournament),
                const SizedBox(height: 12),
                _AdminTabs(
                  current: _AdminTab.inscriptions,
                  tournament: _currentTournament,
                ),
                const SizedBox(height: 12),
                _RegistrationFilterBar(
                  filter: _filter,
                  onChanged: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 14),
                _ProgressSummary(
                  registrationsCount: _currentTournament.registrationsCount,
                  playerCapacity: _currentTournament.playerCapacity,
                  soloCount: _soloCount,
                ),
                const SizedBox(height: 14),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  _SimpleCard(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (_entries.isEmpty)
                  const _SimpleCard(
                    child: Text(
                      'Aun no hay inscripciones en esta vista.',
                      style: TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  ..._entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RegistrationCard(
                        entry: entry,
                        onView: () => _showRegistrationDetails(entry),
                        onPair: entry.hasPartner || _isUpdating
                            ? null
                            : () => _pairRegistration(entry),
                        onRemove: _isUpdating
                            ? null
                            : () => _removeRegistration(entry),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _handleCloseAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      foregroundColor: AppColors.SecondBlue,
                      disabledBackgroundColor:
                          const Color(0xFFD7FF59).withValues(alpha: 0.55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentTournament.registrationsOpen
                          ? 'Cerrar inscripciones'
                          : 'Abrir cupos',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _AdminRegistrationFilter { all, withPartner, solo }

enum _AdminTab { summary, inscriptions, matches, bracket }

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.tournament,
  });

  final TournamentRecord tournament;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(tournament.photoUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tournament.photoUrl != null && tournament.photoUrl!.isNotEmpty)
              tournament.photoUrl!.startsWith('http')
                  ? Image.network(
                      tournament.photoUrl!,
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
            else
              Image.asset(
                AppAssets.defaultTournamentImage,
                fit: BoxFit.cover,
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tournament.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E58C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tournament.registrationsOpen
                              ? 'Pendiente'
                              : 'Cerrado',
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${tournament.category.toUpperCase()} categoria',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formattedDate(tournament.startsAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    tournament.location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate(DateTime date) {
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
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]} - $hour:$minute';
  }
}

class _AdminTabs extends StatelessWidget {
  const _AdminTabs({
    required this.current,
    required this.tournament,
  });

  final _AdminTab current;
  final TournamentRecord tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          _AdminTabButton(
            label: 'Resumen',
            selected: current == _AdminTab.summary,
            onTap: () {
              if (current == _AdminTab.summary) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TournamentAdminScreen(
                    tournament: tournament,
                  ),
                ),
              );
            },
          ),
          _AdminTabButton(
            label: 'Inscritos',
            selected: current == _AdminTab.inscriptions,
            onTap: () {},
          ),
          _AdminTabButton(
            label: 'Partidos',
            selected: current == _AdminTab.matches,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) =>
                      TournamentAdminMatchesScreen(tournament: tournament),
                ),
              );
            },
          ),
          _AdminTabButton(
            label: 'Bracket',
            selected: current == _AdminTab.bracket,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TournamentAdminBracketScreen(
                    tournament: tournament,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminTabButton extends StatelessWidget {
  const _AdminTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: selected ? AppColors.secondaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.SecondBlue.withValues(alpha: 0.84),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationFilterBar extends StatelessWidget {
  const _RegistrationFilterBar({
    required this.filter,
    required this.onChanged,
  });

  final _AdminRegistrationFilter filter;
  final ValueChanged<_AdminRegistrationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _FilterButton(
            label: 'Todos',
            selected: filter == _AdminRegistrationFilter.all,
            onTap: () => onChanged(_AdminRegistrationFilter.all),
          ),
          _FilterButton(
            label: 'Con pareja',
            selected: filter == _AdminRegistrationFilter.withPartner,
            onTap: () => onChanged(_AdminRegistrationFilter.withPartner),
          ),
          _FilterButton(
            label: 'Sin pareja',
            selected: filter == _AdminRegistrationFilter.solo,
            onTap: () => onChanged(_AdminRegistrationFilter.solo),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: selected ? AppColors.secondaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.SecondBlue.withValues(alpha: 0.84),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.registrationsCount,
    required this.playerCapacity,
    required this.soloCount,
  });

  final int registrationsCount;
  final int playerCapacity;
  final int soloCount;

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups_2_outlined,
                color: AppColors.SecondBlue.withValues(alpha: 0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$registrationsCount de $playerCapacity jugadores',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (soloCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD7FF59),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$soloCount buscando dupla',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: playerCapacity <= 0
                  ? 0
                  : (registrationsCount / playerCapacity).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFB8C1D3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.PrimaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({
    required this.entry,
    required this.onView,
    required this.onPair,
    required this.onRemove,
  });

  final TournamentRegistrationEntry entry;
  final VoidCallback onView;
  final VoidCallback? onPair;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(photoUrl: entry.user.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: entry.user.name,
                            style: const TextStyle(
                              color: AppColors.SecondBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (entry.hasPartner)
                            TextSpan(
                              text: ' / ${entry.partnerUser?.name ?? ''}',
                              style: TextStyle(
                                color: AppColors.SecondBlue.withValues(
                                    alpha: 0.55),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(
                          text: entry.statusLabel,
                          highlighted: true,
                        ),
                        if (!entry.hasPartner &&
                            (entry.preferredSide ?? '').isNotEmpty)
                          _Tag(text: entry.preferredSide!),
                        if (!entry.hasPartner &&
                            (entry.availability ?? '').isNotEmpty)
                          _Tag(text: entry.availability!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onView,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.SecondBlue,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFDCE2EB),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!entry.hasPartner) ...[
                Expanded(
                  child: _CardActionButton(
                    label: 'Emparejar',
                    icon: Icons.person_add_alt_1,
                    backgroundColor: const Color(0xFFD7FF59),
                    onTap: onPair,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _CardActionButton(
                  label: 'Ver',
                  icon: Icons.visibility_outlined,
                  backgroundColor: entry.hasPartner
                      ? const Color(0xFFD7FF59)
                      : const Color(0xFFE7EBF0),
                  onTap: onView,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardActionButton(
                  label: 'Quitar',
                  icon: Icons.remove_circle_outline,
                  backgroundColor: const Color(0xFFE7EBF0),
                  onTap: onRemove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairRegistrationSheet extends StatelessWidget {
  const _PairRegistrationSheet({
    required this.currentEntry,
    required this.availableEntries,
  });

  final TournamentRegistrationEntry currentEntry;
  final List<TournamentRegistrationEntry> availableEntries;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emparejar a ${currentEntry.user.name}',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona otro jugador inscrito sin pareja.',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            if (availableEntries.isEmpty)
              const Text(
                'No hay otro jugador solo disponible para emparejar.',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: availableEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = availableEntries[index];
                    return ListTile(
                      onTap: () => Navigator.of(context).pop(entry),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      tileColor: const Color(0xFFF2F4F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: _Avatar(photoUrl: entry.user.photoUrl),
                      title: Text(
                        entry.user.name,
                        style: const TextStyle(
                          color: AppColors.SecondBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if ((entry.preferredSide ?? '').isNotEmpty)
                            _Tag(text: entry.preferredSide!),
                          if ((entry.availability ?? '').isNotEmpty)
                            _Tag(text: entry.availability!),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.SecondBlue,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          side: BorderSide.none,
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
  });

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(photoUrl);

    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.PrimaryGreen, width: 1.3),
      ),
      child: ClipOval(
        child: (photoUrl != null && photoUrl!.isNotEmpty)
            ? (photoUrl!.startsWith('http')
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
                      )))
            : Image.asset(
                'assets/images/Logo_Icono.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    this.highlighted = false,
  });

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFD7FF59) : AppColors.SecondBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlighted ? AppColors.SecondBlue : Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseRegistrationsDialog extends StatelessWidget {
  const _CloseRegistrationsDialog({
    required this.isComplete,
    this.registrationsCount = 0,
    this.playerCapacity = 0,
    this.pendingPairs = 0,
    this.canGenerate = false,
    required this.onGenerateBrackets,
  });

  final bool isComplete;
  final int registrationsCount;
  final int playerCapacity;
  final int pendingPairs;
  final bool canGenerate;
  final Future<void> Function() onGenerateBrackets;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isComplete && pendingPairs == 0) ...[
                Text(
                  'Cupos completos',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'El torneo ya completo sus cupos.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Todos los inscritos tienen pareja',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ya puedes generar los cruces del torneo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ] else ...[
                Text(
                  'Cerrar inscripciones',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ya no podran registrarse mas jugadores\n'
                  'en el torneo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$registrationsCount de $playerCapacity jugadores inscritos',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (pendingPairs > 0) ...[
                  const SizedBox(height: 4),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(text: '$pendingPairs buscando pareja \u00b7 '),
                        const TextSpan(
                          text: 'emparejar antes de\n',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const TextSpan(
                          text: 'generar cruces',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
                if (pendingPairs > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: const Color(0xFFD3DAE3),
                  ),
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 12),
                Text(
                  'El torneo continuara con los jugadores\n'
                  'actualmente confirmados',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (pendingPairs > 0) ...[
                  Text(
                    'Debes emparejar a los jugadores pendientes\n'
                    'antes de generar los cruces.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDDE1E6),
                          foregroundColor: AppColors.SecondBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Volver',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: (isComplete && !canGenerate)
                            ? null
                            : onGenerateBrackets,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD7FF59),
                          foregroundColor: AppColors.SecondBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          isComplete
                              ? 'Generar cruces'
                              : 'Cerrar inscripciones',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
