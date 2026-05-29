import '../domain/enums/level_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Contexto do usuário
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Estado da conversa
// ─────────────────────────────────────────────────────────────────────────────

enum _Topic {
  none,
  greeting,
  anxiety,
  sadness,
  anger,
  loneliness,
  stress,
  fear,
  sleep,
  positive,
  relationship,
  family,
  work,
  breathing,
  meditation,
  cbtReframe,
  crisis,
  gratitude,
  confusion,
  open,
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
  // Controla se o Mindo já fez uma pergunta aberta e aguarda resposta livre
  final bool awaitingFreeResponse;

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
    this.awaitingFreeResponse = false,
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
    bool? awaitingFreeResponse,
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
        guidedMeditationActive:
            endGuided ? false : guidedMeditationActive ?? this.guidedMeditationActive,
        guidedMeditationStep:
            endGuided ? 0 : guidedMeditationStep ?? this.guidedMeditationStep,
        genericResponseIndex: genericResponseIndex ?? this.genericResponseIndex,
        rapportLevel: rapportLevel ?? this.rapportLevel,
        recentUserMessages: recentUserMessages ?? this.recentUserMessages,
        awaitingFreeResponse: awaitingFreeResponse ?? this.awaitingFreeResponse,
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
        'awaitingFreeResponse': awaitingFreeResponse,
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
        awaitingFreeResponse: json['awaitingFreeResponse'] as bool? ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Resposta do Mindo
// ─────────────────────────────────────────────────────────────────────────────

class MindoReply {
  final String text;
  final MindoConversationState state;
  const MindoReply({required this.text, required this.state});
}

// ─────────────────────────────────────────────────────────────────────────────
// Motor principal — lógica reescrita
// ─────────────────────────────────────────────────────────────────────────────

class MindoEngine {
  MindoReply respond({
    required String input,
    required MindoConversationState state,
    required MindoUserContext user,
  }) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return MindoReply(
        text: 'Pode continuar — estou aqui. 💜',
        state: state,
      );
    }

    final lower = raw.toLowerCase();

    // Histórico: mantém só as 6 últimas
    final history = [...state.recentUserMessages, lower];
    if (history.length > 6) history.removeAt(0);

    var next = state.copyWith(
      userMessageCount: state.userMessageCount + 1,
      lastUserSnippet: lower.length > 100 ? '${lower.substring(0, 100)}...' : lower,
      recentUserMessages: history,
      rapportLevel: (state.rapportLevel + 1).clamp(0, 10),
    );

    // ── 1. CRISE — prioridade máxima ─────────────────────────────────────
    if (_hasCrisis(lower)) {
      return MindoReply(
        text: _crisisResponse(user),
        state: next.copyWith(inCrisis: true, lastTopic: 'crise', awaitingFreeResponse: true),
      );
    }

    // ── 2. MEDITAÇÃO GUIADA EM ANDAMENTO ─────────────────────────────────
    if (next.guidedMeditationActive) {
      return _advanceMeditation(lower, next, user);
    }

    // ── 3. Detecta intenção primária com peso (mais específica vence) ─────
    final intent = _detectPrimaryIntent(lower);

    // ── 4. Usuário respondendo à pergunta aberta anterior do Mindo ────────
    //    Só trata como "continuação" se NÃO identificamos uma intenção nova forte
    if (next.awaitingFreeResponse && intent == _Topic.none && next.lastTopic != null) {
      return _handleFreeResponse(lower, next, user);
    }

    // ── 5. Intenções específicas ──────────────────────────────────────────
    switch (intent) {
      case _Topic.greeting:
        return MindoReply(
          text: _greeting(user),
          state: next.copyWith(lastTopic: 'saudacao', awaitingFreeResponse: true),
        );

      case _Topic.meditation:
        next = next.copyWith(guidedMeditationActive: true, guidedMeditationStep: 0, lastTopic: 'meditação');
        return MindoReply(text: _guidedIntro(user), state: next);

      case _Topic.breathing:
        return MindoReply(
          text: _breathingTechnique(),
          state: next.copyWith(lastTopic: 'respiração', awaitingFreeResponse: false),
        );

      case _Topic.cbtReframe:
        return MindoReply(
          text: _cbtReframe(user),
          state: next.copyWith(lastTopic: 'reframe', lastEmotion: 'pensamento negativo', awaitingFreeResponse: true),
        );

      case _Topic.anxiety:
        return MindoReply(
          text: _anxiety(lower, user),
          state: next.copyWith(lastTopic: 'ansiedade', lastEmotion: 'ansiedade', awaitingFreeResponse: true),
        );

      case _Topic.sadness:
        return MindoReply(
          text: _sadness(lower, user),
          state: next.copyWith(lastTopic: 'tristeza', lastEmotion: 'tristeza', awaitingFreeResponse: true),
        );

      case _Topic.anger:
        return MindoReply(
          text: _anger(user),
          state: next.copyWith(lastTopic: 'raiva', lastEmotion: 'raiva', awaitingFreeResponse: true),
        );

      case _Topic.loneliness:
        return MindoReply(
          text: _loneliness(user),
          state: next.copyWith(lastTopic: 'solidão', lastEmotion: 'solidão', awaitingFreeResponse: true),
        );

      case _Topic.stress:
        return MindoReply(
          text: _stress(user),
          state: next.copyWith(lastTopic: 'estresse', lastEmotion: 'estresse', awaitingFreeResponse: true),
        );

      case _Topic.fear:
        return MindoReply(
          text: _fear(lower, user),
          state: next.copyWith(lastTopic: 'medo', lastEmotion: 'medo', awaitingFreeResponse: true),
        );

      case _Topic.sleep:
        return MindoReply(
          text: _sleepSupport(user),
          state: next.copyWith(lastTopic: 'sono', awaitingFreeResponse: true),
        );

      case _Topic.positive:
        return MindoReply(
          text: _positive(user),
          state: next.copyWith(lastTopic: 'positivo', lastEmotion: 'positivo', awaitingFreeResponse: true),
        );

      case _Topic.relationship:
        return MindoReply(
          text: _relationship(user),
          state: next.copyWith(lastTopic: 'relacionamento', awaitingFreeResponse: true),
        );

      case _Topic.family:
        return MindoReply(
          text: _family(user),
          state: next.copyWith(lastTopic: 'família', awaitingFreeResponse: true),
        );

      case _Topic.work:
        return MindoReply(
          text: _work(user),
          state: next.copyWith(lastTopic: 'trabalho', awaitingFreeResponse: true),
        );

      case _Topic.gratitude:
        return MindoReply(
          text: _gratitude(user),
          state: next.copyWith(lastTopic: 'gratidao', awaitingFreeResponse: true),
        );

      case _Topic.confusion:
        return MindoReply(
          text: _confusion(),
          state: next.copyWith(lastTopic: 'confusão', awaitingFreeResponse: true),
        );

      // Sem intenção clara
      case _Topic.none:
      case _Topic.crisis:
      case _Topic.open:
        break;
    }

    // ── 6. Mensagem longa sem intenção clara → resposta empática aberta ───
    if (lower.length > 30) {
      return MindoReply(
        text: _empatheticOpen(lower, next, user),
        state: next.copyWith(
          lastTopic: next.lastTopic ?? 'aberto',
          awaitingFreeResponse: true,
          genericResponseIndex: (next.genericResponseIndex + 1) % 5,
        ),
      );
    }

    // ── 7. Mensagem curta ambígua → pergunta aberta ───────────────────────
    return MindoReply(
      text: _shortMessageResponse(next, user),
      state: next.copyWith(
        lastTopic: next.lastTopic ?? 'aberto',
        awaitingFreeResponse: true,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Detecção de intenção — ordem de especificidade (mais específico = mais peso)
  // ─────────────────────────────────────────────────────────────────────────

  _Topic _detectPrimaryIntent(String lower) {
    // Crise já tratada antes
    // Meditação guiada — precisa de palavras bem específicas
    if (_any(lower, [
      'meditação guiada', 'meditacao guiada', 'me guie', 'me guia',
      'quero meditar', 'iniciar meditação', 'iniciar meditacao',
      'sessão guiada', 'sessao guiada',
    ])) return _Topic.meditation;

    // CBT
    if (_any(lower, [
      'pensamento negativo', 'nao consigo parar de pensar', 'não consigo parar de pensar',
      'ruminação', 'ruminacao', 'mente acelerada', 'reformular pensamento',
      'pensamento automático', 'loop na cabeça',
    ])) return _Topic.cbtReframe;

    // Respiração sem meditação guiada
    if (_any(lower, [
      'técnica de respiração', 'tecnica de respiracao', 'respiração 4', 'box breathing',
      'quero respirar', 'me ensina a respirar',
    ])) return _Topic.breathing;

    // Sono — antes de estresse (cansado pode ser das duas)
    if (_any(lower, [
      'insônia', 'insonia', 'não consigo dormir', 'nao consigo dormir',
      'acordando muito', 'sono ruim', 'dormir mal',
    ])) return _Topic.sleep;

    // Crise (já tratada acima, mas mantém consistência)
    if (_hasCrisis(lower)) return _Topic.crisis;

    // Ansiedade — palavras bem específicas
    if (_any(lower, [
      'ansiedade', 'ansioso', 'ansiosa', 'angústia', 'angustia',
      'ataque de pânico', 'panico', 'coração acelerado', 'tensão no peito',
      'preocupado', 'preocupada', 'nervoso demais', 'nervosa demais',
    ])) return _Topic.anxiety;

    // Tristeza — específicas
    if (_any(lower, [
      'triste', 'tristeza', 'chorando', 'chorei', 'chorar',
      'deprimido', 'deprimida', 'depressão', 'depressao',
      'sem esperança', 'sem esperanca', 'vazio', 'vazia',
      'desmotivado', 'desmotivada',
    ])) return _Topic.sadness;

    // Raiva
    if (_any(lower, [
      'raiva', 'com raiva', 'com ódio', 'ódio', 'odio',
      'frustrado', 'frustrada', 'irritado', 'irritada',
      'bravo', 'brava', 'com raiva de',
    ])) return _Topic.anger;

    // Solidão
    if (_any(lower, [
      'sozinho', 'sozinha', 'solidão', 'solidao',
      'me sinto isolado', 'me sinto isolada', 'ninguém me entende',
      'ninguem me entende', 'sem amigos', 'sem apoio',
    ])) return _Topic.loneliness;

    // Estresse / burnout
    if (_any(lower, [
      'estressado', 'estressada', 'estresse', 'sobrecarregado', 'sobrecarregada',
      'burnout', 'esgotado', 'esgotada', 'não aguento mais', 'nao aguento mais',
    ])) return _Topic.stress;

    // Medo — específico
    if (_any(lower, [
      'com medo de', 'tenho medo de', 'medo de', 'assustado', 'assustada',
      'fobia', 'pavor de',
    ])) return _Topic.fear;

    // Sono (genérico, depois do específico)
    if (_any(lower, ['cansado', 'cansada', 'exausto', 'exausta', 'sem dormir', 'dormir'])) {
      return _Topic.sleep;
    }

    // Positivo — só com palavras claramente positivas E sem negação perto
    if (_isPositive(lower)) return _Topic.positive;

    // Relacionamento
    if (_any(lower, [
      'meu namorado', 'minha namorada', 'meu parceiro', 'minha parceira',
      'término', 'termino', 'separação', 'separacao', 'brigar com',
      'relacionamento', 'namoro',
    ])) return _Topic.relationship;

    // Família
    if (_any(lower, [
      'minha mãe', 'meu pai', 'minha familia', 'minha família',
      'meu irmão', 'minha irmã', 'briga em casa', 'conflito familiar',
    ])) return _Topic.family;

    // Trabalho / estudo
    if (_any(lower, [
      'meu trabalho', 'no trabalho', 'meu chefe', 'minha chefe',
      'faculdade', 'escola', 'prova amanhã', 'demitido', 'demitida',
      'perdi o emprego', 'entrevista',
    ])) return _Topic.work;

    // Gratidão
    if (_any(lower, [
      'obrigado', 'obrigada', 'valeu', 'muito obrigado', 'muito obrigada',
      'me ajudou', 'você ajudou', 'grato', 'grata',
    ])) return _Topic.gratitude;

    // Confusão
    if (_any(lower, [
      'não sei o que sinto', 'nao sei o que sinto',
      'confuso', 'confusa', 'perdido', 'perdida', 'não sei', 'nao sei',
    ])) return _Topic.confusion;

    // Saudação simples — só se a mensagem for curta
    if (lower.length < 35 &&
        _any(lower, ['oi', 'olá', 'ola', 'bom dia', 'boa tarde', 'boa noite', 'hey', 'hello', 'e aí', 'e ai'])) {
      return _Topic.greeting;
    }

    return _Topic.none;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resposta a mensagem livre (usuário respondendo a uma pergunta do Mindo)
  // ─────────────────────────────────────────────────────────────────────────

  MindoReply _handleFreeResponse(String lower, MindoConversationState state, MindoUserContext user) {
    final name = _nameComma(user);
    final topic = state.lastTopic ?? 'aberto';

    // CBT reframe — passou pelo passo 1 (situação), agora pede passo 2
    if (topic == 'reframe') {
      return MindoReply(
        text: '''$name anotei. 🧠💜

**Passo 2 — Pensamento automático:** qual foi a primeira frase que sua mente disse quando isso aconteceu?

Ex.: _"Não vou dar conta"_, _"Todo mundo vai me julgar"_, _"Nunca vai melhorar"_...

Escreva o seu.''',
        state: state.copyWith(lastTopic: 'reframe_p2', awaitingFreeResponse: true),
      );
    }

    if (topic == 'reframe_p2') {
      return MindoReply(
        text: '''$name esse pensamento é muito humano. 💜

**Passo 3 — Evidências:**
• Cite **2 fatos** que *apoiam* esse pensamento
• Cite **2 fatos** que *questionam* ou contradizem ele

Depois escreva: _"Um pensamento mais equilibrado seria..."_

Pode ir passo a passo, sem pressa.''',
        state: state.copyWith(lastTopic: 'reframe_p3', awaitingFreeResponse: true),
      );
    }

    if (topic == 'reframe_p3') {
      return MindoReply(
        text: '''$name excelente trabalho. 🌟 Isso é CBT na prática — você acabou de treinar o músculo da mente.

Como está se sentindo **agora** em comparação ao início da conversa?''',
        state: state.copyWith(lastTopic: 'reflexão', awaitingFreeResponse: true),
      );
    }

    // Meditação concluída — usuário responde como está o corpo
    if (topic == 'meditação') {
      if (_any(lower, ['leve', 'melhor', 'calmo', 'calma', 'tranquilo', 'tranquila', 'bem'])) {
        return MindoReply(
          text: '${name}fico feliz! 🌿 Presença é prática — cada vez fica mais fácil. Como está o resto do dia?',
          state: state.copyWith(lastTopic: 'positivo', awaitingFreeResponse: true),
        );
      }
      if (_any(lower, ['igual', 'tenso', 'tensa', 'ainda', 'não mudou', 'nao mudou'])) {
        return MindoReply(
          text: '''${name}tudo bem — às vezes a calma chega depois. 💜

Quer tentar uma técnica rápida de ancoragem agora? Foca em **5 coisas que você enxerga** no ambiente. Me conta o que você vê.''',
          state: state.copyWith(lastTopic: 'ansiedade', awaitingFreeResponse: true),
        );
      }
    }

    // Resposta genérica contextual baseada no último tópico
    final Map<String, String> topicFollowUps = {
      'ansiedade':
          '${name}obrigado por compartilhar. 💜 O pensamento que está em loop agora — ele é sobre o passado, o presente ou o futuro?',
      'tristeza':
          '${name}sentir isso mostra que algo importante foi tocado. 💜 O que você mais precisaria agora: silêncio, movimento ou conversar mais?',
      'raiva':
          '${name}raiva traz informação importante sobre seus limites. 💜 Você consegue identificar o momento exato em que ela apareceu?',
      'solidão':
          '${name}contar isso já é um passo corajoso. 💜 Há alguém específico com quem você gostaria de se conectar, ou é uma sensação mais geral?',
      'estresse':
          '${name}entendido. 💜 Das coisas que estão pesando, qual você tem **zero** controle — e pode deixar de lado por agora?',
      'medo':
          '${name}obrigado por confiar. 💜 Esse medo aparece o tempo todo ou em situações específicas?',
      'sono':
          '${name}sono e emoção caminham juntos. 💜 Quando você deita, sua mente acelera ou o corpo fica inquieto?',
      'relacionamento':
          '${name}conte mais. 💜 O que você precisaria que acontecesse para essa situação melhorar?',
      'família':
          '${name}família é complexa — amor e história juntos. 💜 Você se sente ouvido(a) por eles?',
      'trabalho':
          '${name}trabalho pode pesar muito. 💜 Isso está afetando só o humor ou já está impactando o sono e o corpo?',
      'saudacao':
          '${name}fico aqui com você. 💜 O que mais está presente agora — algo que aconteceu, ou uma sensação sem causa clara?',
      'reflexão':
          '${name}isso é perspectiva real. 💜 O que essa percepção muda, mesmo que um pouquinho, daqui pra frente?',
    };

    final followUp = topicFollowUps[topic];
    if (followUp != null) {
      return MindoReply(
        text: followUp,
        state: state.copyWith(awaitingFreeResponse: true),
      );
    }

    // Fallback
    return MindoReply(
      text: '${name}estou acompanhando com atenção. 💜 O que você está sentindo agora, neste momento?',
      state: state.copyWith(awaitingFreeResponse: true),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resposta empática para mensagens longas sem intenção clara
  // ─────────────────────────────────────────────────────────────────────────

  String _empatheticOpen(String lower, MindoConversationState state, MindoUserContext user) {
    final name = _nameComma(user);
    final idx = state.genericResponseIndex % 5;

    final List<String> responses = [
      '${name}estou lendo o que você escreveu com atenção real. 💜\n\nO que mais pesa nisso tudo que você descreveu?',
      '${name}obrigado por compartilhar isso comigo. 💜\n\nSe tivesse que colocar em uma palavra o que está sentindo agora, qual seria?',
      '${name}faz sentido sentir isso. 💜\n\nO que aconteceu que trouxe esse estado — algo específico ou é uma acumulação?',
      '${name}estou aqui, sem pressa. 💜\n\nAlguma coisa no que você descreveu está no seu controle agora, mesmo que pequena?',
      '${name}sua mensagem mostra alguém que está tentando processar algo difícil. 💜\n\nO que você precisaria agora: ser ouvido(a), uma técnica de alívio, ou clareza?',
    ];

    return responses[idx];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resposta para mensagens curtas ambíguas
  // ─────────────────────────────────────────────────────────────────────────

  String _shortMessageResponse(MindoConversationState state, MindoUserContext user) {
    final name = _nameComma(user);

    // Se há tópico anterior, usa ele como gancho
    if (state.lastTopic != null && state.lastTopic != 'aberto') {
      return '${name}continue à vontade. 💜 Me conta mais sobre o que está sentindo.';
    }

    return '${name}pode falar mais sobre isso? 💜 Estou aqui para ouvir sem julgamento.';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers de detecção
  // ─────────────────────────────────────────────────────────────────────────

  bool _hasCrisis(String lower) => _any(lower, [
        'suicid', 'me matar', 'quero morrer', 'não quero mais viver',
        'nao quero mais viver', 'acabar com tudo', 'me machucar',
        'automutilação', 'automutilacao', 'desaparecer para sempre',
        'não vale a pena viver', 'nao vale a pena viver',
      ]);

  bool _isPositive(String lower) {
    // Não marca como positivo se há negação + palavra positiva
    final hasNegation = _any(lower, [
      'não estou bem', 'nao estou bem', 'não me sinto', 'nao me sinto',
      'mal', 'ruim', 'péssimo', 'pessimo', 'horrível', 'horrivel',
      'cansado', 'cansada', 'exausto', 'exausta',
    ]);
    if (hasNegation) return false;
    return _any(lower, [
      'feliz', 'muito bem', 'ótimo', 'otimo', 'maravilhoso', 'maravilhosa',
      'alegre', 'contente', 'realizado', 'realizada', 'orgulhoso', 'orgulhosa',
      'gratidão', 'gratidao', 'animado', 'animada',
    ]);
  }

  bool _any(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Meditação guiada
  // ─────────────────────────────────────────────────────────────────────────

  MindoReply _advanceMeditation(
      String lower, MindoConversationState state, MindoUserContext user) {
    if (_any(lower, ['parar', 'cancelar', 'sair', 'encerrar', 'chega'])) {
      return MindoReply(
        text: 'Sessão encerrada com cuidado. 💜 Respire fundo uma vez. Estou aqui — como está se sentindo?',
        state: state.copyWith(endGuided: true, lastTopic: 'meditação', awaitingFreeResponse: true),
      );
    }

    final step = state.guidedMeditationStep + 1;
    final steps = _guidedSteps(user);

    if (step >= steps.length) {
      return MindoReply(
        text: '''🧘✨ **Sessão guiada concluída.**

Você praticou presença — isso é saúde mental ativa. Registre seu humor no app.

Como está o corpo agora: mais leve, igual ou ainda tenso?''',
        state: state.copyWith(endGuided: true, lastTopic: 'meditação', awaitingFreeResponse: true),
      );
    }

    return MindoReply(
      text: steps[step],
      state: state.copyWith(guidedMeditationStep: step, lastTopic: 'meditação'),
    );
  }

  List<String> _guidedSteps(MindoUserContext user) => [
        _guidedIntro(user),
        '''**Passo 1 — Chegada** 🌿

Ajuste a postura. Feche os olhos.
Inspire pelo nariz contando **4** · Segure **4** · Expire pela boca contando **6**.
Faça 3 ciclos assim.

Quando terminar, diga **"próximo"**.''',
        '''**Passo 2 — Escaneamento do corpo** 🫁

Atenção nos pés → pernas → quadril → barriga → peito → ombros → rosto.
Em cada região: perceba, sem forçar, e deixe soltar.

**"próximo"** para continuar.''',
        '''**Passo 3 — Âncora** 💜

Repita internamente 3 vezes:
_"Agora mesmo, estou seguro(a) o suficiente para respirar."_

Fique 20 segundos em silêncio.

**"próximo"** quando estiver pronto(a).''',
        '''**Passo 4 — Gratidão** ✨

Pense em uma coisa pequena de hoje que ainda existe — pode ser o café, a luz pela janela, um som agradável.

Fique com essa imagem por 15 segundos.

**"próximo"** para encerrar.''',
      ];

  String _guidedIntro(MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? ', ${user.displayName}' : '';
    return '''🧘 **Meditação guiada Mindo**$name

Vou te conduzir passo a passo (~5 min). Responda **"próximo"** para avançar — **"parar"** para encerrar a qualquer momento.

Para áudio ambiente durante a meditação: acesse **Meditação Flow** no app.

Quando estiver confortável, diga **"próximo"**.''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Respostas por tópico
  // ─────────────────────────────────────────────────────────────────────────

  String _crisisResponse(MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    return '''${name}obrigado por confiar em mim. O que você sente é real e pesado — você não está sozinho(a). 💜

**Se precisar de apoio imediato:**
🆘 **CVV — ligue 188** (24h, gratuito)
🌐 **cvv.org.br** (chat online)

Estou aqui. O que está acontecendo neste momento?''';
  }

  String _greeting(MindoUserContext user) {
    final hour = DateTime.now().hour;
    final period = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';
    final name = user.displayName.isNotEmpty ? ', ${user.displayName}' : '';
    final journeyInfo = user.daysOnJourney <= 1
        ? 'Primeiro dia — começamos com intenção.'
        : 'Dia **${user.daysOnJourney}** · nível **${user.level.label}** ${user.level.emoji} · **${user.totalXp} XP**';
    final streak = user.currentStreak >= 2 ? '\n🔥 Sequência: **${user.currentStreak}** dias.' : '';
    final moodTip = user.loggedMoodToday
        ? ''
        : '\n📊 Lembre de registrar seu humor hoje.';

    return '$period$name! 💜 $journeyInfo$streak$moodTip\n\nO que está mais presente em você agora?';
  }

  String _anxiety(String lower, MindoUserContext user) {
    final name = _nameComma(user);
    if (_any(lower, ['coração acelerado', 'sufocando', 'tremendo', 'não consigo respirar', 'peito apertado'])) {
      return '''${name}seu corpo está em modo de proteção — é biológico, não é fraqueza. 💜

**Agora:** inspire pelo nariz contando 4 · segure 7 · solte pela boca contando 8.
Repita 3 vezes.

Estou aqui. O que disparou isso?''';
    }
    return '''${name}ansiedade é pesada — e você fez bem em falar sobre isso. 💜

**Técnica 5-4-3-2-1** (grounding):
5 coisas que você *vê* · 4 que *toca* · 3 que *ouve* · 2 que *cheira* · 1 que *sente*.

Qual pensamento está mais alto agora?''';
  }

  String _sadness(String lower, MindoUserContext user) {
    final name = _nameComma(user);
    if (_any(lower, ['depressão', 'depressao', 'deprimido', 'deprimida', 'sem esperança', 'sem esperanca'])) {
      return '''${name}obrigado por confiar — isso é sofrimento real, não fraqueza. 🫂

Há quanto tempo está assim? Está conseguindo comer e dormir?

Se esse estado persistir, um profissional pode ajudar muito. O que pesa mais hoje?''';
    }
    return '''${name}tristeza mostra que algo que importa foi tocado. 🫂

Você não precisa estar bem agora.

O que aconteceu?''';
  }

  String _anger(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}raiva sinaliza que um limite foi cruzado — é uma emoção válida. 💜

Você está seguro(a) agora?

Respire devagar 3 vezes. O que aconteceu?''';
  }

  String _loneliness(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}buscar apoio aqui já é coragem. 💜

É solidão de estar fisicamente só, ou de sentir que ninguém te compreende de verdade?''';
  }

  String _stress(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}estresse acumulado tem peso. 💜

Tente agora: 30 segundos com os olhos fechados, ombros soltos.

O que está pesando mais — trabalho, relações, ou tudo ao mesmo tempo?''';
  }

  String _fear(String lower, MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}medo tenta proteger — mas às vezes ele exagera. 💜

É medo de algo específico ou uma sensação difusa de que algo vai dar errado?

Do que exatamente você está com medo agora?''';
  }

  String _sleepSupport(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}sono e humor estão diretamente ligados. 😴💜

**Higiene rápida Mindo:**
• Luz baixa 1h antes de dormir
• Evitar telas (ou usar modo noturno)
• **4-7-8**: inspire 4s · segure 7s · solte 8s (×3 antes de deitar)

${user.loggedMoodToday ? '' : 'Registrar o humor no app ajuda a ver padrões sono ↔ emoção.\n'}
O que mais atrapalha: mente acelerada, preocupação ou corpo inquieto?''';
  }

  String _positive(MindoUserContext user) {
    final name = _nameComma(user);
    final streak = user.currentStreak >= 3 ? ' 🔥 ${user.currentStreak} dias seguidos!' : '';
    return '''${name}que energia boa! 🌟$streak

Registra isso no humor do app — ajuda a ver o que contribui para os bons momentos.

O que aconteceu de especial hoje?''';
  }

  String _relationship(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}relacionamentos tocam o mais vulnerável em nós. 💜

Pode contar sem filtro — o que está acontecendo?''';
  }

  String _family(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}família é amor e história misturados — e nem sempre é simples. 💜

O que está pesando agora?''';
  }

  String _work(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}trabalho e estudo drenam quando a pressão é alta. 💜

Isso está acontecendo há pouco ou vem se acumulando?''';
  }

  String _breathingTechnique() =>
      '''**Técnica Box Breathing (4-4-4-4)** 🧘

Inspire 4s → Segure 4s → Expire 4s → Segure 4s.

Repita 4 vezes. Quando terminar, me conta como está.

Se quiser uma sessão completa guiada, diga **"meditação guiada"**.''';

  String _cbtReframe(MindoUserContext user) {
    final name = user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
    return '''${name}vamos usar **Terapia Cognitivo-Comportamental (CBT)** em 3 passos. 🧠💜

**Passo 1 — Situação:** descreva o que aconteceu *em fatos*, sem interpretação.

Ex.: _"Meu chefe não respondeu meu e-mail"_, _"Fui ignorado(a) numa conversa"_

Escreva sua situação quando quiser — vou te acompanhar passo a passo.''';
  }

  String _gratitude(MindoUserContext user) {
    final name = _nameComma(user);
    return '''${name}fico feliz em poder apoiar. O mérito é seu por cuidar de si. 💜

Como está se sentindo agora, depois de conversar?''';
  }

  String _confusion() =>
      '''Tudo bem não saber exatamente o que está sentindo. 💜

Vamos devagar. Onde no corpo você percebe alguma sensação agora — peito, estômago, garganta?''';

  // ─────────────────────────────────────────────────────────────────────────
  // Mensagem de boas-vindas (estática)
  // ─────────────────────────────────────────────────────────────────────────

  static String welcomeMessage(String name) {
    final n = name.isNotEmpty ? ', $name' : '';
    return 'Oi$n! 💜 Sou o **Mindo**, companheiro emocional do MindFlow.\n\n'
        'Estou aqui para ouvir, apoiar e oferecer técnicas de mindfulness e CBT — '
        'sem substituir um profissional de saúde mental.\n\n'
        'Como você está se sentindo agora?';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilitários
  // ─────────────────────────────────────────────────────────────────────────

  String _nameComma(MindoUserContext user) =>
      user.displayName.isNotEmpty ? '${user.displayName}, ' : '';
}
