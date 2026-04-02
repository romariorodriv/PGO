class SelectedPlayer {
  final String id;
  final String name;
  final String? photoUrl;
  final String? category;
  final int rankingPosition;
  final bool locked;

  const SelectedPlayer({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.category,
    required this.rankingPosition,
    this.locked = false,
  });
}
