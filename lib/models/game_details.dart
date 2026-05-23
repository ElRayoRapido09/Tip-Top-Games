class GameAchievement {
  final String apiName;
  final String displayName;
  final String description;
  final bool unlocked;
  final bool hidden;

  const GameAchievement({
    required this.apiName,
    required this.displayName,
    required this.description,
    required this.unlocked,
    this.hidden = false,
  });
}

class GameExtendedDetails {
  final String? description;
  final String? storageRequirement;
  final List<GameAchievement> achievements;
  final int unlockedCount;
  final int totalCount;
  final String? achievementsNote;

  const GameExtendedDetails({
    this.description,
    this.storageRequirement,
    this.achievements = const [],
    this.unlockedCount = 0,
    this.totalCount = 0,
    this.achievementsNote,
  });

  bool get hasAchievements => totalCount > 0;
}
