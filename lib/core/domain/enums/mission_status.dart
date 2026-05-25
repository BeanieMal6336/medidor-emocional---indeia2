enum MissionStatus {
  available,
  inProgress,
  completed,
  failed;

  String get label {
    switch (this) {
      case available: return 'Disponível';
      case inProgress: return 'Em progresso';
      case completed: return 'Concluída';
      case failed: return 'Falhou';
    }
  }
}
