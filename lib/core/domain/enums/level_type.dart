enum LevelType {
  seedling,
  sprout,
  plant,
  flower,
  tree,
  forest;

  String get label {
    switch (this) {
      case seedling: return 'Sementinha';
      case sprout: return 'Broto';
      case plant: return 'Planta';
      case flower: return 'Flor';
      case tree: return 'Árvore';
      case forest: return 'Floresta';
    }
  }

  String get emoji {
    switch (this) {
      case seedling: return '🌱';
      case sprout: return '🌿';
      case plant: return '🪴';
      case flower: return '🌸';
      case tree: return '🌳';
      case forest: return '🌲';
    }
  }

  int get xpRequired {
    switch (this) {
      case seedling: return 0;
      case sprout: return 100;
      case plant: return 300;
      case flower: return 600;
      case tree: return 1000;
      case forest: return 2000;
    }
  }

  static LevelType fromXp(int xp) {
    if (xp >= 2000) return forest;
    if (xp >= 1000) return tree;
    if (xp >= 600) return flower;
    if (xp >= 300) return plant;
    if (xp >= 100) return sprout;
    return seedling;
  }
}
