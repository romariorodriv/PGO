import '../models/tournament_record.dart';

class TournamentRules {
  const TournamentRules._();

  static bool isDraft(TournamentRecord tournament) =>
      tournament.status.toUpperCase() == 'DRAFT';

  static bool isCanceled(TournamentRecord tournament) =>
      tournament.status.toUpperCase() == 'CANCELED';

  static bool isCompleted(TournamentRecord tournament) =>
      tournament.status.toUpperCase() == 'COMPLETED';

  static bool isFull(TournamentRecord tournament) =>
      tournament.playerCapacity > 0 &&
      tournament.registrationsCount >= tournament.playerCapacity;

  static bool hasValidDate(TournamentRecord tournament) =>
      tournament.startsAt.year >= 2000;

  static bool isPast(TournamentRecord tournament) =>
      hasValidDate(tournament) && tournament.startsAt.isBefore(DateTime.now());

  static bool canJoin(TournamentRecord tournament) {
    return !isDraft(tournament) &&
        !isCanceled(tournament) &&
        !isCompleted(tournament) &&
        tournament.registrationsOpen &&
        !isFull(tournament) &&
        !isPast(tournament);
  }

  static String joinLabel(TournamentRecord? tournament, {bool isPaid = false}) {
    if (isPaid) return 'IR AL PARTIDO';
    if (tournament == null) return 'UNIRME';
    if (isCanceled(tournament)) return 'TORNEO CANCELADO';
    if (isCompleted(tournament)) return 'TORNEO FINALIZADO';
    if (isDraft(tournament)) return 'BORRADOR';
    if (isPast(tournament)) return 'TORNEO PASADO';
    if (!tournament.registrationsOpen) return 'INSCRIPCIONES CERRADAS';
    if (isFull(tournament)) return 'CUPOS COMPLETOS';
    return 'UNIRME';
  }

  static String statusLabel(TournamentRecord tournament) {
    if (isDraft(tournament)) return 'borrador';
    if (isCanceled(tournament)) return 'torneo cancelado';
    if (isCompleted(tournament)) return 'torneo finalizado';
    if (!tournament.registrationsOpen) return 'inscripciones cerradas';
    if (isFull(tournament)) return 'cupos completos';
    return 'inscripciones abiertas';
  }

  static bool canPublish(TournamentRecord? tournament) {
    if (tournament == null) return true;
    return !isCanceled(tournament) && !isCompleted(tournament);
  }
}
