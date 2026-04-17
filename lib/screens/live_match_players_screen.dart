import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../constants/lima_padel_clubs.dart';
import '../models/community_user.dart';
import '../models/profile_summary.dart';
import '../models/selected_player.dart';
import '../services/community_service.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'live_match_setup_screen.dart';
import 'qr_scanner_screen.dart';

class LiveMatchPlayersScreen extends StatefulWidget {
  const LiveMatchPlayersScreen({
    super.key,
    required this.isCompetitive,
  });

  final bool isCompetitive;

  @override
  State<LiveMatchPlayersScreen> createState() => _LiveMatchPlayersScreenState();
}

class _LiveMatchPlayersScreenState extends State<LiveMatchPlayersScreen> {
  static const _fallbackClubName = 'One Padel Olguin';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final CommunityService _communityService = CommunityService();
  Timer? _searchDebounce;

  ProfileSummary? _profile;
  List<CommunityUser> _communityUsers = const [];
  List<CommunityUser> _searchResults = const [];
  final List<SelectedPlayer?> _selectedPlayers = List<SelectedPlayer?>.filled(
    4,
    null,
  );

  bool _isLoadingProfile = true;
  bool _isLoadingCommunity = true;
  bool _isSearching = false;
  String? _selectedClubName;
  String? _profileError;
  String? _communityError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProfile(),
      _loadCommunity(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _selectedClubName ??=
            profile.preferredClub ?? _fallbackClubName;
        _selectedPlayers[0] = SelectedPlayer(
          id: profile.id,
          name: profile.name,
          photoUrl: profile.photoUrl,
          category: profile.category,
          rankingPosition: profile.rankingPosition,
          locked: true,
        );
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadCommunity({String? query}) async {
    final isSearch = query != null && query.trim().isNotEmpty;

    setState(() {
      if (isSearch) {
        _isSearching = true;
      } else {
        _isLoadingCommunity = true;
      }
    });

    try {
      final users = isSearch
          ? await _communityService.searchCommunity(query.trim())
          : await _communityService.getSuggestions();
      if (!mounted) return;
      setState(() {
        if (isSearch) {
          _searchResults = users;
        } else {
          _communityUsers = users;
          _searchResults = const [];
        }
        _communityError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _communityError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          if (isSearch) {
            _isSearching = false;
          } else {
            _isLoadingCommunity = false;
          }
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (value.trim().isEmpty) {
        setState(() {
          _searchResults = const [];
          _communityError = null;
        });
        return;
      }
      _loadCommunity(query: value);
    });
  }

  void _focusSearchInput() {
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  bool _isAlreadySelected(String userId) {
    return _selectedPlayers.any((player) => player?.id == userId);
  }

  void _addPlayer(CommunityUser user) {
    if (_isAlreadySelected(user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese jugador ya fue agregado')),
      );
      return;
    }

    final slotIndex = _selectedPlayers.indexWhere((player) => player == null);
    if (slotIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya completaste los 4 jugadores')),
      );
      return;
    }

    setState(() {
      _selectedPlayers[slotIndex] = SelectedPlayer(
        id: user.id,
        name: user.name,
        photoUrl: user.photoUrl,
        category: user.category,
        rankingPosition: user.rankingPosition,
      );
      _searchController.clear();
      _searchResults = const [];
    });
  }

  void _removePlayer(int index) {
    final player = _selectedPlayers[index];
    if (player == null || player.locked) {
      return;
    }

    setState(() {
      _selectedPlayers[index] = null;
    });
  }

  Future<void> _handleQrScan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (!mounted || code == null || code.trim().isEmpty) {
      return;
    }

    try {
      final qrQuery = _extractQrQuery(code.trim());
      final users = await _communityService.searchCommunity(qrQuery);
      if (!mounted) return;
      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No encontramos un jugador para ese QR')),
        );
        return;
      }

      final normalized = qrQuery.toLowerCase();
      final user = users.firstWhere(
        (item) =>
            item.id.toLowerCase() == normalized ||
            item.name.toLowerCase() == normalized ||
            (item.email?.toLowerCase() == normalized),
        orElse: () => users.first,
      );
      _addPlayer(user);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _extractQrQuery(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'] as String?;
        final email = decoded['email'] as String?;
        final name = decoded['name'] as String?;
        if (id != null && id.trim().isNotEmpty) return id.trim();
        if (email != null && email.trim().isNotEmpty) return email.trim();
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    } catch (_) {}
    return raw;
  }

  void _goNext() {
    if (_profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debemos cargar tu perfil')),
      );
      return;
    }

    if (_selectedPlayers.any((player) => player == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar los 4 jugadores antes de continuar'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveMatchSetupScreen(
          isCompetitive: widget.isCompetitive,
          profile: _profile!,
          players: _selectedPlayers.whereType<SelectedPlayer>().toList(),
          clubName: _clubName,
        ),
      ),
    );
  }

  List<CommunityUser> get _displayUsers =>
      _searchController.text.trim().isEmpty ? _communityUsers : _searchResults;

  String get _clubName =>
      _selectedClubName ??
      _profile?.preferredClub ??
      _fallbackClubName;

  bool get _canContinue =>
      _selectedPlayers.every((player) => player != null);

  Future<void> _pickClub() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClubPickerSheet(
        current: _clubName,
        clubs: limaPadelClubs,
      ),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedClubName = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);
    final isBusy = _isLoadingProfile || _isLoadingCommunity;

    return Theme(
      data: baseTheme.copyWith(
        textTheme: interTextTheme,
        primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
      ),
      child: PgoHeaderScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Actividad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [
          PgoOptionsMenuButton(),
        ],
        body: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F5F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Anadir jugadores',
                      style: TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Center(
                    child: Text(
                      'Con quien juegas hoy?',
                      style: TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (isBusy)
                    const Center(child: CircularProgressIndicator())
                  else if (_profileError != null)
                    _StatusCard(
                      title: 'No pudimos cargar tu perfil',
                      message: _profileError!,
                      actionLabel: 'Reintentar',
                      onTap: _loadInitialData,
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (index) {
                          final player = _selectedPlayers[index];
                          if (player == null) {
                            return _AddPlayerCircle(
                              label: 'Jugador ${index + 1}',
                              onTap: _focusSearchInput,
                            );
                          }

                          return _PlayerCircle(
                            label: player.name,
                            imageUrl: player.photoUrl,
                            selected: true,
                            removable: !player.locked,
                            onRemove: () => _removePlayer(index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 18,
                                  color: AppColors.SecondBlue.withValues(
                                      alpha: 0.45),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    focusNode: _searchFocusNode,
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    decoration: InputDecoration(
                                      hintText: 'Nombre, correo electronico',
                                      hintStyle: TextStyle(
                                        color: AppColors.SecondBlue.withValues(
                                          alpha: 0.55,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.SecondBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _handleQrScan,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 60,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'QR',
                              style: TextStyle(
                                color: AppColors.SecondBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _searchController.text.trim().isEmpty
                          ? 'Sugerencias'
                          : 'Resultados de busqueda',
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_communityError != null)
                      _InlineInfoCard(message: _communityError!)
                    else if (_isSearching)
                      const Center(child: CircularProgressIndicator())
                    else if (_displayUsers.isEmpty)
                      _InlineInfoCard(
                        message: _searchController.text.trim().isEmpty
                            ? 'Aun no tienes companeros con los que hayas jugado.'
                            : 'No encontramos jugadores con esa busqueda.',
                      )
                    else
                      ..._displayUsers.map(
                        (user) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CommunityUserCard(
                            user: user,
                            alreadySelected: _isAlreadySelected(user.id),
                            onTap: () => _addPlayer(user),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'Club de juego',
                      style: TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _clubName,
                              style: const TextStyle(
                                color: AppColors.SecondBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _pickClub,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Cambiar',
                              style: TextStyle(
                                color: AppColors.PrimaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 38),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canContinue ? _goNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canContinue
                              ? const Color(0xFFD7FF59)
                              : const Color(0xFFD9DEE7),
                          foregroundColor: _canContinue
                              ? AppColors.SecondBlue
                              : AppColors.SecondBlue.withValues(alpha: 0.48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'SIGUIENTE',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerCircle extends StatelessWidget {
  const _PlayerCircle({
    required this.label,
    required this.imageUrl,
    this.selected = false,
    this.removable = false,
    this.onRemove,
  });

  final String label;
  final String? imageUrl;
  final bool selected;
  final bool removable;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        selected ? AppColors.PrimaryGreen : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackAvatar(),
                        )
                      : _fallbackAvatar(),
                ),
              ),
              if (removable)
                Positioned(
                  right: -4,
                  top: -4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFABB8CC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Colors.white,
      ),
    );
  }
}

class _AddPlayerCircle extends StatelessWidget {
  const _AddPlayerCircle({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFABB8CC),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CommunityUserCard extends StatelessWidget {
  const _CommunityUserCard({
    required this.user,
    required this.alreadySelected,
    required this.onTap,
  });

  final CommunityUser user;
  final bool alreadySelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alreadySelected ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.PrimaryGreen,
                  width: 1.4,
                ),
              ),
              child: ClipOval(
                child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? Image.network(
                        user.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackAvatar(),
                      )
                    : _fallbackAvatar(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.category ?? 'Sin categoria',
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _helperText(user),
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  String _helperText(CommunityUser user) {
    if (user.preferredClub != null && user.preferredClub!.isNotEmpty) {
      return user.preferredClub!;
    }
    return '${user.rankingPosition == 0 ? 3 : (user.rankingPosition % 6) + 2} partidos juntos';
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFABB8CC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Colors.white,
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.SecondBlue.withValues(alpha: 0.75),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ClubPickerSheet extends StatelessWidget {
  const _ClubPickerSheet({
    required this.current,
    required this.clubs,
  });

  final String current;
  final List<String> clubs;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona club',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                itemCount: clubs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final club = clubs[index];
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(club),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tileColor: club == current
                        ? const Color(0xFFD7FF59)
                        : const Color(0xFFF2F4F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      club,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: club == current
                        ? const Icon(Icons.check, color: AppColors.SecondBlue)
                        : null,
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7FF59),
                foregroundColor: AppColors.SecondBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
