import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/session_service.dart';
import '../screens/login_screen.dart';

class PgoOptionsMenuButton extends StatelessWidget {
  const PgoOptionsMenuButton({super.key});

  Future<void> _handleSelection(
    BuildContext context,
    _PgoMenuAction action,
  ) async {
    switch (action) {
      case _PgoMenuAction.notifications:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificaciones proximamente')),
        );
        break;
      case _PgoMenuAction.settings:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuracion proximamente')),
        );
        break;
      case _PgoMenuAction.help:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Centro de ayuda proximamente')),
        );
        break;
      case _PgoMenuAction.logout:
        await SessionService().clear();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PgoMenuAction>(
      tooltip: 'Opciones',
      offset: const Offset(0, 12),
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      icon: const Icon(Icons.menu, color: Colors.white),
      onSelected: (value) => _handleSelection(context, value),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _PgoMenuAction.notifications,
          child: _MenuItemContent(
            icon: Icons.notifications_none_rounded,
            label: 'Notificaciones',
          ),
        ),
        PopupMenuItem(
          value: _PgoMenuAction.settings,
          child: _MenuItemContent(
            icon: Icons.settings_outlined,
            label: 'Configuracion',
          ),
        ),
        PopupMenuItem(
          value: _PgoMenuAction.help,
          child: _MenuItemContent(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _PgoMenuAction.logout,
          child: _MenuItemContent(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesion',
            danger: true,
          ),
        ),
      ],
    );
  }
}

enum _PgoMenuAction {
  notifications,
  settings,
  help,
  logout,
}

class _MenuItemContent extends StatelessWidget {
  const _MenuItemContent({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFD64242) : AppColors.SecondBlue;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
