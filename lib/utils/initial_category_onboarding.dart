import '../models/profile_summary.dart';

bool needsInitialCategoryOnboarding(ProfileSummary profile) {
  if (profile.hasCompletedInitialOnboarding == true) return false;

  final category = profile.category?.trim() ?? '';
  if (category.isNotEmpty) return false;

  final origin = profile.categoryOrigin?.trim().toLowerCase() ?? '';
  if (origin == 'quiz' || origin == 'manual' || origin == 'confirmed') {
    return false;
  }

  if (profile.categoryIsProvisional == true) return false;
  if ((profile.categorySuggested ?? '').trim().isNotEmpty) return false;
  if ((profile.categoryPreliminary ?? '').trim().isNotEmpty) return false;
  if ((profile.categoryMaxApplied ?? '').trim().isNotEmpty) return false;
  if (profile.categoryScore != null) return false;
  if ((profile.categoryQuizAnswers ?? const {}).isNotEmpty) return false;

  return true;
}
