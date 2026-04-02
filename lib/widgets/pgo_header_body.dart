import 'package:flutter/material.dart';

import '../constants/colors.dart';

class PgoHeaderBody extends StatelessWidget {
  const PgoHeaderBody({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: AppColors.headerGradientDecoration,
        child: Padding(
          padding: EdgeInsets.only(
            top: topInset + AppColors.headerToolbarHeight,
          ),
          child: child,
        ),
      ),
    );
  }
}
