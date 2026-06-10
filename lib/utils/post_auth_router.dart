import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_summary.dart';
import '../screens/initial_onboarding_screen.dart';
import '../screens/main_shell.dart';
import '../services/profile_service.dart';
import 'initial_category_onboarding.dart';

const _pendingDeepLinkKey = 'pending_deep_link';

Future<void> savePendingDeepLink(Uri uri) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_pendingDeepLinkKey, uri.toString());
}

Future<Uri?> takePendingDeepLink() async {
  final prefs = await SharedPreferences.getInstance();
  final rawValue = prefs.getString(_pendingDeepLinkKey);
  if (rawValue == null || rawValue.isEmpty) return null;
  await prefs.remove(_pendingDeepLinkKey);
  return Uri.tryParse(rawValue);
}

Future<bool> routeAfterSuccessfulAuth(BuildContext context) async {
  try {
    final profile = await ProfileService().getMyProfile();
    if (!context.mounted) return false;
    final resolvedProfile = await _ensureInitialCategoryOnboarding(
      context,
      profile,
    );
    if (!context.mounted) return false;
    Navigator.of(context).pushAndRemoveUntil(
      MainShell.route(initialProfile: resolvedProfile),
      (_) => false,
    );
    return true;
  } catch (error) {
    if (error.toString().contains('ONBOARDING_CANCELLED')) {
      return false;
    }
    rethrow;
  }
}

Future<ProfileSummary> _ensureInitialCategoryOnboarding(
  BuildContext context,
  ProfileSummary profile,
) async {
  if (!needsInitialCategoryOnboarding(profile)) return profile;

  final result = await _openInitialCategoryOnboarding(context, profile);
  if (result == null) {
    throw Exception('ONBOARDING_CANCELLED');
  }

  final updated = await ProfileService().updateMyProfile(
    name: result.name,
    photoUrl: result.photoUrl,
    category: result.category,
    preferredClub: result.preferredClub,
    preferredSide: result.preferredSide,
    categoryOrigin: result.categoryOrigin,
    categoryIsProvisional: result.categoryIsProvisional,
    categorySuggested: result.quizCompletion?.result.suggestedCategory,
    categoryPreliminary: result.quizCompletion?.result.preliminaryCategory,
    categoryMaxApplied: result.quizCompletion?.result.maxAppliedCategory,
    categoryScore: result.quizCompletion?.result.totalScore,
    categoryQuizAnswers: result.quizCompletion?.answers,
    hasCompletedInitialOnboarding: true,
  );

  try {
    await ProfileService().markInitialOnboardingComplete();
  } catch (_) {}
  return updated;
}

Future<InitialOnboardingResult?> _openInitialCategoryOnboarding(
  BuildContext context,
  ProfileSummary profile,
) {
  final completer = Completer<InitialOnboardingResult?>();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!context.mounted) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final result = await Navigator.of(context).push<InitialOnboardingResult>(
      MaterialPageRoute(
        builder: (_) => InitialOnboardingScreen(
          initialName: profile.name,
          email: profile.email,
          initialPhotoUrl: profile.photoUrl,
          initialPhone: '',
        ),
      ),
    );
    if (!completer.isCompleted) completer.complete(result);
  });
  return completer.future;
}
