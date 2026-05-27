import 'package:flutter/material.dart';

import '../screens/account_menu_screen.dart';

class PgoOptionsMenuButton extends StatelessWidget {
  const PgoOptionsMenuButton({
    super.key,
    this.notificationCount = 0,
    this.onNotificationsTap,
  });

  final int notificationCount;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Menú',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => AccountMenuScreen(
              onNotificationsTap: onNotificationsTap,
            ),
          ),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.menu, color: Colors.white),
          if (notificationCount > 0)
            Positioned(
              top: -5,
              right: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF334B),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    notificationCount > 9 ? '9+' : '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      height: 1,
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
