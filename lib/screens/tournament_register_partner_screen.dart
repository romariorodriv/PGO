import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/community_user.dart';
import '../models/tournament_record.dart';
import '../services/community_service.dart';
import '../services/tournament_service.dart';
import '../widgets/pgo_header_scaffold.dart';

class TournamentRegisterPartnerScreen extends StatefulWidget {
  const TournamentRegisterPartnerScreen({
    super.key,
    this.tournament,
  });

  final TournamentRecord? tournament;

  @override
  State<TournamentRegisterPartnerScreen> createState() =>
      _TournamentRegisterPartnerScreenState();
}

class _TournamentRegisterPartnerScreenState
    extends State<TournamentRegisterPartnerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  final TournamentService _tournamentService = TournamentService();

  CommunityUser? _selectedPartner;
  List<CommunityUser> _results = const [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _isSubmitting = false;

  TournamentRecord? get _tournament => widget.tournament;
  String get _title => _tournament?.title ?? 'Torneo PGO';
  String get _location => _tournament?.location ?? 'One Padel Trigal';
  int get _entryFee => _tournament?.entryFee ?? 60;

  String get _formattedDate {
    final startsAt = _tournament?.startsAt;
    if (startsAt == null) return 'Lunes 19 de Diciembre';
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
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final local = startsAt.toLocal();
    return '${weekDays[local.weekday - 1]} ${local.day} de ${months[local.month - 1]}';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = _searchController.text.trim();
      if (query.length < 2) {
        if (mounted) {
          setState(() {
            _results = const [];
          });
        }
        return;
      }

      setState(() {
        _isSearching = true;
      });

      try {
        final users = await _communityService.searchCommunity(query);
        if (!mounted) return;
        setState(() {
          _results = users;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = const [];
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _submit() async {
    final tournament = _tournament;
    final partner = _selectedPartner;
    if (tournament == null || partner == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _tournamentService.registerWithPartner(
        tournamentId: tournament.id,
        partnerUserId: partner.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inscripcion confirmada con ${partner.name}.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (_entryFee * 2) + 3;

    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Torneo',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
      ],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 140,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6C0D0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Center(
                child: Text(
                  'Inscripcion torneo',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFD3DAE3),
              ),
              const SizedBox(height: 20),
              _buildTournamentCard(),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFD3DAE3),
              ),
              const SizedBox(height: 18),
              const Text(
                'Costo de inscripcion:',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _PriceCard(
                tournament: 'S/${_entryFee * 2}',
                fee: 'S/3',
                total: 'S/$total',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _selectedPartner != null && !_isSubmitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7FF59),
                    disabledBackgroundColor:
                        const Color(0xFFD7FF59).withValues(alpha: 0.45),
                    foregroundColor: AppColors.SecondBlue,
                    disabledForegroundColor:
                        AppColors.SecondBlue.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'PAGAR S/$total',
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
    );
  }

  Widget _buildTournamentCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECF1),
        borderRadius: BorderRadius.circular(24),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF426EA6),
                  AppColors.SecondBlue,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Column(
              children: [
                const Text(
                  'Anade a tu dupla',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const _AvatarCircle(),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tu cupo',
                          style: TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7FF59),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'YO',
                          style: TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Busca a tu pareja',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF1F3F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedPartner != null) ...[
                        _PartnerResultTile(
                          user: _selectedPartner!,
                          selected: true,
                          onTap: () {
                            setState(() {
                              _selectedPartner = null;
                            });
                          },
                        ),
                      ] else if (_results.isNotEmpty) ...[
                        ..._results.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PartnerResultTile(
                              user: user,
                              onTap: () {
                                setState(() {
                                  _selectedPartner = user;
                                  _results = const [];
                                  _searchController.text = user.name;
                                });
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Busca por nombre para elegir a tu pareja.',
                          style: TextStyle(
                            color: AppColors.SecondBlue.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
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

class _PartnerResultTile extends StatelessWidget {
  const _PartnerResultTile({
    required this.user,
    required this.onTap,
    this.selected = false,
  });

  final CommunityUser user;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppColors.PrimaryGreen, width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            const _AvatarCircle(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user.category ?? 'Sin categoria',
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.PrimaryGreen),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
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

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.tournament,
    required this.fee,
    required this.total,
  });

  final String tournament;
  final String fee;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          _PriceRow(label: 'Torneo', value: tournament),
          const SizedBox(height: 10),
          _PriceRow(label: 'Comision PGO', value: fee),
          const SizedBox(height: 10),
          _PriceRow(label: 'Total', value: total, bold: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final fontWeight = bold ? FontWeight.w900 : FontWeight.w700;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: fontWeight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}
