import '../models/tournament_record.dart';
import '../services/api_config.dart';

String buildTournamentShareLink(TournamentRecord tournament) {
  final shareUri = Uri.parse(ApiConfig.shareBaseUrl);
  final publicSegments =
      shareUri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  final slug = tournament.slug.isNotEmpty
      ? tournament.slug
      : _slugifyTournamentTitle(tournament.title);

  return shareUri.replace(
    pathSegments: [...publicSegments, 'torneos', slug],
    queryParameters: null,
    fragment: null,
  ).toString();
}

String _slugifyTournamentTitle(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'torneo' : normalized;
}
