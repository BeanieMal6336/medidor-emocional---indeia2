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
  final int rapportLevel;
  final List<String> recentUserMessages;
  const MindoConversationState({
    this.userMessageCount = 0,
    this.lastTopic,
    this.lastEmotion,
    this.lastUserSnippet,
    this.inCrisis = false,
    this.guidedMeditationActive = false,
    this.guidedMeditationStep = 0,
    this.genericResponseIndex = 0,
    this.rapportLevel = 0,
    this.recentUserMessages = const [],
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
    int? rapportLevel,
    List<String>? recentUserMessages,
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
        rapportLevel: rapportLevel ?? this.rapportLevel,
        recentUserMessages: recentUserMessages ?? this.recentUserMessages,
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
        'rapportLevel': rapportLevel,
        'recentUserMessages': recentUserMessages,
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
        rapportLevel: json['rapportLevel'] as int? ?? 0,
        recentUserMessages: (json['recentUserMessages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
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
    final history = [...state.recentUserMessages, lower].take(5).toList();
    var next = state.copyWith(
      userMessageCount: state.userMessageCount + 1,
      lastUserSnippet: lower.length > 80 ? '${lower.substring(0, 80)}...' : lower,
      recentUserMessages: history,
      rapportLevel: state.rapportLevel + 1,
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
        text: '''💜 Obrigado por confiar em mim. O que você sente é real e pesado — você não está sozinho(a).

**CVV — 188** (24h) · **cvv.org.br**

Estou aqui. O que está acontecendo neste momento?''',
        state: next.copyWith(inCrisis: true, lastTopic: 'crise'),
      );
    }
    if (next.inCrisis && !_isCrisisContinuation(lower)) {
      next = next.copyWith(inCrisis: false);
    }
    if (_wantsThoughtReframe(lower)) {
      return MindoReply(
        text: _cbtReframe(user),
        state: next.copyWith(lastTopic: 'reframe', lastEmotion: 'ansiedade'),
      );
    }
    if (_isFollowUp(lower) && next.lastTopic != null) {
      return MindoReply(
        text: _deepFollowUp(next, user, lower),
        state: next,
      );
    }
    if (_isExplicitGreeting(lower) && next.userMessageCount <= 2) {
      return MindoReply(text: _greeting(user), state: next.copyWith(lastTopic: 'saudacao'));
    }
    final tone = _detectTone(lower);
    if (tone != null && next.rapportLevel >= 2 && lower.length > 40) {
      return MindoReply(
        text: _reflectiveInsight(lower, tone, user, next),
        state: next.copyWith(lastTopic: 'reflexão', lastEmotion: tone),
      );
    }
    if (_containsAny(lower, [
      'ansiedad', 'ansioso', 'ansiosa', 'angustia', 'angústia',
      'nervoso', 'nervosa', 'preocupado', 'preocupada', 'apavorad', 'panico', 'pânico',
    ])) {
      return MindoReply(
        text: _anxiety(lower, user),
        state: next.copyWith(lastTopic: 'ansiedade', lastEmotion: 'ansiedade'),
      );
    }
    if (_containsAny(lower, [
      'triste', 'tristeza', 'choran', 'chorei', 'deprimid', 'depressão', 'depressao',
      'vazio', 'sem esperança', 'sem esperanca', 'desmotivad',
    ])) {
      return MindoReply(
        text: _sadness(lower, user),
        state: next.copyWith(lastTopic: 'tristeza', lastEmotion: 'tristeza'),
      );
    }
    if (_containsAny(lower, ['raiva', 'irritad', 'bravo', 'brava', 'frustrad', 'ódio', 'odio'])) {
      return MindoReply(
        text: _anger(user),
        state: next.copyWith(lastTopic: 'raiva', lastEmotion: 'raiva'),
      );
    }
    if (_containsAny(lower, ['sozinho', 'sozinha', 'solidão', 'solidao', 'isolad', 'abandonad'])) {
      return MindoReply(
        text: _loneliness(user),
        state: next.copyWith(lastTopic: 'solidão', lastEmotion: 'solidão'),
      );
    }
    if (_containsAny(lower, ['estressad', 'estresse', 'sobrecarregad', 'burnout', 'esgotad'])) {
      return MindoReply(
        text: _stress(user),
        state: next.copyWith(lastTopic: 'estresse', lastEmotion: 'estresse'),
      );
    }
    if (_containsAny(lower, ['medo', 'assustado', 'assustada', 'pavor', 'fobia'])) {
      return MindoReply(
        text: _fear(user),
        state: next.copyWith(lastTopic: 'medo', lastEmotion: 'medo'),
      );
    }
    if (_containsAny(lower, ['sono', 'dormir', 'insônia', 'insonia', 'cansad', 'exaust'])) {
      return MindoReply(
        text: _sleepSupport(user),
        state: next.copyWith(lastTopic: 'sono'),
      );
    }
    if (_isPositive(lower)) {
      return MindoReply(
        text: _positive(user),
        state: next.copyWith(lastTopic: 'positivo', lastEmotion: 'positivo'),
      );
    }
    if (_containsAny(lower, ['relacionamento', 'namorad', 'parceir', 'termino', 'término'])) {
      return MindoReply(text: _relationship(user), state: next.copyWith(lastTopic: 'relacionamento'));
    }
    if (_containsAny(lower, ['família', 'familia', 'mãe', 'mae', 'pai', 'irmão', 'irma'])) {
      return MindoReply(text: _family(user), state: next.copyWith(lastTopic: 'família'));
    }
    if (_containsAny(lower, ['trabalho', 'emprego', 'faculdade', 'escola', 'chefe', 'prova'])) {
      return MindoReply(text: _work(user), state: next.copyWith(lastTopic: 'trabalho'));
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
      return MindoReply(text: _gratitude(user), state: next);
    }
    if (_containsAny(lower, ['não sei', 'nao sei', 'confuso', 'confusa', 'perdido', 'perdida'])) {
      return MindoReply(text: _confusion(), state: next.copyWith(lastTopic: 'confusão'));
    }
    if (next.lastTopic != null && lower.length < 160) {
      return MindoReply(
        text: _contextualContinue(next.lastTopic!, next.lastEmotion, lower, user),
        state: next,
      );
    }
    final idx = next.genericResponseIndex;
    return MindoReply(
      text: _empathetic(idx, user, next),
      state: next.copyWith(genericResponseIndex: idx + 1, lastTopic: 'aberto'),
    );
  }

  static String welcomeMessage(String name) {
    final n = name.isNotEmpty ? ', $name' : '';
    return 'Oi$n! 💜 Sou o **Mindo** — companheiro emocional do MindFlow.\n\n'
        'Converso com memória da sessão, guio meditação, aplico técnicas de CBT e mindfulness '
        '(sem substituir terapia). Como você está agora?';
  }

  String? _detectTone(String lower) {
    if (_containsAny(lower, ['ansiedad', 'nervos', 'preocup', 'panico'])) return 'ansiedade';
    if (_containsAny(lower, ['triste', 'chor', 'vazio', 'deprim'])) return 'tristeza';
    if (_containsAny(lower, ['raiva', 'irritad', 'frustrad'])) return 'raiva';
    if (_containsAny(lower, ['cansad', 'esgot', 'burnout'])) return 'estresse';
    return null;
  }

  String _reflectiveInsight(String lower, String tone, MindoUserContext user, MindoConversationState state) {
    final name = user.displayName.isNotEmpty ? user.displayName : 'você';
    final prev = state.recentUserMessages.length >= 2
        ? state.recentUserMessages[state.recentUserMessages.length - 2]
        : '';
    final bridge = prev.isNotEmpty
        ? '\n\nPercebo uma continuidade no que você trouxe antes ("$prev") e agora.'
        : '';
    return '''$name, estou processando o que você compartilhou com atenção real. 💜$bridge

Pelo tom da sua mensagem, parece haver **$tone** presente. Isso não define quem você é — é um estado que pode ser acolhido.

**Pergunta Mindo:** se essa emoção tivesse uma voz, o que ela estaria pedindo agora — descanso, limite, carinho ou clareza?''';
  }

  String _deepFollowUp(MindoConversationState state, MindoUserContext user, String lower) {
    if (state.guidedMeditationActive || state.lastTopic == 'meditação') {
      return _guidedMeditationStep(lower, state, user).text;
    }
    if (state.lastTopic == 'reframe') {
      return '''Ótimo. 💜 Agora complete:

**Pensamento mais equilibrado:** uma frase gentil e realista sobre a situação.

Ex.: _"Estou com dificuldade agora, mas já superei momentos difíceis antes."_

Escreva a sua versão.''';
    }
    return _contextualContinue(state.lastTopic!, state.lastEmotion, lower, user);
  }

  bool _wantsThoughtReframe(String lower) =>
      _containsAny(lower, [
        'pensamento negativo', 'não consigo parar de pensar', 'nao consigo parar',
        'ruminação', 'ruminacao', 'loop na cabeça', 'mente acelerada',
        'reformular', 'pensamento automático',
      ]);

  String _cbtReframe(MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    return '''${name}vamos usar um método de **Terapia Cognitivo-Comportamental** (CBT) — em 3 passos:

**1. Situação** — O que aconteceu? (só fatos)
**2. Pensamento automático** — O que sua mente disse? (ex.: "não vou dar conta")
**3. Evidências** — Liste 2 fatos que **apoiam** e 2 que **questionam** esse pensamento

Depois escreva um **pensamento alternativo** mais justo.

Responda o passo 1 quando quiser — vou te acompanhar. 🧠💜''';
  }

  String _sleepSupport(MindoUserContext user) =>
      '''Sono e humor estão ligados. 😴 💜

**Higiene rápida Mindo:**
• Luz baixa 1h antes de dormir
• Evitar telas ou usar modo noturno
• 4-7-8: inspire 4s, segure 7s, solte 8s (4 vezes)

${user.loggedMoodToday ? '' : 'Registre como está agora no humor — ajuda a ver padrões sono ↔ emoção.'}

O que mais atrapalha seu sono: mente acelerada, preocupação ou corpo inquieto?''';

  bool _wantsGuidedMeditation(String lower) =>
      _containsAny(lower, [
        'meditação guiada', 'meditacao guiada', 'me guie', 'me guia',
        'meditar com você', 'meditar com voce', 'sessão guiada', 'sessao guiada',
        'quero meditar', 'iniciar meditação', 'iniciar meditacao',
      ]);

  bool _isExplicitGreeting(String lower) {
    final greetings = ['oi', 'olá', 'ola', 'bom dia', 'boa tarde', 'boa noite', 'e aí', 'e ai', 'hey', 'hello'];
    return greetings.any((g) => lower == g || (lower.length < 30 && lower.startsWith(g)));
  }

  bool _isFollowUp(String lower) =>
      _containsAny(lower, [
        'sim', 'continua', 'continue', 'próximo', 'proximo', 'ok', 'certo',
        'entendi', 'pode', 'vamos', 'segue', 'e depois', 'e agora', 'pronto',
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
        text: 'Sessão encerrada com cuidado. 💜 Respire fundo. Estou aqui — ou use **Meditação Flow** com sons imersivos.',
        state: state.copyWith(endGuided: true),
      );
    }
    final step = state.guidedMeditationStep + 1;
    final texts = _guidedSteps(user);
    if (step >= texts.length) {
      return MindoReply(
        text: '''🧘✨ **Sessão guiada concluída.**

Você praticou presença — isso é saúde mental ativa. Registre seu humor no app.

Como está o corpo: mais leve, igual ou tenso?''',
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
Ajuste a postura. Inspire **4**, segure **4**, expire **6** (3 ciclos).
Digite **"próximo"** quando pronto(a).''',
        '''**Passo 2 — Corpo** 🫁
Escaneie: pés → pernas → barriga → peito → rosto. Solte tensão em cada região.
**"próximo"** para continuar.''',
        '''**Passo 3 — Âncora mental** 💜
Repita: _"Neste momento, estou seguro(a) o suficiente para respirar."_
**"próximo"** quando sentir.''',
        '''**Passo 4 — Gratidão** ✨
Uma coisa pequena de hoje que ainda existe. Silêncio 20s. Abra os olhos devagar.''',
      ];

  String _guidedIntro(MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? ', ${user.displayName}' : '';
    return '''🧘 **Meditação guiada Mindo**$name

Condução passo a passo (~5 min). Responda **"próximo"** para avançar · **"parar"** para encerrar.

Para áudio ambiente: **Meditação Flow** no app.

Quando estiver pronto(a), diga **"próximo"**.''';
  }

  String _greeting(MindoUserContext user) {
    final hour = DateTime.now().hour;
    final g = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';
    final name = user.displayName.isNotEmpty ? ', ${user.displayName}' : '';
    final journey = user.daysOnJourney <= 1
        ? 'Primeiro dia oficial na sua jornada — começamos do zero, com intenção.'
        : 'Dia **${user.daysOnJourney}** · nível **${user.level.label}** ${user.level.emoji} · **${user.totalXp}** XP';
    final streak = user.currentStreak >= 2 ? '\n🔥 Sequência: **${user.currentStreak}** dias.' : '';
    final moodTip = user.loggedMoodToday
        ? ''
        : '\n📊 Registrar o humor hoje desbloqueia insights no Mapa Emocional.';
    return '$g$name! 💜 $journey$streak$moodTip\n\nO que está mais presente em você agora?';
  }

  String _contextualContinue(String topic, String? emotion, String lower, MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    const map = {
      'ansiedade': 'qual pensamento específico está em loop agora? Nomear reduz a intensidade em até 30%.',
      'tristeza': 'o que mudou, mesmo que um pouco, desde que você começou a falar?',
      'raiva': 'que limite foi cruzado? O que você precisava que acontecesse de diferente?',
      'solidão': 'é solidão física ou de não ser compreendido(a)?',
      'estresse': 'se só pudesse resolver UMA coisa hoje, qual aliviaria mais?',
      'relacionamento': 'o que você precisa agora: ser ouvido(a), espaço ou clareza?',
      'trabalho': 'o que está no seu controle nas próximas 24 horas?',
      'meditação': 'como está o corpo após respirar — mais leve ou ainda tenso?',
      'reflexão': 'o que essa emoção pede de você com gentileza?',
      'aberto': 'pode descrever o que sente no corpo agora (peito, estômago, garganta)?',
    };
    return '${name}continuo aqui. 💜 ${map[topic] ?? map['aberto']!}';
  }

  String _anxiety(String input, MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    if (_containsAny(input, ['coração', 'respiraçã', 'sufocand', 'tremendo'])) {
      return '''$name seu corpo está em modo proteção — biológico, não é exagero. 💜

**4-7-8 agora:** inspire 4s · segure 7s · solte 8s (×3).

O que disparou isso?''';
    }
    return '''$name ansiedade consome energia do corpo. 💜

**5-4-3-2-1** (grounding) ou diga **"meditação guiada"**.

Qual pensamento está mais alto agora?''';
  }

  String _sadness(String input, MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? '$name, ' : '';
    if (_containsAny(input, ['depressão', 'depressao', 'deprimid', 'sem esperança'])) {
      return '''${name}obrigado por confiar. 🫂 Isso é sofrimento real, não fraqueza.

Há quanto tempo? Está comendo e dormindo?

Se persistir, apoio profissional ajuda muito. O que pesa mais hoje?''';
    }
    return '''${name}tristeza mostra que algo importava. 🫂 Não precisa estar bem agora.

O que aconteceu?''';
  }

  String _anger(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    return '''$n raiva sinaliza limite cruzado. 💜 Você está seguro(a)?

Respire 3× devagar. O que aconteceu?''';
  }

  String _loneliness(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '$n' : '';
    return '''$n buscar apoio aqui já é coragem. 💜

Solidão física ou de não ser compreendido(a)?''';
  }

  String _stress(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '$n' : '';
    return '''$n estresse acumulado tem limite. 💜

30s: olhos fechados, ombros soltos.

O que pesa mais — trabalho, relações ou tudo?''';
  }

  String _fear(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '$n' : '';
    return '''$n medo tenta proteger. 💜 É algo específico ou difuso?

Pergunte: probabilidade real? Como eu lidaria se acontecesse?

Do que tem medo agora?''';
  }

  String _positive(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    final streak = user.currentStreak >= 3 ? ' 🔥 ${user.currentStreak} dias de sequência!' : '';
    return '''$n que energia boa! 🌟 Registre no humor do app.$streak

O que contribuiu para esse bem-estar?''';
  }

  String _relationship(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '$n' : '';
    return '''$n relacionamentos tocam o vulnerável. 💜 Conte sem filtro o que está acontecendo.''';
  }

  String _family(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '$n' : '';
    return '''$n família é complexa — amor e história juntos. 💜 O que está pesando?''';
  }

  String _work(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '$n' : '';
    return '''$n trabalho/estudo drenam quando pressionam demais. 💜

É pontual ou acumulado há tempo?''';
  }

  String _breathing() =>
      '''**Box 4-4-4-4** ou diga **"meditação guiada"** para condução completa. 🧘''';

  String _gratitude(MindoUserContext user) {
    final n = user.displayName.isNotEmpty ? '$n' : '';
    return '''$n fico feliz em apoiar — o mérito é seu por cuidar de si. 💜

Como está agora, depois de conversar?''';
  }

  String _confusion() =>
      '''Tudo bem não saber o que sente. 💜 Onde no corpo há sensação agora?''';

  String _empathetic(int index, MindoUserContext user, MindoConversationState state) {
    final n = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    final pool = [
      '${n}o que você trouxe importa. 💜 O que sente no corpo neste instante?',
      '${n}estou acompanhando com atenção plena. 💜 O que aconteceu antes desse estado?',
      '${n}se pudesse mudar uma coisa hoje, qual seria?',
      '${n}quer **meditação guiada**, técnica **CBT** (pensamento negativo) ou continuar conversando?',
      '${n}leio sua mensagem como alguém que precisa ser ouvido(a) sem pressa — pode continuar.',
    ];
    if (state.rapportLevel >= 4) {
      return '''${n}já estamos construindo um fio de confiança nesta conversa. 💜

Não preciso de internet para te acompanhar — uso memória da sessão, técnicas validadas e o contexto do seu perfil no MindFlow.

${pool[index % pool.length]}''';
    }
    return pool[index % pool.length];
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }
}
