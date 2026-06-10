import 'package:flutter_test/flutter_test.dart';
import 'package:pgo/utils/match_share_link.dart';

void main() {
  const id = '123e4567-e89b-42d3-a456-426614174000';

  test('builds the production match URL', () {
    expect(
      buildMatchShareUrl(id),
      'https://pgoapp.com/partidos/$id',
    );
  });

  test('builds a share message with available details', () {
    final message = buildMatchShareMessage(
      openMatchAlertId: id,
      category: '4ta',
      club: 'PGO Club',
      startsAt: DateTime(2026, 6, 10, 19, 30),
    );

    expect(message, contains('Unete a este partido de padel en PGO'));
    expect(message, contains('Categoria: 4ta'));
    expect(message, contains('Sede: PGO Club'));
    expect(message, contains('https://pgoapp.com/partidos/$id'));
  });

  test('omits empty optional details', () {
    final message = buildMatchShareMessage(
      openMatchAlertId: id,
      category: null,
      club: ' ',
    );

    expect(message, contains('Partido de padel'));
    expect(message, isNot(contains('Sede:')));
    expect(message, isNot(contains('Fecha:')));
  });

  test('parses a valid production match link', () {
    final result = parseMatchShareLink(
      Uri.parse('https://pgoapp.com/partidos/$id'),
    );

    expect(result.isMatchPath, isTrue);
    expect(result.openMatchAlertId, id);
    expect(result.hasInvalidId, isFalse);
  });

  test('recognizes an invalid id as a match link', () {
    final result = parseMatchShareLink(
      Uri.parse('https://pgoapp.com/partidos/no-es-uuid'),
    );

    expect(result.isMatchPath, isTrue);
    expect(result.openMatchAlertId, isNull);
    expect(result.hasInvalidId, isTrue);
  });

  test('ignores unrelated and tournament links', () {
    final tournament = parseMatchShareLink(
      Uri.parse('https://pgoapp.com/torneos/$id'),
    );
    final unrelated = parseMatchShareLink(
      Uri.parse('https://example.com/partidos/$id'),
    );

    expect(tournament.isMatchPath, isFalse);
    expect(unrelated.isMatchPath, isFalse);
  });
}
