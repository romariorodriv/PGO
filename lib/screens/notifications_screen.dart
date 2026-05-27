import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'confirmar_actividad_screen.dart';
import '../widgets/pgo_bottom_nav.dart';
import 'main_shell.dart';
import 'profile_history_screen.dart';

enum _NotificationFilter {
  all,
  matches,
  tournaments,
  social,
}

enum _NotificationDestination {
  matches,
  tournaments,
  profileFriends,
  history,
  matchConfirmation,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  _NotificationFilter _selectedFilter = _NotificationFilter.all;
  List<PgoAppNotification> _notifications = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _notificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = response.notifications;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final now = DateTime.now();
    setState(() {
      _notifications = _notifications
          .map((item) => item.isRead ? item : item.copyWith(readAt: now))
          .toList();
    });
    try {
      await _notificationService.markAllRead();
    } catch (_) {}
  }

  Future<void> _markAsRead(PgoAppNotification item) async {
    if (item.isRead) return;
    final now = DateTime.now();
    setState(() {
      _notifications = _notifications
          .map((current) =>
              current.id == item.id ? current.copyWith(readAt: now) : current)
          .toList();
    });
    try {
      await _notificationService.markRead(item.id);
    } catch (_) {}
  }

  Future<void> _openNotification(PgoAppNotification item) async {
    await _markAsRead(item);
    if (!mounted) return;

    switch (_destinationFor(item)) {
      case _NotificationDestination.matches:
        Navigator.of(context).pushAndRemoveUntil(
          MainShell.route(initialTab: PgoNavTab.alerts),
          (_) => false,
        );
        break;
      case _NotificationDestination.tournaments:
        Navigator.of(context).pushAndRemoveUntil(
          MainShell.route(initialTab: PgoNavTab.tournaments),
          (_) => false,
        );
        break;
      case _NotificationDestination.profileFriends:
        Navigator.of(context).pushAndRemoveUntil(
          MainShell.route(
            initialTab: PgoNavTab.profile,
            openProfileFriendsOnStart: true,
          ),
          (_) => false,
        );
        break;
      case _NotificationDestination.history:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileHistoryScreen()),
        );
        break;
      case _NotificationDestination.matchConfirmation:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmarActividadScreen(notification: item),
          ),
        );
        break;
    }
  }

  List<PgoAppNotification> get _visibleNotifications {
    if (_selectedFilter == _NotificationFilter.all) return _notifications;
    return _notifications
        .where((item) => _filterFor(item) == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNotifications;
    final grouped = _groupNotifications(visible);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Stack(
          children: [
            Container(
              height: 162,
              decoration: AppColors.headerGradientDecoration,
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: SizedBox(
                      height: 54,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          Text(
                            'Notificaciones',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _markAllAsRead,
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFE9F8CB),
                                foregroundColor: AppColors.SecondBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Marcar leidas',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                      ),
                      child: RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: AppColors.SecondBlue,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 34, 18, 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FilterTabs(
                                selectedFilter: _selectedFilter,
                                onChanged: (filter) {
                                  setState(() => _selectedFilter = filter);
                                },
                              ),
                              const SizedBox(height: 34),
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (_error != null)
                                _NotificationsErrorCard(
                                  message: _error!,
                                  onRetry: _loadNotifications,
                                )
                              else if (visible.isEmpty)
                                const _EmptyNotificationsCard()
                              else
                                ...grouped.entries.expand((entry) {
                                  return [
                                    _SectionTitle(entry.key),
                                    const SizedBox(height: 14),
                                    _NotificationsGroupCard(
                                      notifications: entry.value,
                                      onTap: _openNotification,
                                    ),
                                    const SizedBox(height: 24),
                                  ];
                                }),
                            ],
                          ),
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
    );
  }

  Map<String, List<PgoAppNotification>> _groupNotifications(
    List<PgoAppNotification> notifications,
  ) {
    final grouped = <String, List<PgoAppNotification>>{};
    for (final item in notifications) {
      grouped.putIfAbsent(_sectionFor(item.createdAt), () => []).add(item);
    }
    return grouped;
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _NotificationFilter selectedFilter;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <_NotificationFilter, String>{
      _NotificationFilter.all: 'Todas',
      _NotificationFilter.matches: 'Partidos',
      _NotificationFilter.tournaments: 'Torneos',
      _NotificationFilter.social: 'Social',
    };

    return Row(
      children: tabs.entries.map((entry) {
        final selected = entry.key == selectedFilter;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: entry.key == _NotificationFilter.social ? 0 : 12,
            ),
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.SecondBlue : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: selected
                      ? const []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Text(
                  entry.value,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : AppColors.SecondBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppColors.SecondBlue,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _NotificationsGroupCard extends StatelessWidget {
  const _NotificationsGroupCard({
    required this.notifications,
    required this.onTap,
  });

  final List<PgoAppNotification> notifications;
  final ValueChanged<PgoAppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < notifications.length; index++) ...[
            _NotificationRow(
              notification: notifications[index],
              onTap: () => onTap(notifications[index]),
            ),
            if (index != notifications.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 76, right: 16),
                child: Divider(height: 1, color: Color(0xFFDDE2E8)),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.onTap,
  });

  final PgoAppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NotificationLeading(notification: notification),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _timeLabel(notification.createdAt),
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.62),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: notification.isRead ? 0 : 11,
                  height: notification.isRead ? 0 : 11,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9AC81E),
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

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({required this.notification});

  final PgoAppNotification notification;

  @override
  Widget build(BuildContext context) {
    return _IconBubble(
      icon: _iconFor(notification),
      background: _bubbleFor(notification),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.background,
  });

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
      ),
      child: Icon(icon, color: AppColors.SecondBlue, size: 24),
    );
  }
}

class _NotificationsErrorCard extends StatelessWidget {
  const _NotificationsErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

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
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Reintentar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationsCard extends StatelessWidget {
  const _EmptyNotificationsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'No tienes notificaciones por ahora.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppColors.SecondBlue.withValues(alpha: 0.72),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

const _blueBubble = Color(0xFFD9ECFF);
const _greenBubble = Color(0xFFE9F8CB);
const _yellowBubble = Color(0xFFFFF0A8);

String _sectionFor(DateTime createdAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final diff = today.difference(createdDay).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  return 'Esta semana';
}

String _timeLabel(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes}min';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'Ayer';
  const days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  return days[(createdAt.weekday - 1).clamp(0, 6)];
}

_NotificationFilter _filterFor(PgoAppNotification notification) {
  final type = notification.type.toUpperCase();
  if (type.contains('TOURNAMENT') ||
      type.contains('DUPLA') ||
      type.contains('MATCH_RESULT_CONFIRMATION')) {
    return _NotificationFilter.tournaments;
  }
  if (type.contains('FRIEND') || type.contains('SOCIAL')) {
    return _NotificationFilter.social;
  }
  return _NotificationFilter.matches;
}

_NotificationDestination _destinationFor(PgoAppNotification notification) {
  final type = notification.type.toUpperCase();
  if (type == 'MATCH_RESULT_CONFIRMATION_REQUIRED' ||
      notification.type == 'match_result_confirmation_required') {
    return _NotificationDestination.matchConfirmation;
  }
  if (type.contains('FRIEND') || type.contains('SOCIAL')) {
    return _NotificationDestination.profileFriends;
  }
  if (type.contains('RESULT') ||
      type.contains('XP') ||
      type.contains('MATCH_RESULT_CONFIRMATION')) {
    return _NotificationDestination.history;
  }
  if (type.contains('TOURNAMENT') || type.contains('DUPLA')) {
    return _NotificationDestination.tournaments;
  }
  return _NotificationDestination.matches;
}

IconData _iconFor(PgoAppNotification notification) {
  final type = notification.type.toUpperCase();
  if (type.contains('COORDINATION') || type.contains('WAY')) {
    return Icons.directions_car_filled_rounded;
  }
  if (type.contains('TOURNAMENT') || type.contains('DUPLA')) {
    return Icons.emoji_events_rounded;
  }
  if (type.contains('FRIEND') || type.contains('SOCIAL')) {
    return Icons.person_rounded;
  }
  if (type.contains('RESULT') ||
      type.contains('CONFIRM') ||
      type.contains('MATCH_RESULT_CONFIRMATION')) {
    return Icons.check_rounded;
  }
  if (type.contains('REMINDER') || type.contains('HOUR')) {
    return Icons.schedule_rounded;
  }
  return Icons.sports_tennis_rounded;
}

Color _bubbleFor(PgoAppNotification notification) {
  final type = notification.type.toUpperCase();
  if (type.contains('REMINDER') || type.contains('HOUR')) {
    return _yellowBubble;
  }
  if (type.contains('TOURNAMENT') ||
      type.contains('DUPLA') ||
      type.contains('FRIEND') ||
      type.contains('SOCIAL') ||
      type.contains('MATCH_RESULT_CONFIRMATION')) {
    return _greenBubble;
  }
  return _blueBubble;
}
