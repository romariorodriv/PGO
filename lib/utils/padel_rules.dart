class PadelSetValidationResult {
  const PadelSetValidationResult({
    required this.isValid,
    this.winnerTeam,
    this.error,
  });

  final bool isValid;
  final int? winnerTeam;
  final String? error;
}

class PadelMatchValidationResult {
  const PadelMatchValidationResult({
    required this.isValid,
    this.winnerTeam,
    this.error,
    this.team1SetsWon = 0,
    this.team2SetsWon = 0,
  });

  final bool isValid;
  final int? winnerTeam;
  final String? error;
  final int team1SetsWon;
  final int team2SetsWon;
}

class PadelRules {
  static const int setsToWin = 2;
  static const int maxSets = 3;

  static PadelSetValidationResult validateCompletedSetScore(
    int team1Games,
    int team2Games,
  ) {
    if (team1Games < 0 || team2Games < 0) {
      return const PadelSetValidationResult(
        isValid: false,
        error: 'Los games no pueden ser negativos.',
      );
    }

    if (team1Games == team2Games) {
      return const PadelSetValidationResult(
        isValid: false,
        error: 'Un set no puede terminar empatado.',
      );
    }

    final winnerGames = team1Games > team2Games ? team1Games : team2Games;
    final loserGames = team1Games > team2Games ? team2Games : team1Games;
    final winnerTeam = team1Games > team2Games ? 1 : 2;

    final isStandardWin =
        winnerGames == 6 && loserGames >= 0 && loserGames <= 4;
    final isExtendedWin = winnerGames == 7 && (loserGames == 5 || loserGames == 6);

    if (!isStandardWin && !isExtendedWin) {
      return const PadelSetValidationResult(
        isValid: false,
        error:
            'Set invalido. Usa marcadores reales como 6-0 a 6-4, 7-5 o 7-6.',
      );
    }

    return PadelSetValidationResult(
      isValid: true,
      winnerTeam: winnerTeam,
    );
  }

  static PadelMatchValidationResult validateBestOfThreeMatch(
    List<List<int>> sets,
  ) {
    if (sets.isEmpty) {
      return const PadelMatchValidationResult(
        isValid: false,
        error: 'Debes registrar al menos un set.',
      );
    }

    if (sets.length > maxSets) {
      return const PadelMatchValidationResult(
        isValid: false,
        error: 'Un partido al mejor de 3 no puede tener mas de 3 sets.',
      );
    }

    var team1SetsWon = 0;
    var team2SetsWon = 0;

    for (var index = 0; index < sets.length; index++) {
      final set = sets[index];
      if (set.length < 2) {
        return const PadelMatchValidationResult(
          isValid: false,
          error: 'Cada set debe tener marcador para ambos equipos.',
        );
      }

      final setResult = validateCompletedSetScore(set[0], set[1]);
      if (!setResult.isValid) {
        return PadelMatchValidationResult(
          isValid: false,
          error: 'Set ${index + 1}: ${setResult.error}',
        );
      }

      if (setResult.winnerTeam == 1) {
        team1SetsWon += 1;
      } else {
        team2SetsWon += 1;
      }

      if (index < sets.length - 1 &&
          (team1SetsWon >= setsToWin || team2SetsWon >= setsToWin)) {
        return const PadelMatchValidationResult(
          isValid: false,
          error: 'Si una pareja gana 2 sets, el partido ya debe terminar.',
        );
      }
    }

    if (team1SetsWon == team2SetsWon) {
      return PadelMatchValidationResult(
        isValid: false,
        error: 'El partido debe tener una pareja ganadora.',
        team1SetsWon: team1SetsWon,
        team2SetsWon: team2SetsWon,
      );
    }

    if (team1SetsWon < setsToWin && team2SetsWon < setsToWin) {
      return PadelMatchValidationResult(
        isValid: false,
        error: 'Una pareja debe ganar 2 sets para cerrar el partido.',
        team1SetsWon: team1SetsWon,
        team2SetsWon: team2SetsWon,
      );
    }

    return PadelMatchValidationResult(
      isValid: true,
      winnerTeam: team1SetsWon > team2SetsWon ? 1 : 2,
      team1SetsWon: team1SetsWon,
      team2SetsWon: team2SetsWon,
    );
  }
}
