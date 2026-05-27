import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/profile_summary.dart';
import '../services/profile_service.dart';
import 'account_settings_screens.dart';
import 'open_match_alerts_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_history_screen.dart';
import 'profile_screen.dart';
import 'tournaments_screen.dart';

class AccountMenuScreen extends StatefulWidget {
  const AccountMenuScreen({
    super.key,
    this.onNotificationsTap,
  });

  final VoidCallback? onNotificationsTap;

  @override
  State<AccountMenuScreen> createState() => _AccountMenuScreenState();
}

class _AccountMenuScreenState extends State<AccountMenuScreen> {
  ProfileSummary? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    showLogoutDialog(context);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openEditProfile() {
    final profile = _profile;
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileEditScreen(profile: profile)),
    );
  }

  void _openTournaments() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentsScreen()),
    );
  }

  void _openMatches() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenMatchAlertsScreen()),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileHistoryScreen()),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  void _openSportsPreferences() {
    final profile = _profile;
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SportsPreferencesScreen(profile: profile),
      ),
    );
  }

  Future<void> _shareProfile() async {
    final profile = _profile;
    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name.trim()
        : 'Jugador PGO';
    await Share.share('Mira el perfil de $name en PGO.');
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name.trim()
        : 'Jugador PGO';
    final category = profile?.category?.trim().isNotEmpty == true
        ? profile!.category!.trim()
        : 'Sin categoría';
    final club = profile?.preferredClub?.trim().isNotEmpty == true
        ? profile!.preferredClub!.trim()
        : 'Club por definir';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'X',
                    style: PgoTextStyles.title(
                      color: AppColors.SecondBlue,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoading ? 'Cargando...' : name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PgoTextStyles.screenTitle(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category,
                        style: PgoTextStyles.title(
                          color: AppColors.SecondBlue,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.SecondBlue,
                            size: 17,
                          ),
                          Expanded(
                            child: Text(
                              club,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PgoTextStyles.body(
                                color: AppColors.SecondBlue,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _MenuAvatar(imageUrl: profile?.photoUrl),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MenuActionButton(
                    label: 'Ver perfil',
                    filled: true,
                    onTap: _openProfile,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _MenuActionButton(
                    label: 'Compartir perfil',
                    icon: Icons.ios_share_rounded,
                    onTap: _shareProfile,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _MenuSection(
              title: 'Cuenta',
              items: [
                _MenuEntry(
                  icon: Icons.person_outline_rounded,
                  title: 'Editar perfil',
                  subtitle: 'Nombre, foto y datos personales',
                  onTap: _openEditProfile,
                ),
                _MenuEntry(
                  icon: Icons.sports_tennis_rounded,
                  title: 'Preferencias deportivas',
                  subtitle: 'Lado, horario, nivel y club favorito',
                  onTap: _openSportsPreferences,
                ),
                _MenuEntry(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notificaciones',
                  subtitle: 'Partidos, torneos e invitaciones',
                  onTap: _openNotifications,
                ),
                _MenuEntry(
                  icon: Icons.shield_outlined,
                  title: 'Privacidad',
                  subtitle: 'Visibilidad y permisos',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacySettingsScreen(),
                    ),
                  ),
                ),
                _MenuEntry(
                  icon: Icons.lock_outline_rounded,
                  title: 'Seguridad y acceso',
                  subtitle: 'Contraseña y acceso a tu cuenta',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SecurityAccessScreen(),
                    ),
                  ),
                ),
              ],
            ),
            _MenuSection(
              title: 'Actividad',
              items: [
                _MenuEntry(
                  icon: Icons.event_available_outlined,
                  title: 'Mis partidos',
                  subtitle: 'Mis partidos abiertos y coordinaciones',
                  onTap: _openMatches,
                ),
                _MenuEntry(
                  icon: Icons.emoji_events_outlined,
                  title: 'Mis torneos',
                  subtitle: 'Inscripciones, brackets y resultados',
                  onTap: _openTournaments,
                ),
                _MenuEntry(
                  icon: Icons.bar_chart_rounded,
                  title: 'Historial deportivo',
                  subtitle: 'Resultados y partidos jugados',
                  onTap: _openHistory,
                ),
              ],
            ),
            _MenuSection(
              title: 'Ayuda',
              items: [
                _MenuEntry(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Ayuda',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  ),
                ),
                _MenuEntry(
                  icon: Icons.report_problem_outlined,
                  title: 'Reportar un problema',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportProblemScreen(),
                    ),
                  ),
                ),
              ],
            ),
            _MenuSection(
              title: 'Legal',
              items: [
                _MenuEntry(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SimpleLegalScreen(
                        title: 'Términos y condiciones',
                        body:
                            'Al usar PGO aceptas mantener información real, respetar a otros jugadores y usar las funciones de partidos, torneos y alertas de forma responsable. PGO puede actualizar estas condiciones para mejorar la seguridad y experiencia del servicio.',
                      ),
                    ),
                  ),
                ),
                _MenuEntry(
                  icon: Icons.visibility_outlined,
                  title: 'Política de privacidad',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SimpleLegalScreen(
                        title: 'Política de privacidad',
                        body:
                            'PGO utiliza tus datos para autenticar tu cuenta, mostrar tu perfil deportivo, gestionar partidos y torneos, enviar notificaciones y mejorar recomendaciones. Puedes ajustar visibilidad y permisos desde Privacidad.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LogoutCard(onTap: _logout),
          ],
        ),
      ),
    );
  }
}

class _MenuAvatar extends StatelessWidget {
  const _MenuAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.PrimaryGreen, width: 1.5),
      ),
      child: ClipOval(
        child: (imageUrl ?? '').isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _MenuAvatarFallback(),
              )
            : const _MenuAvatarFallback(),
      ),
    );
  }
}

class _MenuAvatarFallback extends StatelessWidget {
  const _MenuAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE1E5EB),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.SecondBlue.withValues(alpha: 0.55),
        size: 38,
      ),
    );
  }
}

class _MenuActionButton extends StatelessWidget {
  const _MenuActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(icon, size: 16, color: AppColors.SecondBlue),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? AppColors.PrimaryGreen : Colors.transparent,
          foregroundColor: AppColors.SecondBlue,
          shadowColor: Colors.transparent,
          side: filled
              ? BorderSide.none
              : const BorderSide(color: AppColors.SecondBlue, width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: PgoTextStyles.buttonSecondary(),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_MenuEntry> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PgoTextStyles.sectionTitle(),
          ),
          const SizedBox(height: 14),
          _MenuCard(items: items),
        ],
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuEntry> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _MenuTile(entry: items[index]),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 66, right: 28),
                child: Divider(height: 1, color: Color(0xFFD8DDE5)),
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.entry});

  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
        child: Row(
          children: [
            Icon(entry.icon, color: AppColors.SecondBlue, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: PgoTextStyles.menuOptionTitle(),
                  ),
                  if ((entry.subtitle ?? '').isNotEmpty)
                    Text(
                      entry.subtitle!,
                      style: PgoTextStyles.menuOptionDescription(
                        color: AppColors.SecondBlue.withValues(alpha: 0.72),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.SecondBlue,
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.power_settings_new_rounded,
                color: Color(0xFFFF4B68),
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Cerrar sesión',
                  style: PgoTextStyles.menuOptionTitle(
                    color: const Color(0xFFFF4B68),
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFFF4B68),
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
