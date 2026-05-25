enum EmotionType {
  joy,
  sadness,
  anger,
  fear,
  anxiety,
  hope,
  love,
  calm,
  surprise,
  disgust,
  loneliness,
  guilt,
  motivation,
  exhaustion;

  String get label {
    switch (this) {
      case joy: return 'Alegria';
      case sadness: return 'Tristeza';
      case anger: return 'Raiva';
      case fear: return 'Medo';
      case anxiety: return 'Ansiedade';
      case hope: return 'Esperança';
      case love: return 'Amor';
      case calm: return 'Calma';
      case surprise: return 'Surpresa';
      case disgust: return 'Nojo';
      case loneliness: return 'Solidão';
      case guilt: return 'Culpa';
      case motivation: return 'Motivação';
      case exhaustion: return 'Exaustão';
    }
  }

  String get emoji {
    switch (this) {
      case joy: return '😄';
      case sadness: return '😢';
      case anger: return '😡';
      case fear: return '😨';
      case anxiety: return '😰';
      case hope: return '🌟';
      case love: return '❤️';
      case calm: return '😌';
      case surprise: return '😲';
      case disgust: return '🤢';
      case loneliness: return '😔';
      case guilt: return '😞';
      case motivation: return '🔥';
      case exhaustion: return '😴';
    }
  }
}
