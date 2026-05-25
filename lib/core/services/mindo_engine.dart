import '../domain/enums/level_type.dart';

class MindoUserContext {
  final String displayName;
  final int totalXp;
  final int currentStreak;
  final LevelType level;
  final int daysOnJourney;
  final int moodEntriesCount;
  final bool loggedMoodToday;
  final int meditationSessions;
  const MindoUserContext({
    required this.displayName,
    required this.totalXp,
    required this.currentStreak,
    required this.level,
    required this.daysOnJourney,
    required this.moodEntriesCount,
    required this.loggedMoodToday,
    required this.meditationSessions,
  });
}

class MindoConversationState {
  final int userMessageCount;
  final String? lastTopic;
  final String? lastEmotion;
  final String? lastUserSnippet;
  final bool inCrisis;
  final bool guidedMeditationActive;
  final int guidedMeditationStep;
  final int genericResponseIndex;
  const MindoConversationState({
    this.userMessageCount = 0,
    this.lastTopic,
    this.lastEmotion,
    this.lastUserSnippet,
    this.inCrisis = false,
    this.guidedMeditationActive = false,
    this.guidedMeditationStep = 0,
    this.genericResponseIndex = 0,
  });
  MindoConversationState copyWith({
    int? userMessageCount,
    String? lastTopic,
    String? lastEmotion,
    String? lastUserSnippet,
    bool? inCrisis,
    bool? guidedMeditationActive,
    int? guidedMeditationStep,
    int? genericResponseIndex,
    bool clearTopic = false,
    bool clearEmotion = false,
    bool endGuided = false,
  }) =>
      MindoConversationState(
        userMessageCount: userMessageCount ?? this.userMessageCount,
        lastTopic: clearTopic ? null : lastTopic ?? this.lastTopic,
        lastEmotion: clearEmotion ? null : lastEmotion ?? this.lastEmotion,
        lastUserSnippet: lastUserSnippet ?? this.lastUserSnippet,
        inCrisis: inCrisis ?? this.inCrisis,
        guidedMeditationActive: endGuided ? false : guidedMeditationActive ?? this.guidedMeditationActive,
        guidedMeditationStep: endGuided ? 0 : guidedMeditationStep ?? this.guidedMeditationStep,
        genericResponseIndex: genericResponseIndex ?? this.genericResponseIndex,
      );
  Map<String, dynamic> toJson() => {
        'userMessageCount': userMessageCount,
        'lastTopic': lastTopic,
        'lastEmotion': lastEmotion,
        'lastUserSnippet': lastUserSnippet,
        'inCrisis': inCrisis,
        'guidedMeditationActive': guidedMeditationActive,
        'guidedMeditationStep': guidedMeditationStep,
        'genericResponseIndex': genericResponseIndex,
      };
  factory MindoConversationState.fromJson(Map<String, dynamic> json) =>
      MindoConversationState(
        userMessageCount: json['userMessageCount'] as int? ?? 0,
        lastTopic: json['lastTopic'] as String?,
        lastEmotion: json['lastEmotion'] as String?,
        lastUserSnippet: json['lastUserSnippet'] as String?,
        inCrisis: json['inCrisis'] as bool? ?? false,
        guidedMeditationActive: json['guidedMeditationActive'] as bool? ?? false,
        guidedMeditationStep: json['guidedMeditationStep'] as int? ?? 0,
        genericResponseIndex: json['genericResponseIndex'] as int? ?? 0,
      );
}

class MindoReply {
  final String text;
  final MindoConversationState state;
  const MindoReply({required this.text, required this.state});
}

class MindoEngine {
  MindoReply respond({
    required String input,
    required MindoConversationState state,
    required MindoUserContext user,
  }) {
    final lower = input.toLowerCase().trim();
    var next = state.copyWith(
      userMessageCount: state.userMessageCount + 1,
      lastUserSnippet: lower.length > 80 ? '${lower.substring(0, 80)}...' : lower,
    );
    if (next.guidedMeditationActive) {
      final guided = _guidedMeditationStep(lower, next, user);
      return MindoReply(text: guided.text, state: guided.state);
    }
    if (_wantsGuidedMeditation(lower)) {
      next = next.copyWith(guidedMeditationActive: true, guidedMeditationStep: 0);
      return MindoReply(text: _guidedIntro(user), state: next);
    }
    if (_containsAny(lower, [
      'suicid', 'me matar', 'quero morrer', 'nao quero mais viver',
      'não quero mais viver', 'acabar com tudo', 'me machucar',
      'automutilação', 'cortar', 'desaparecer para sempre',
    ])) {
      return MindoReply(
        text: '''💜 Obrigado por confiar em mim. O que você sente agora é muito pesado — você não está sozinho(a).

**CVV — 188** (24h, gratuito) · **cvv.org.br**

Posso continuar aqui com você. O que está acontecendo agora?''',
        state: next.copyWith(inCrisis: true, lastTopic: 'crise'),
      );
    }
    if (next.inCrisis && !_isCrisisContinuation(lower)) {
      next = next.copyWith(inCrisis: false);
    }
    if (_isFollowUp(lower) && next.lastTopic != null) {
      return MindoReply(
        text: _followUpForTopic(next.lastTopic!, next.lastEmotion, lower, user),
        state: next,
      );
    }
    if (_isExplicitGreeting(lower) && next.userMessageCount <= 2) {
      return MindoReply(text: _greeting(user), state: next.copyWith(lastTopic: 'saudacao'));
    }
    if (_containsAny(lower, [
      'ansiedad', 'ansioso', 'ansiosa', 'angustia', 'angústia',
      'nervoso', 'nervosa', 'preocupado', 'preocupada', 'apavorad', 'panico', 'pânico',
    ])) {
      return MindoReply(
        text: _anxiety(lower),
        state: next.copyWith(lastTopic: 'ansiedade', lastEmotion: 'ansiedade'),
      );
    }
    if (_containsAny(lower, [
      'triste', 'tristeza', 'choran', 'chorei', 'deprimid', 'depressão', 'depressao',
      'vazio', 'sem esperança', 'sem esperanca', 'desmotivad',
    ])) {
      return MindoReply(
        text: _sadness(lower),
        state: next.copyWith(lastTopic: 'tristeza', lastEmotion: 'tristeza'),
      );
    }
    if (_containsAny(lower, ['raiva', 'irritad', 'bravo', 'brava', 'frustrad', 'ódio', 'odio'])) {
      return MindoReply(
        text: _anger(),
        state: next.copyWith(lastTopic: 'raiva', lastEmotion: 'raiva'),
      );
    }
    if (_containsAny(lower, ['sozinho', 'sozinha', 'solidão', 'solidao', 'isolad', 'abandonad'])) {
      return MindoReply(
        text: _loneliness(),
        state: next.copyWith(lastTopic: 'solidão', lastEmotion: 'solidão'),
      );
    }
    if (_containsAny(lower, ['estressad', 'estresse', 'sobrecarregad', 'burnout', 'esgotad'])) {
      return MindoReply(
        text: _stress(),
        state: next.copyWith(lastTopic: 'estresse', lastEmotion: 'estresse'),
      );
    }
    if (_containsAny(lower, ['medo', 'assustado', 'assustada', 'pavor', 'fobia'])) {
      return MindoReply(
        text: _fear(),
        state: next.copyWith(lastTopic: 'medo', lastEmotion: 'medo'),
      );
    }
    if (_isPositive(lower)) {
      return MindoReply(
        text: _positive(user),
        state: next.copyWith(lastTopic: 'positivo', lastEmotion: 'positivo'),
      );
    }
    if (_containsAny(lower, ['relacionamento', 'namorad', 'parceir', 'termino', 'término'])) {
      return MindoReply(text: _relationship(), state: next.copyWith(lastTopic: 'relacionamento'));
    }
    if (_containsAny(lower, ['família', 'familia', 'mãe', 'mae', 'pai', 'irmão', 'irma'])) {
      return MindoReply(text: _family(), state: next.copyWith(lastTopic: 'família'));
    }
    if (_containsAny(lower, ['trabalho', 'emprego', 'faculdade', 'escola', 'chefe', 'prova'])) {
      return MindoReply(text: _work(), state: next.copyWith(lastTopic: 'trabalho'));
    }
    if (_containsAny(lower, [
      'respiração', 'respiracao', 'respirar', 'meditação', 'meditacao',
      'relaxar', 'acalmar', 'técnica', 'tecnica', 'exercicio',
    ])) {
      if (_wantsGuidedMeditation(lower)) {
        next = next.copyWith(guidedMeditationActive: true, guidedMeditationStep: 0);
        return MindoReply(text: _guidedIntro(user), state: next);
      }
      return MindoReply(text: _breathing(), state: next.copyWith(lastTopic: 'respiração'));
    }
    if (_containsAny(lower, ['obrigado', 'obrigada', 'valeu', 'ajudou', 'grato', 'grata'])) {
      return MindoReply(text: _gratitude(), state: next);
    }
    if (_containsAny(lower, ['não sei', 'nao sei', 'confuso', 'confusa', 'perdido', 'perdida'])) {
      return MindoReply(text: _confusion(), state: next.copyWith(lastTopic: 'confusão'));
    }
    if (next.lastTopic != null && lower.length < 120) {
      return MindoReply(
        text: _contextualContinue(next.lastTopic!, next.lastEmotion, lower),
        state: next,
      );
    }
    final idx = next.genericResponseIndex;
    final text = _empathetic(idx);
    return MindoReply(
      text: text,
      state: next.copyWith(genericResponseIndex: idx + 1, lastTopic: 'aberto'),
    );
  }

  static String welcomeMessage(String name) {
    final n = name.isNotEmpty ? ', $name' : '';
    return 'Oi$n! 💜 Eu sou o **Mindo**, seu companheiro emocional no MindFlow.\n\n'
        'Posso ouvir você, guiar respiração e meditação, e acompanhar sua jornada. '
        'Como você está se sentindo agora?';
  }

  bool _wantsGuidedMeditation(String lower) =>
      _containsAny(lower, [
        'meditação guiada', 'meditacao guiada', 'me guie', 'me guia',
        'meditar com você', 'meditar com voce', 'sessão guiada', 'sessao guiada',
        'quero meditar', 'iniciar meditação', 'iniciar meditacao',
      ]);

  bool _isExplicitGreeting(String lower) {
    final greetings = ['oi', 'olá', 'ola', 'bom dia', 'boa tarde', 'boa noite', 'e aí', 'e ai', 'hey', 'hello'];
    final onlyGreeting = greetings.any((g) => lower == g || lower.startsWith('$g '));
    return onlyGreeting || (lower.length < 25 && greetings.any((g) => lower.contains(g)));
  }

  bool _isFollowUp(String lower) =>
      _containsAny(lower, [
        'sim', 'continua', 'continue', 'próximo', 'proximo', 'ok', 'certo',
        'entendi', 'pode', 'vamos', 'segue', 'e depois', 'e agora',
      ]);

  bool _isCrisisContinuation(String lower) =>
      _containsAny(lower, ['ainda', 'pior', 'medo', 'choro', 'não aguento', 'nao aguento']);

  bool _isPositive(String lower) {
    if (_containsAny(lower, ['não estou bem', 'nao estou bem', 'mal', 'ruim', 'péssim', 'pessim', 'horrível'])) {
      return false;
    }
    return _containsAny(lower, [
      'feliz', 'ótimo', 'otimo', 'bem demais', 'maravilhoso', 'alegre',
      'contente', 'realizado', 'realizada', 'orgulhoso', 'gratidão', 'gratidao',
    ]);
  }

  MindoReply _guidedMeditationStep(String lower, MindoConversationState state, MindoUserContext user) {
    if (_containsAny(lower, ['parar', 'cancelar', 'sair', 'encerrar'])) {
      return MindoReply(
        text: 'Sessão encerrada com cuidado. 💜 Respire fundo mais uma vez. Estou aqui quando quiser retomar — ou abra **Meditação Flow** no app para áudio imersivo.',
        state: state.copyWith(endGuided: true),
      );
    }
    final step = state.guidedMeditationStep + 1;
    final texts = _guidedSteps(user);
    if (step >= texts.length) {
      return MindoReply(
        text: '''🧘✨ **Sessão guiada concluída.**

Você dedicou alguns minutos a si. Isso conta na sua jornada (+40 XP se usar Meditação Flow no app).

Como seu corpo está agora — mais leve, igual ou ainda tenso?''',
        state: state.copyWith(endGuided: true, lastTopic: 'meditação'),
      );
    }
    return MindoReply(
      text: texts[step],
      state: state.copyWith(guidedMeditationStep: step, lastTopic: 'meditação'),
    );
  }

  List<String> _guidedSteps(MindoUserContext user) => [
        _guidedIntro(user),
        '''**Passo 1 — Chegada** 🌿
Sente-se confortavelmente. Solte os ombros. Feche os olhos se quiser.
Inspire pelo nariz contando **4**... segure **4**... expire pela boca **6**.
Repita 3 vezes.
Digite **"próximo"** quando estiver pronto(a).''',
        '''**Passo 2 — Corpo** 🫁
Perceba os pés no chão. A coluna apoiada. O ar entrando e saindo.
Se a mente vagar, volte apenas à respiração — sem julgar.
Mais 4 ciclos lentos de respiração.
**"próximo"** para continuar.''',
        '''**Passo 3 — Mente** 💜
Imagine uma luz suave no peito expandindo a cada inspiração.
A cada expiração, solte tensão que não precisa ficar hoje.
Repita mentalmente: _"Estou seguro(a) neste momento."_
**"próximo"** quando sentir.''',
        '''**Passo 4 — Gratidão** ✨
Pense em uma coisa pequena que ainda existe hoje — uma pessoa, um conforto, um detalhe.
Agradeça em silêncio por 20 segundos.
Abra os olhos devagar.''',
      ];

  String _guidedIntro(MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? ', ${user.displayName}' : '';
    return '''🧘 **Meditação guiada com o Mindo**$name

Vou te conduzir em ~5 minutos, passo a passo. Responda **"próximo"** ou **"sim"** para avançar. Digite **"parar"** para encerrar.

Também pode abrir **Meditação Flow** no app para sons de fundo (ondas, tibetanas, spa).

**Preparo:** encontre um lugar quieto. Quando estiver pronto(a), diga **"próximo"**.''';
  }

  String _greeting(MindoUserContext user) {
    final hour = DateTime.now().hour;
    final g = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';
    final name = user.displayName.isNotEmpty ? ', ${user.displayName}' : '';
    final journey = user.daysOnJourney <= 1
        ? 'Você está começando sua jornada no MindFlow — cada passo conta.'
        : 'Dia **${user.daysOnJourney}** da sua jornada · nível **${user.level.label}** ${user.level.emoji}';
    final streak = user.currentStreak >= 2
        ? '\n🔥 Sequência de **${user.currentStreak}** dias — consistência transforma hábitos.'
        : '';
    final moodTip = user.loggedMoodToday
        ? ''
        : '\n📊 Ainda não registrou o humor hoje — isso ajuda sua progressão real no app.';
    return '$g$name! 💜 $journey$streak$moodTip\n\nComo você está se sentindo agora? Pode falar com suas palavras.';
  }

  String _followUpForTopic(String topic, String? emotion, String lower, MindoUserContext user) {
    if (topic == 'meditação' && _isFollowUp(lower)) {
      return 'Continue respirando no seu ritmo. 💜 Digite **"próximo"** para o próximo passo da meditação, ou **"meditação guiada"** para reiniciar.';
    }
    return _contextualContinue(topic, emotion, lower);
  }

  String _contextualContinue(String topic, String? emotion, String lower) {
    const map = {
      'ansiedade': 'Continuo aqui com você. 💜 O pensamento que mais repete na sua cabeça agora é qual? Nomear isso já reduz um pouco a intensidade.',
      'tristeza': 'Obrigado por ainda estar conversando. 🫂 O que mudou — mesmo que pouco — desde que você começou a falar?',
      'raiva': 'Como está o corpo agora — mais relaxado ou ainda tenso? 💜 O que você precisaria que fosse diferente na situação?',
      'solidão': 'Quero entender melhor: é solidão física ou de não ser compreendido(a)? 💜',
      'estresse': 'Se você pudesse resolver **só uma** coisa hoje, qual aliviaria mais? 💜',
      'relacionamento': 'O que você mais precisa nessa relação agora — ser ouvido(a), espaço, clareza? 💜',
      'trabalho': 'O que está no seu controle nas próximas 24h? Vamos focar só nisso. 💜',
      'meditação': 'Respire mais um ciclo 4-4-6. Como está o corpo agora? 💜',
      'aberto': 'Estou acompanhando o que você trouxe. 💜 Pode detalhar um pouco mais o que sente no corpo agora?',
    };
    return map[topic] ?? map['aberto']!;
  }

  String _anxiety(String input) {
    if (_containsAny(input, ['coração', 'respiraçã', 'sufocand', 'tremendo'])) {
      return '''Seu corpo está em alerta — isso é biológico, não é "frescura". 💜

**Agora — 4-7-8:**
Inspire **4s** · segure **7s** · solte **8s** (3 vezes).

O que disparou essa ansiedade? Conte com calma.''';
    }
    return '''Ansiedade cansa porque o corpo gasta energia se protegendo. 💜

**Grounding 5-4-3-2-1:** 5 coisas que vê · 4 que toca · 3 sons · 2 cheiros · 1 gosto.

Qual preocupação específica está mais alta agora?''';
  }

  String _sadness(String input) {
    if (_containsAny(input, ['depressão', 'depressao', 'deprimid', 'sem esperança'])) {
      return '''Obrigado por confiar isso a mim. 🫂 Depressão não é fraqueza — é sofrimento real.

→ Há quanto tempo se sente assim?
→ Está dormindo e se alimentando?

Se persistir, um psicólogo pode ajudar muito — é autocuidado, não derrota. 🌱

O que pesa mais hoje?''';
    }
    return '''Tristeza mostra que algo importava. 🫂 Você não precisa estar bem agora.

O que aconteceu? Estou ouvindo sem pressa.''';
  }

  String _anger() =>
      '''Raiva aparece quando um limite foi cruzado. 💜 Você está seguro(a) agora?

Respire 3 vezes devagar. O que aconteceu?''';

  String _loneliness() =>
      '''Solidão dói — e buscar apoio aqui já é coragem. 💜

É falta de pessoas por perto, ou de se sentir compreendido(a) mesmo acompanhado(a)?''';

  String _stress() =>
      '''Estresse acumulado tem limite — seu corpo avisa. 💜

30 segundos: olhos fechados, ombros soltos, mandíbula relaxada.

O que pesa mais agora — trabalho, relações ou tudo junto?''';

  String _fear() =>
      '''Medo tenta te proteger. 💜 É algo específico ou sensação difusa?

Pergunte: _"Qual a probabilidade real?"_ e _"Se acontecer, como eu lidaria?"_

Do que você tem medo agora?''';

  String _positive(MindoUserContext user) {
    final streak = user.currentStreak >= 3
        ? '\n🔥 **${user.currentStreak}** dias de sequência — sua progressão é real.'
        : '';
    return '''Que bom ouvir isso! 🌟 Registre esse momento no humor do app — seu eu do futuro agradece.$streak

O que contribuiu para esse bem-estar hoje?''';
  }

  String _relationship() =>
      '''Relacionamentos tocam o que temos de mais vulnerável. 💜 Conte o que está acontecendo — sem filtro.''';

  String _family() =>
      '''Família traz história e amor — e às vezes dor. 💜 O que está pesando nas relações familiares?''';

  String _work() =>
      '''Trabalho e estudo drenam energia quando pressionam demais. 💜

O que é pontual e o que vem se arrastando há tempo?''';

  String _breathing() =>
      '''**Box Breathing 4-4-4-4:** inspire 4 · segure 4 · expire 4 · segure 4. Repita 4–6 vezes.

Ou diga **"meditação guiada"** que eu conduzo passo a passo aqui no chat. 🧘''';

  String _gratitude() =>
      '''Fico feliz em ajudar — mas o mérito é seu por buscar cuidado. 💜

Como está se sentindo agora, depois de conversar?''';

  String _confusion() =>
      '''Não saber o que sente é comum. 💜

Onde no corpo há algo agora — peito, estômago, cabeça? Descreva a sensação física.''';

  String _empathetic(int index) {
    final pool = [
      'Obrigado por compartilhar. 💜 O que você descreveu importa — pode detalhar o que sente no corpo agora?',
      'Estou ouvindo sem julgamento. 💜 O que aconteceu antes de você se sentir assim?',
      'Você não precisa ter tudo organizado. 💜 Se pudesse mudar **uma** coisa hoje, qual seria?',
      'Isso que você vive é válido. 💜 Quer tentar **meditação guiada** comigo ou continuar conversando?',
    ];
    return pool[index % pool.length];
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }
}
