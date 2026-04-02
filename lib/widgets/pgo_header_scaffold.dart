import 'package:flutter/material.dart';

import '../constants/colors.dart';

class PgoHeaderScaffold extends StatelessWidget {
  const PgoHeaderScaffold({
    super.key,
    required this.body,
    this.leading,
    this.title,
    this.actions,
    this.titleSpacing,
    this.bottomNavigationBar,
  });

  final Widget body;
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double? titleSpacing;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: AppColors.headerToolbarHeight,
        backgroundColor: Colors.transparent,
        flexibleSpace: const DecoratedBox(
          decoration: AppColors.headerGradientDecoration,
        ),
        elevation: 0,
        titleSpacing: titleSpacing,
        leading: leading,
        title: title,
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: AppColors.headerGradientDecoration,
          child: Padding(
            padding: EdgeInsets.only(
              top: topInset + AppColors.headerToolbarHeight,
            ),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
