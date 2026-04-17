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
import 'tournament_admin_registrations_screen.dart';

class TournamentAdminScreen extends StatefulWidget {
  const TournamentAdminScreen({
    super.key,
    required this.tournament,
  });

  final TournamentRecord tournament;

  @override
  State<TournamentAdminScreen> createState() => _TournamentAdminScreenState();
}

class _TournamentAdminScreenState extends State<TournamentAdminScreen> {
  TournamentRecord? _tournament;
  bool _isLoading = false;
  bool _isUpdatingRegistrations = false;
  String? _error;

  TournamentRecord get _currentTournament => _tournament ?? widget.tournament;

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

  Future<void> _toggleRegistrations() async {
    if (_currentTournament.registrationsOpen) {
      final shouldClose = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => _CloseRegistrationsDialog(
          isComplete: _currentTournament.registrationsCount >=
              _currentTournament.playerCapacity,
          onGenerateBrackets: () async {
            Navigator.of(context).pop(true);
          },
        ),
      );

      if (shouldClose != true) {
        return;
      }
    }

    setState(() {
      _isUpdatingRegistrations = true;
    });

    try {
      late TournamentRecord updated;
      if (_currentTournament.registrationsOpen) {
        await TournamentService()
            .closeAndGenerateBracket(_currentTournament.id);
        updated =
            await TournamentService().getTournament(_currentTournament.id);
      } else {
        updated = await TournamentService().updateTournament(
          tournamentId: _currentTournament.id,
          registrationsOpen: true,
        );
      }
      if (!mounted) return;
      setState(() {
        _tournament = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.registrationsOpen
                ? 'Inscripciones abiertas nuevamente'
                : 'Inscripciones cerradas',
          ),
        ),
      );

      if (!updated.registrationsOpen) {
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
          _isUpdatingRegistrations = false;
        });
      }
    }
  }

  // ignore: unused_element
  String get _formattedHeroDate {
    final date = _currentTournament.startsAt.toLocal();
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

    final weekday = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$weekday ${date.day} $month · $hour:$minute';
  }

  List<String> get _recentActivity {
    final entries = [..._currentTournament.registrationEntries]
      ..sort((left, right) {
        final leftDate =
            left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate =
            right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightDate.compareTo(leftDate);
      });

    if (entries.isEmpty) {
      return const ['Aun no hay actividad reciente'];
    }

    final items = <String>[];
    for (final entry in entries.take(2)) {
      if (entry.hasPartner) {
        items.add(
          '${entry.user.name} y ${entry.partnerUser?.name ?? ''} se inscribieron',
        );
      } else {
        items.add('${entry.user.name} esta buscando pareja');
      }
    }
    items.add(
      '${_currentTournament.registrationsCount} de ${_currentTournament.playerCapacity} cupos completados',
    );
    return items;
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
          'Panel de torneo',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
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
                  _AdminHeroCard(
                    tournament: _currentTournament,
                    formattedDate: _formattedHeroDate,
                  ),
                  const SizedBox(height: 12),
                  _buildTabs(context),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PanelCard(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  _PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inscripciones abiertas',
                          style: GoogleFonts.inter(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.groups_2_outlined,
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.65),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_currentTournament.registrationsCount} de ${_currentTournament.playerCapacity} jugadores',
                              style: const TextStyle(
                                color: AppColors.SecondBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _currentTournament.playerCapacity <= 0
                                ? 0
                                : (_currentTournament.registrationsCount /
                                        _currentTournament.playerCapacity)
                                    .clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: const Color(0xFFB8C1D3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.PrimaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentTournament.registrationsOpen
                              ? 'Se cierra al completar cupos'
                              : 'Las inscripciones estan cerradas',
                          style: TextStyle(
                            color: AppColors.SecondBlue.withValues(alpha: 0.58),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionButton(
                          label: 'Ver inscritos',
                          filled: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    TournamentAdminRegistrationsScreen(
                                  tournament: _currentTournament,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          label: _currentTournament.registrationsOpen
                              ? 'Cerrar inscripciones'
                              : 'Abrir cupos',
                          filled: false,
                          enabled: !_isUpdatingRegistrations,
                          onTap: _toggleRegistrations,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen del torneo',
                          style: GoogleFonts.inter(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SummaryLine(
                          label: 'Cupos',
                          value: '${_currentTournament.playerCapacity}',
                        ),
                        _SummaryLine(
                          label: 'Formato',
                          value: _currentTournament.format,
                        ),
                        const _SummaryLine(
                          label: 'Inscripcion',
                          value: 'Con o sin pareja',
                        ),
                        _SummaryLine(
                          label: 'Costo',
                          value: 'S/${_currentTournament.entryFee} x persona',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actividad reciente',
                          style: GoogleFonts.inter(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._recentActivity.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RecentActivityText(text: item),
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
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Resumen',
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TournamentAdminRegistrationsScreen(
                      tournament: _currentTournament,
                    ),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Inscritos',
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TournamentAdminMatchesScreen(
                      tournament: _currentTournament,
                    ),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Partidos',
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TournamentAdminBracketScreen(
                      tournament: _currentTournament,
                    ),
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
        ],
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.tournament,
    required this.formattedDate,
  });

  final TournamentRecord tournament;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(tournament.photoUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 230,
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
                    Colors.black.withValues(alpha: 0.14),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          tournament.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
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
                  const SizedBox(height: 3),
                  Text(
                    '${tournament.category.toUpperCase()} categoria',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    tournament.location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  // ignore: unused_element
  String _formatDate(DateTime date) {
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
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]} · $hour:$minute';
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RecentActivityText extends StatelessWidget {
  const _RecentActivityText({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.inter(
      color: AppColors.SecondBlue.withValues(alpha: 0.82),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final boldStyle = GoogleFonts.inter(
      color: AppColors.SecondBlue.withValues(alpha: 0.92),
      fontSize: 13,
      fontWeight: FontWeight.w900,
    );

    final cuposMatch = RegExp(r'^(\d+ de \d+ cupos)(.*)$').firstMatch(text);
    if (cuposMatch != null) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: cuposMatch.group(1), style: boldStyle),
            TextSpan(text: cuposMatch.group(2) ?? ''),
          ],
        ),
      );
    }

    final splitText = text.split(' se ');
    if (splitText.length == 2) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: splitText.first, style: boldStyle),
            TextSpan(text: ' se ${splitText.last}'),
          ],
        ),
      );
    }

    final searchingText = text.split(' esta ');
    if (searchingText.length == 2) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: searchingText.first, style: boldStyle),
            TextSpan(text: ' esta ${searchingText.last}'),
          ],
        ),
      );
    }

    return Text(text, style: baseStyle);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? const Color(0xFFD7FF59) : const Color(0xFFE7EBF0),
          foregroundColor: AppColors.SecondBlue,
          disabledBackgroundColor:
              (filled ? const Color(0xFFD7FF59) : const Color(0xFFE7EBF0))
                  .withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
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
            color: AppColors.SecondBlue.withValues(alpha: 0.76),
            fontSize: 13,
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
    required this.onGenerateBrackets,
  });

  final bool isComplete;
  final Future<void> Function() onGenerateBrackets;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isComplete ? 'Cupos completos' : 'Cerrar inscripciones',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isComplete
                  ? 'El torneo ya completó sus cupos.\nTodos los inscritos tienen pareja\nYa puedes generar los cruces del torneo'
                  : 'Al cerrar las inscripciones ya no entrarán más jugadores.\nLuego podrás generar los cruces del torneo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.78),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EBF0),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onGenerateBrackets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Generar cruces',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
