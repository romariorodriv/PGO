import '../services/api_config.dart';

class MatchShareLinkParseResult {
  const MatchShareLinkParseResult._({
    required this.isMatchPath,
    this.openMatchAlertId,
  });

  const MatchShareLinkParseResult.notMatch() : this._(isMatchPath: false);

  const MatchShareLinkParseResult.invalid() : this._(isMatchPath: true);

  const MatchShareLinkParseResult.valid(String openMatchAlertId)
      : this._(
          isMatchPath: true,
          openMatchAlertId: openMatchAlertId,
        );

  final bool isMatchPath;
  final String? openMatchAlertId;

  bool get hasInvalidId => isMatchPath && openMatchAlertId == null;
}

String buildMatchShareUrl(String openMatchAlertId) {
  return Uri.parse(ApiConfig.shareBaseUrl)
      .replace(pathSegments: ['partidos', openMatchAlertId]).toString();
}

String buildMatchShareMessage({
  required String openMatchAlertId,
  String? category,
  String? club,
  DateTime? startsAt,
}) {
  final normalizedCategory = category?.trim() ?? '';
  final normalizedClub = club?.trim() ?? '';
  final lines = <String>[
    'Unete a este partido de padel en PGO',
    normalizedCategory.isEmpty
        ? 'Partido de padel'
        : 'Categoria: $normalizedCategory',
    if (normalizedClub.isNotEmpty) 'Sede: $normalizedClub',
    if (startsAt != null) 'Fecha: ${_formatShareDate(startsAt.toLocal())}',
    buildMatchShareUrl(openMatchAlertId),
  ];
  return lines.join('\n');
}

String _formatShareDate(DateTime value) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day} de ${months[value.month - 1]}, $hour:$minute';
}

String? extractOpenMatchAlertId(Uri uri) {
  return parseMatchShareLink(uri).openMatchAlertId;
}

MatchShareLinkParseResult parseMatchShareLink(Uri uri) {
  final isProductionMatchPath =
      (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.toLowerCase() == 'pgoapp.com' &&
          uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 'partidos';
  final isCustomSchemeMatchPath = uri.scheme.toLowerCase() == 'pgo' &&
      uri.host.toLowerCase() == 'partidos' &&
      uri.pathSegments.isNotEmpty;

  if (!isProductionMatchPath && !isCustomSchemeMatchPath) {
    return const MatchShareLinkParseResult.notMatch();
  }

  final hasExpectedSegments = isCustomSchemeMatchPath
      ? uri.pathSegments.length == 1
      : uri.pathSegments.length == 2;
  if (!hasExpectedSegments) {
    return const MatchShareLinkParseResult.invalid();
  }

  final id =
      isCustomSchemeMatchPath ? uri.pathSegments.first : uri.pathSegments[1];
  return isUuid(id)
      ? MatchShareLinkParseResult.valid(id)
      : const MatchShareLinkParseResult.invalid();
}

bool isUuid(String value) {
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}
