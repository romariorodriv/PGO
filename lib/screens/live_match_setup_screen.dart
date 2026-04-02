import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/community_user.dart';
import '../models/profile_summary.dart';
import '../models/selected_player.dart';
import '../services/community_service.dart';
import '../services/match_service.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'live_match_screen.dart';
import 'main_shell.dart';
import 'qr_scanner_screen.dart';

class LiveMatchSetupScreen extends StatefulWidget {
  const LiveMatchSetupScreen({
    super.key,
    this.isCompetitive = true,
  });

  final bool isCompetitive;

  @override
  State<LiveMatchSetupScreen> createState() => _LiveMatchSetupScreenState();
}

class _LiveMatchSetupScreenState extends State<LiveMatchSetupScreen> {
  static const _fallbackClubName = 'One Padel Olguin';

  final TextEditingController _searchController = TextEditingController();
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
  bool _isSubmitting = false;
  int? _servingTeam;
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

  Future<void> _handleStartMatch() async {
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

    if (_servingTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el equipo que empieza sacando'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final players = _selectedPlayers.whereType<SelectedPlayer>().toList();
      final match = await MatchService().createMatch(
        clubName: _profile?.preferredClub ?? _fallbackClubName,
        playedAt: DateTime.now(),
        matchType: widget.isCompetitive ? 'RANKED' : 'FRIENDLY',
        participantIds: players.map((player) => player.id).toList(),
        photoUrl: _profile?.photoUrl,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LiveMatchScreen(
            match: match,
            players: players,
            initialServingTeam: _servingTeam!,
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String get _clubName => _profile?.preferredClub ?? _fallbackClubName;

  List<CommunityUser> get _displayUsers =>
      _searchController.text.trim().isEmpty ? _communityUsers : _searchResults;

  bool get _canStart =>
      !_isSubmitting &&
      _selectedPlayers.every((player) => player != null) &&
      _servingTeam != null;

  Future<void> _handleQrScan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (!mounted || code == null || code.trim().isEmpty) {
      return;
    }

    try {
      final users = await _communityService.searchCommunity(code.trim());
      if (!mounted) return;
      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No encontramos un jugador para ese QR')),
        );
        return;
      }

      final normalized = code.trim().toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoadingProfile || _isLoadingCommunity;

    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Registro en vivo',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: const [
        PgoOptionsMenuButton(),
      ],
      bottomNavigationBar: PgoBottomNav(
        currentTab: PgoNavTab.tournaments,
        onHomeTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.home);
        },
        onTournamentsTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.tournaments);
        },
        onProfileTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.profile);
        },
      ),
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
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB7D56A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_tennis,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancha en vivo · $_clubName',
                        style: const TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF4),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 42),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _profileError != null
                          ? _LiveStatusCard(
                              title: 'No pudimos cargar tu perfil',
                              message: _profileError!,
                              actionLabel: 'Reintentar',
                              onTap: _loadInitialData,
                            )
                          : _buildSetupCardContent(),
                ),
                const SizedBox(height: 24),
                _buildSearchRow(),
                const SizedBox(height: 28),
                const Text(
                  'Sugerencias',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _buildSuggestions(),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canStart ? _handleStartMatch : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      disabledBackgroundColor:
                          const Color(0xFFD7FF59).withValues(alpha: 0.45),
                      foregroundColor: AppColors.SecondBlue,
                      disabledForegroundColor:
                          AppColors.SecondBlue.withValues(alpha: 0.55),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.18),
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
                        : const Text(
                            'EMPEZAR PARTIDO',
                            style: TextStyle(
                              fontSize: 16,
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

  Widget _buildSetupCardContent() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Equipo 1',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Equipo 2',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LiveSetupPlayer(
                      label: _selectedPlayers[0]?.name ?? 'Jugador 1',
                      imageUrl: _selectedPlayers[0]?.photoUrl,
                      selected: _selectedPlayers[0] != null,
                      removable: !(_selectedPlayers[0]?.locked ?? false),
                      onRemove: () => _removePlayer(0),
                    ),
                    _LiveSetupPlayer(
                      label: _selectedPlayers[1]?.name ?? 'Jugador 2',
                      imageUrl: _selectedPlayers[1]?.photoUrl,
                      selected: _selectedPlayers[1] != null,
                      removable: _selectedPlayers[1] != null,
                      onRemove: () => _removePlayer(1),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(
                color: Color(0xFFB7C0D1),
                thickness: 1,
                width: 22,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LiveSetupPlayer(
                      label: _selectedPlayers[2]?.name ?? 'Jugador 3',
                      imageUrl: _selectedPlayers[2]?.photoUrl,
                      selected: _selectedPlayers[2] != null,
                      removable: _selectedPlayers[2] != null,
                      onRemove: () => _removePlayer(2),
                    ),
                    _LiveSetupPlayer(
                      label: _selectedPlayers[3]?.name ?? 'Jugador 4',
                      imageUrl: _selectedPlayers[3]?.photoUrl,
                      selected: _selectedPlayers[3] != null,
                      removable: _selectedPlayers[3] != null,
                      onRemove: () => _removePlayer(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFB7C0D1),
        ),
        const SizedBox(height: 18),
        const Text(
          'Quien empieza sacando?',
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.SecondBlue,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: const Text(
            'SELECCIONA EQUIPO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 22),
        _ServeOptionCard(
          active: _servingTeam == 1,
          label: 'Equipo 1',
          onTap: () {
            setState(() {
              _servingTeam = 1;
            });
          },
        ),
        const SizedBox(height: 14),
        _ServeOptionCard(
          active: _servingTeam == 2,
          label: 'Equipo 2',
          onTap: () {
            setState(() {
              _servingTeam = 2;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.SecondBlue.withValues(alpha: 0.35),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nombre, correo electronico',
                      hintStyle: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.36),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _handleQrScan,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 58,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text(
              'QR',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_communityError != null) {
      return _LiveStatusCard(
        title: 'No pudimos cargar la comunidad',
        message: _communityError!,
        actionLabel: 'Reintentar',
        onTap: () => _loadCommunity(
          query: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
      );
    }

    if (_displayUsers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'Aun no tienes jugadores sugeridos para registrar en vivo.'
              : 'No encontramos jugadores con ese criterio.',
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.62),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: _displayUsers
          .map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SuggestedPlayerCard(
                user: user,
                selected: _isAlreadySelected(user.id),
                onTap: () => _addPlayer(user),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LiveSetupPlayer extends StatelessWidget {
  const _LiveSetupPlayer({
    required this.label,
    this.imageUrl,
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
      width: 68,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DEED),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.PrimaryGreen
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 26,
                          ),
                        )
                      : Icon(
                          selected ? Icons.person : Icons.add,
                          color: Colors.white,
                          size: selected ? 26 : 32,
                        ),
                ),
              ),
              if (removable)
                Positioned(
                  top: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5B6B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServeOptionCard extends StatelessWidget {
  const _ServeOptionCard({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: active ? Colors.white : const Color(0xFFDCE3EE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? AppColors.PrimaryGreen : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_off,
              color: active
                  ? AppColors.PrimaryGreen
                  : AppColors.SecondBlue.withValues(alpha: 0.35),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label empieza sacando',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedPlayerCard extends StatelessWidget {
  const _SuggestedPlayerCard({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  final CommunityUser user;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4DEED),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.PrimaryGreen,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? Image.network(
                            user.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 26,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.category ?? 'Sin categoria',
                        style: TextStyle(
                          color: AppColors.SecondBlue.withValues(alpha: 0.62),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE6ECB9)
                        : AppColors.PrimaryGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    selected ? 'OK' : '#${user.rankingPosition}',
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
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

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onTap;

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
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
