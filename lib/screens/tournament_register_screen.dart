import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/community_user.dart';
import '../models/tournament_record.dart';
import '../services/community_service.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../utils/tournament_rules.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'qr_scanner_screen.dart';

enum TournamentRegistrationSheetStep {
  chooseMode,
  soloPreferences,
  partnerSelection,
  success,
}

enum TournamentRegistrationMode { solo, partner }

class TournamentRegisterScreen extends StatefulWidget {
  const TournamentRegisterScreen({
    super.key,
    this.tournament,
    this.isModal = false,
    this.scrollController,
    this.onGoToMyTournaments,
  });

  final TournamentRecord? tournament;
  final bool isModal;
  final ScrollController? scrollController;
  final VoidCallback? onGoToMyTournaments;

  @override
  State<TournamentRegisterScreen> createState() =>
      _TournamentRegisterScreenState();
}

class _TournamentRegisterScreenState extends State<TournamentRegisterScreen> {
  final TournamentService _tournamentService = TournamentService();
  final ProfileService _profileService = ProfileService();
  final CommunityService _communityService = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  TournamentRegistrationSheetStep _step =
      TournamentRegistrationSheetStep.chooseMode;
  TournamentRegistrationMode? _mode;
  CommunityUser? _selectedPartner;
  List<CommunityUser> _results = const [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _isScanningQr = false;
  String _preferredSide = 'Drive';
  String _availability = 'Flexible';
  String? _errorMessage;

  TournamentRecord? get _tournament => widget.tournament;
  String get _title => _tournament?.title ?? '';
  String get _location => _tournament?.location ?? '';
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
        if (mounted) setState(() => _results = const []);
        return;
      }

      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });

      try {
        final users = await _communityService.searchCommunity(query);
        if (!mounted) return;
        setState(() => _results = users);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _results = const [];
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _startSolo() async {
    setState(() {
      _mode = TournamentRegistrationMode.solo;
      _step = TournamentRegistrationSheetStep.soloPreferences;
      _errorMessage = null;
    });
  }

  Future<void> _startPartner() async {
    setState(() {
      _mode = TournamentRegistrationMode.partner;
      _step = TournamentRegistrationSheetStep.partnerSelection;
      _errorMessage = null;
    });
  }

  Future<void> _submitSolo() async {
    final tournament = _tournament;
    if (tournament == null || !TournamentRules.canJoin(tournament)) {
      _errorMessage = TournamentRules.joinBlockedReason(tournament);
      if (mounted) setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _profileService.getMyProfile();
      await _tournamentService.registerSolo(
        tournamentId: tournament.id,
        preferredSide: _preferredSide,
        availability: _availability,
      );
      if (!mounted) return;
      setState(() => _step = TournamentRegistrationSheetStep.success);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitPartner() async {
    final tournament = _tournament;
    final partner = _selectedPartner;
    if (tournament == null || partner == null) return;
    if (!TournamentRules.canJoin(tournament)) {
      setState(
          () => _errorMessage = TournamentRules.joinBlockedReason(tournament));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileService.getMyProfile();
      if (partner.id == profile.id) {
        throw Exception('No puedes inscribirte contigo mismo como dupla');
      }
      if (tournament.registrationUserIds.contains(partner.id)) {
        throw Exception('Ese jugador ya está inscrito en el torneo');
      }
      await _tournamentService.registerWithPartner(
        tournamentId: tournament.id,
        partnerUserId: partner.id,
      );
      if (!mounted) return;
      setState(() => _step = TournamentRegistrationSheetStep.success);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _scanPartnerQr() async {
    final rawValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (!mounted || rawValue == null || rawValue.trim().isEmpty) return;
    final query = _extractQueryFromQr(rawValue);

    setState(() {
      _isScanningQr = true;
      _errorMessage = null;
    });

    try {
      final results = await _communityService.searchCommunity(query);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _errorMessage = 'No encontramos un jugador para ese QR');
        return;
      }
      final player = results.first;
      setState(() {
        _selectedPartner = player;
        _results = const [];
        _searchController.text = player.name;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isScanningQr = false);
    }
  }

  String _extractQueryFromQr(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return '';
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id']?.toString().trim() ?? '';
        final email = decoded['email']?.toString().trim() ?? '';
        final name = decoded['name']?.toString().trim() ?? '';
        return [id, email, name]
            .firstWhere((value) => value.isNotEmpty, orElse: () => trimmed);
      }
    } catch (_) {}
    return trimmed;
  }

  String _friendlyError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).viewPadding.bottom;
    final canJoin =
        _tournament != null && TournamentRules.canJoin(_tournament!);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dragHandle(),
        const SizedBox(height: 28),
        Center(
          child: Text(
            'Inscripción torneo',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _divider(),
        const SizedBox(height: 18),
        _tournamentCard(),
        const SizedBox(height: 18),
        _divider(),
        const SizedBox(height: 14),
        if (_errorMessage != null) ...[
          _errorBanner(_errorMessage!),
          const SizedBox(height: 12),
        ],
        if (_step == TournamentRegistrationSheetStep.chooseMode)
          _buildChooseMode(canJoin)
        else if (_step == TournamentRegistrationSheetStep.soloPreferences)
          _buildSoloPreferences(canJoin)
        else if (_step == TournamentRegistrationSheetStep.partnerSelection)
          _buildPartnerSelection(canJoin)
        else
          _buildSuccess(),
      ],
    );

    final content = SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(24, 10, 24, 24 + bottomPadding),
      child: body,
    );

    if (widget.isModal) {
      return Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: content,
        ),
      );
    }

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
      actions: const [PgoOptionsMenuButton()],
      body: Container(
        color: const Color(0xFFF2F3F5),
        child: content,
      ),
    );
  }

  Widget _buildChooseMode(bool canJoin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '¿Cómo quieres inscribirte?',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _optionTile(
          icon: Icons.groups,
          title: 'Con pareja',
          subtitle: 'Inscríbete con tu dupla y confirma tu cupo al instante.',
          onTap: canJoin ? _startPartner : null,
        ),
        const SizedBox(height: 12),
        _optionTile(
          icon: Icons.person,
          title: 'Sin pareja',
          subtitle: 'Te ayudamos a encontrar una dupla para este torneo.',
          onTap: canJoin ? _startSolo : null,
        ),
        const SizedBox(height: 18),
        _priceCard(),
      ],
    );
  }

  Widget _buildSoloPreferences(bool canJoin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Participarás sin pareja',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _infoBox(
          'Te ayudamos a encontrar una dupla para este torneo. Mientras tanto, define tus preferencias para emparejarte mejor.',
        ),
        const SizedBox(height: 16),
        Text('Tu lado preferido', style: _sectionLabel()),
        const SizedBox(height: 10),
        _segmented(
          ['Drive', 'Reves', 'Indistinto'],
          _preferredSide,
          (value) => setState(() => _preferredSide = value),
        ),
        const SizedBox(height: 16),
        Text('Disponibilidad', style: _sectionLabel()),
        const SizedBox(height: 10),
        _segmented(
          ['Flexible', 'Tarde', 'Noche'],
          _availability,
          (value) => setState(() => _availability = value),
        ),
        const SizedBox(height: 16),
        _actions(
          backLabel: 'Volver',
          onBack: () => setState(() {
            _step = TournamentRegistrationSheetStep.chooseMode;
            _errorMessage = null;
          }),
          primaryLabel:
              _isSubmitting ? 'Confirmando...' : 'Confirmar inscripción',
          onPrimary: canJoin && !_isSubmitting ? _submitSolo : null,
        ),
      ],
    );
  }

  Widget _buildPartnerSelection(bool canJoin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Inscripción con pareja',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _infoBox('Busca a tu dupla por nombre, correo o QR.'),
        const SizedBox(height: 16),
        _searchField(),
        const SizedBox(height: 10),
        if (_isSearching || _isScanningQr) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ] else if (_results.isNotEmpty) ...[
          for (final user in _results) _partnerTile(user),
        ] else if (_selectedPartner != null) ...[
          _partnerSelectedTile(_selectedPartner!),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _scanPartnerQr,
                child: const Text('Usar QR'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _actions(
          backLabel: 'Volver',
          onBack: () => setState(() {
            _step = TournamentRegistrationSheetStep.chooseMode;
            _errorMessage = null;
          }),
          primaryLabel:
              _isSubmitting ? 'Confirmando...' : 'Confirmar inscripción',
          onPrimary: canJoin && !_isSubmitting && _selectedPartner != null
              ? _submitPartner
              : null,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final solo = _mode == TournamentRegistrationMode.solo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            solo ? 'Solicitud registrada' : 'Inscripción registrada',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _infoBox(
          solo
              ? 'Estamos buscando una dupla para ti.\nTu participación será confirmada cuando completemos tu pareja.'
              : 'Tu dupla quedó confirmada y el cupo ya está reservado.',
        ),
        const SizedBox(height: 16),
        _successCard(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7FF59),
              foregroundColor: AppColors.SecondBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Ver torneo',
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              widget.onGoToMyTournaments?.call();
              Navigator.of(context).pop(true);
            },
            child: Text(
              'Ir a mis torneos',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tournamentCard() {
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
                colors: [Color(0xFF426EA6), AppColors.SecondBlue],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: _whiteTitle()),
                const SizedBox(height: 4),
                Text(_formattedDate, style: _whiteSub()),
                Text(_location, style: _whiteSub()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Inscripción torneo',
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _priceCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard() {
    const fee = 3;
    final total = _entryFee + fee;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _priceRow('Torneo', 'S/$_entryFee'),
          const SizedBox(height: 10),
          _priceRow('Comisión PGO', 'S/$fee'),
          const SizedBox(height: 10),
          _priceRow('Total', 'S/$total', bold: true),
        ],
      ),
    );
  }

  Widget _successCard() {
    final solo = _mode == TournamentRegistrationMode.solo;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(solo ? Icons.hourglass_bottom_rounded : Icons.verified_rounded,
              color: AppColors.PrimaryGreen, size: 40),
          const SizedBox(height: 10),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formattedDate,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar jugador por nombre o correo',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: _scanPartnerQr,
          icon: const Icon(Icons.qr_code_rounded),
        ),
      ),
    );
  }

  Widget _partnerTile(CommunityUser user) {
    final selected = _selectedPartner?.id == user.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedPartner = user),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDFF7A6) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? AppColors.PrimaryGreen : const Color(0xFFE8ECF2),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF0F3F7),
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: AppColors.SecondBlue)),
                    const SizedBox(height: 2),
                    Text(user.email ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                AppColors.SecondBlue.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.PrimaryGreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _partnerSelectedTile(CommunityUser user) => _partnerTile(user);

  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? const Color(0xFFE8ECF2) : const Color(0xFFF0F0F0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: AppColors.SecondBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: AppColors.SecondBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: AppColors.SecondBlue.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmented(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (value) => ChoiceChip(
              label: Text(value),
              selected: selected == value,
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(),
    );
  }

  Widget _actions({
    required String backLabel,
    required VoidCallback onBack,
    required String primaryLabel,
    required VoidCallback? onPrimary,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7FF59),
              foregroundColor: AppColors.SecondBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    primaryLabel,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onBack,
            child: Text(
              backLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: double.infinity,
        height: 1,
        color: const Color(0xFFD3DAE3),
      );

  Widget _dragHandle() => Center(
        child: Container(
          width: 140,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFB6C0D0),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message,
          style: GoogleFonts.inter(
            color: const Color(0xFF9D1B1B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _infoBox(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message,
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue.withValues(alpha: 0.72),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      );

  TextStyle _sectionLabel() => GoogleFonts.inter(
        color: AppColors.SecondBlue,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      );

  TextStyle _whiteTitle() => GoogleFonts.inter(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      );

  TextStyle _whiteSub() => GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  Widget _priceRow(String label, String value, {bool bold = false}) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 15,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      );
}
