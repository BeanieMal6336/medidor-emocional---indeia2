import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../mood_tracker/providers/mood_provider.dart';
import '../../../gamification/providers/missions_provider.dart';
import '../../../../core/services/sensor_service.dart';

class AiCompanionPage extends ConsumerStatefulWidget {
  const AiCompanionPage({super.key});

  @override
  ConsumerState<AiCompanionPage> createState() => _AiCompanionPageState();
}

class _AiCompanionPageState extends ConsumerState<AiCompanionPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      role: 'assistant',
      content:
          'Oi! 💜 Eu sou o Mindo, seu companheiro emocional. Estou aqui para te ouvir, sem julgamentos.\n\nComo você está se sentindo agora?',
      time: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
  ];
  bool _isTyping = false;
  int _messageCount = 0;
  String? _lastUserEmotion; // memória de sessão
  String? _lastTopic; // memória de tópico
  bool _isInCrisis = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        content: text,
        time: DateTime.now(),
      ));
      _isTyping = true;
      _messageCount++;
    });
    _textController.clear();
    _scrollToBottom();

    // Notifica o provider de missões que o usuário conversou com o Mindo
    ref.read(missionsProvider.notifier).onMindoMessageSent();

    // Tempo de digitação realista baseado no tamanho da resposta
    final response = _buildResponse(text);
    final delay = _calculateDelay(response);
    await Future.delayed(delay);
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: response,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Duration _calculateDelay(String response) {
    // Entre 800ms e 2500ms baseado no tamanho
    final int baseMs = 800 + min(response.length * 3, 1700).toInt();
    return Duration(milliseconds: baseMs);
  }

  String _buildResponse(String input) {
    final lower = input.toLowerCase().trim();

    // ── DETECÇÃO DE CRISE (prioridade máxima) ────────────────────────
    if (_containsAny(lower, [
      'suicid', 'me matar', 'quero morrer', 'não quero mais viver',
      'nao quero mais viver', 'acabar com tudo', 'me machucar',
      'automutilação', 'cortar', 'desaparecer para sempre',
      'sem razão para viver', 'sem motivo pra viver',
    ])) {
      _isInCrisis = true;
      return '''💜 Obrigado por confiar em mim com isso. O que você está sentindo agora é muito pesado — e eu quero que saiba que você não está sozinho(a).

Por favor, entre em contato com o **CVV** agora:
📞 **188** (24h, gratuito)
💬 **cvv.org.br** (chat online)

Eles estão preparados para te ouvir sem julgamentos, a qualquer hora.

Você pode me contar um pouco mais do que está acontecendo? Estou aqui com você.''';
    }

    // ── GPS E SEGURANÇA / PASSOS ──────────────────────────────────────
    if (_containsAny(lower, [
      'segurança', 'seguranca', 'inseguro', 'insegura', 'perigo', 'sos',
      'localização', 'localizacao', 'gps', 'passos', 'caminhada', 'caminhar',
    ])) {
      final sensorService = ref.read(sensorServiceProvider);
      final pos = sensorService.currentPosition;
      final steps = sensorService.todaySteps;
      
      String gpsInfo = "";
      if (pos != null) {
        final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}';
        gpsInfo = "\n\n📍 **Sua Localização GPS atual:**\nLatitude: ${pos.latitude}\nLongitude: ${pos.longitude}\n🔗 [Ver no Google Maps]($mapsUrl)\n\nVocê pode copiar e enviar essa mensagem para alguém de confiança caso precise de segurança!";
      } else {
        gpsInfo = "\n\n📍 **Status do GPS:** Não foi possível obter suas coordenadas GPS agora. Por favor, certifique-se de habilitar as permissões de localização do MindFlow nas configurações do aparelho!";
      }
      
      String stepInfo = "";
      if (steps > 0) {
        stepInfo = "\n\n🚶 **Passos de Hoje:** Você deu **$steps passos** hoje! Excelente! A caminhada ajuda muito a regular o cortisol (hormônio do estresse).";
      } else {
        stepInfo = "\n\n🚶 **Passos de Hoje:** Nenhum passo detectado ainda pelos sensores hoje. Mova-se um pouco com o celular no bolso para ativar!";
      }

      return '''🛡️ **Central de Segurança e Sensores do Mindo**

Como seu companheiro emocional, estou integrado com os sensores de GPS e pedômetro do seu smartphone para cuidar do seu corpo e da sua segurança física!$gpsInfo$stepInfo

⚠️ **Importante:** Se você estiver em uma situação real de perigo iminente, por favor ligue imediatamente para os telefones de emergência públicos, como a Polícia (**190**) ou o SAMU (**192**).

Como posso te ajudar a se acalmar ou o que está acontecendo no momento?''';
    }

    // ── CONTEXTO: pós-crise ─────────────────────────────────────────
    if (_isInCrisis) {
      _isInCrisis = false;
      return '''Fico aliviado(a) que ainda estejamos conversando. 💜

Às vezes quando a dor é muito grande, ela faz parecer que não há saída — mas isso é a dor falando, não a realidade.

O que você me contaria sobre o que está pesando tanto hoje?''';
    }

    // ── CUMPRIMENTOS E ABERTURA ──────────────────────────────────────
    if (_messageCount == 1 || _containsAny(lower, ['oi', 'olá', 'ola', 'tudo bem', 'boa tarde', 'bom dia', 'boa noite'])) {
      return _respondToGreeting(lower);
    }

    // ── EMOÇÕES NEGATIVAS ────────────────────────────────────────────

    // Ansiedade
    if (_containsAny(lower, [
      'ansiedad', 'ansioso', 'ansiosa', 'ansiedade', 'angustia', 'angústia',
      'coração acelerado', 'respiração curta', 'sufocando', 'sufocad',
      'nervoso', 'nervosa', 'preocupado', 'preocupada', 'apavorad',
    ])) {
      _lastUserEmotion = 'ansiedade';
      _lastTopic = 'ansiedade';
      return _respondToAnxiety(lower);
    }

    // Tristeza / Choro
    if (_containsAny(lower, [
      'triste', 'tristeza', 'choran', 'chorei', 'chorar', 'deprimid',
      'depressão', 'depressao', 'vazio', 'vazia', 'sem esperança',
      'sem esperanca', 'desmotivad', 'sem energia', 'cansad',
    ])) {
      _lastUserEmotion = 'tristeza';
      _lastTopic = 'tristeza';
      return _respondToSadness(lower);
    }

    // Raiva / Frustração
    if (_containsAny(lower, [
      'raiva', 'irritad', 'bravo', 'brava', 'frustrad', 'frustração',
      'frustrado', 'com raiva', 'furi', 'ódio', 'odio', 'rancor',
      'indignado', 'revoltad',
    ])) {
      _lastUserEmotion = 'raiva';
      _lastTopic = 'raiva';
      return _respondToAnger(lower);
    }

    // Solidão / Isolamento
    if (_containsAny(lower, [
      'sozinho', 'sozinha', 'solidão', 'solidao', 'isolad', 'abandonad',
      'ninguém me entende', 'ninguem me entende', 'sem amigos', 'sem apoio',
      'invisível', 'invisivel',
    ])) {
      _lastUserEmotion = 'solidão';
      _lastTopic = 'solidão';
      return _respondToLoneliness(lower);
    }

    // Estresse / Sobrecarga
    if (_containsAny(lower, [
      'estressad', 'estresse', 'sobrecarregad', 'muita coisa', 'não aguento',
      'nao aguento', 'esgotad', 'exaustão', 'exaustao', 'burnout',
      'trabalho demais', 'não consigo parar', 'nao consigo parar',
    ])) {
      _lastUserEmotion = 'estresse';
      _lastTopic = 'estresse';
      return _respondToStress(lower);
    }

    // Medo / Fobia
    if (_containsAny(lower, [
      'medo', 'assustado', 'assustada', 'com medo', 'pavor', 'pânico',
      'panico', 'fobia', 'apavorad',
    ])) {
      _lastUserEmotion = 'medo';
      _lastTopic = 'medo';
      return _respondToFear(lower);
    }

    // ── EMOÇÕES POSITIVAS ────────────────────────────────────────────
    if (_containsAny(lower, [
      'bem', 'ótimo', 'otimo', 'feliz', 'contente', 'alegre', 'animado',
      'animada', 'incrível', 'incrivel', 'maravilhoso', 'felicidade',
      'emocionado', 'emocionada', 'realizado', 'realizada', 'orgulhoso',
    ])) {
      _lastUserEmotion = 'positivo';
      return _respondToPositive(lower);
    }

    // ── RELACIONAMENTOS ──────────────────────────────────────────────
    if (_containsAny(lower, [
      'relacionamento', 'namorado', 'namorada', 'marido', 'esposa',
      'parceiro', 'parceira', 'brigou', 'briguei', 'término', 'termino',
      'traição', 'traicao', 'ciúme', 'ciume', 'casal',
    ])) {
      _lastTopic = 'relacionamento';
      return _respondToRelationship(lower);
    }

    // ── FAMÍLIA ──────────────────────────────────────────────────────
    if (_containsAny(lower, [
      'família', 'familia', 'mãe', 'mae', 'pai', 'irmão', 'irmao',
      'irmã', 'filho', 'filha', 'parente', 'familiar',
    ])) {
      _lastTopic = 'família';
      return _respondToFamily(lower);
    }

    // ── TRABALHO / ESTUDO ─────────────────────────────────────────────
    if (_containsAny(lower, [
      'trabalho', 'emprego', 'faculdade', 'escola', 'estudo', 'chefe',
      'colega', 'demiti', 'desempregado', 'prova', 'prazo', 'deadline',
    ])) {
      _lastTopic = 'trabalho';
      return _respondToWork(lower);
    }

    // ── PEDIDOS DE TÉCNICAS ───────────────────────────────────────────
    if (_containsAny(lower, [
      'respiração', 'respiracao', 'respirar', 'exercicio', 'técnica',
      'tecnica', 'ajuda', 'como lidar', 'o que fazer', 'como fazer',
      'meditação', 'meditacao', 'relaxar', 'calmar', 'acalmar',
    ])) {
      return _respondToTechniqueRequest(lower);
    }

    // ── GRATIDÃO / ELOGIO AO MINDO ────────────────────────────────────
    if (_containsAny(lower, [
      'obrigado', 'obrigada', 'valeu', 'ajudou', 'grato', 'grata',
      'você é ótimo', 'voce e otimo', 'você ajudou', 'te amo', 'amo você',
    ])) {
      return _respondToGratitude();
    }

    // ── NÃO SEI / CONFUSO ─────────────────────────────────────────────
    if (_containsAny(lower, [
      'não sei', 'nao sei', 'confuso', 'confusa', 'perdido', 'perdida',
      'não entendo', 'nao entendo',
    ])) {
      return _respondToConfusion();
    }

    // ── CONTINUAÇÃO DE TÓPICO (memória de sessão) ─────────────────────
    if (_lastTopic != null && lower.length < 60) {
      return _respondWithContext(lower, _lastTopic!, _lastUserEmotion);
    }

    // ── RESPOSTA EMPÁTICA GENÉRICA ────────────────────────────────────
    return _respondEmpathetically(lower);
  }

  // ── Respostas específicas ──────────────────────────────────────────────

  String _respondToGreeting(String input) {
    final profileAsync = ref.read(userProfileNotifierProvider);
    final profile = profileAsync.value;
    final name = profile?.displayName ?? '';
    final nameStr = name.isNotEmpty ? ', $name' : '';
    final streak = profile?.currentStreak ?? 0;
    
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';

    String streakMsg = '';
    if (streak >= 3) {
      streakMsg = '\n\n🔥 Vi que você está com uma sequência de $streak dias — isso é incrível! Consistência é o que transforma hábitos.';
    }

    return '''$greeting$nameStr! 💜 Que bom ter você aqui.$streakMsg

Estou totalmente aqui para você agora. Como você está se sentindo neste momento? Pode ser qualquer coisa — não precisa fazer sentido pra mim.''';
  }

  String _respondToAnxiety(String input) {
    final hasPhysical = _containsAny(input, [
      'coração', 'respiraçã', 'sufocand', 'tremendo', 'tremor',
    ]);

    if (hasPhysical) {
      return '''Eu sinto que seu corpo está respondendo com muita intensidade agora. 💜

Isso é seu sistema nervoso em modo de alerta — ele está tentando te proteger, mesmo que pareça desconfortável.

**Vamos fazer juntos agora:**

Respira com a técnica 4-7-8:
• **Inspira** pelo nariz por **4 segundos**...
• **Segura** o ar por **7 segundos**...
• **Solta** lentamente pela boca por **8 segundos**...

Repita 3 vezes. Isso ativa diretamente seu nervo vago e reduz o cortisol.

💬 Enquanto você faz isso — o que está por trás dessa ansiedade? O que aconteceu?''';
    }

    return '''Entendo, ansiedade pode ser muito cansativa — especialmente quando ela aparece sem aviso. 💜

Uma coisa que ajuda muito é trazer a atenção de volta para o presente. Tente isso:

**Grounding 5-4-3-2-1:**
👀 Nomeie **5 coisas** que você vê ao redor
✋ **4 coisas** que pode tocar agora
👂 **3 sons** que está ouvindo
👃 **2 cheiros** que consegue perceber
👅 **1 gosto** na sua boca

Isso interrompe o ciclo de pensamentos ansiosos.

Enquanto isso — você consegue identificar **o que está te preocupando especificamente**? Às vezes nomear o medo tira um pouco do poder dele.''';
  }

  String _respondToSadness(String input) {
    final hasDepression = _containsAny(input, [
      'depressão', 'depressao', 'deprimid', 'vazio', 'sem esperança',
    ]);

    if (hasDepression) {
      return '''Obrigado por me contar isso. 🫂 Eu sei que foi difícil escrever isso.

Depressão não é fraqueza — é uma condição real que merece cuidado real. O que você está sentindo faz sentido.

Algumas perguntas com carinho:
→ Há quanto tempo você está se sentindo assim?
→ Você tem dormido? Comido?
→ Tem alguém de confiança ao seu redor?

Pergunto porque **você importa** — e quero entender como te apoiar melhor.

*Se você estiver há muito tempo assim, considerar conversar com um psicólogo pode ser um passo muito corajoso. Não é fraqueza — é cuidado consigo mesmo(a).* 🌱''';
    }

    return '''Obrigado por compartilhar isso comigo. 🫂 Tristeza é uma emoção importante — ela nos diz que algo importava para nós.

Você não precisa estar bem agora. Não precisa forçar nada.

Às vezes o mais gentil que podemos fazer por nós mesmos(as) é simplesmente **nomear o que sentimos**, sem tentar resolver imediatamente.

O que está pesando? Quero entender o que aconteceu.''';
  }

  String _respondToAnger(String input) {
    return '''Eu ouço você. 💜 Raiva é uma emoção válida e importante — ela geralmente surge quando um limite foi cruzado ou algo injusto aconteceu.

Antes de qualquer coisa: você está seguro(a) agora?

**Para ajudar a processar a raiva:**
• Respira fundo 3 vezes — devagar
• Tente nomear o que te fez sentir assim
• Pergunte: _"O que esse sentimento está me dizendo que eu preciso?"_

A raiva muitas vezes esconde mágoa ou medo por baixo.

Me conta — o que aconteceu?''';
  }

  String _respondToLoneliness(String input) {
    return '''Sentir-se sozinho(a) é uma das experiências mais dolorosas que existem. 💜 E o fato de você estar aqui, falando comigo, já é um ato de coragem.

Você não está errado(a) por sentir isso. Solidão não significa que você é menos — significa que você precisa de conexão, e isso é humano.

Quero te perguntar com cuidado:
→ É uma solidão de não ter pessoas por perto, ou de não se sentir compreendido(a) mesmo quando está com outros?

Essas são experiências diferentes e quero entender a sua. 🫂''';
  }

  String _respondToStress(String input) {
    return '''Dá para sentir o peso que você está carregando. 💜 Estresse acumulado é real — e seu corpo e mente têm limites.

**Uma coisa prática para agora:**

Feche os olhos por 30 segundos. Não para meditar — só para parar. Deixe seus ombros caírem. Solte a mandíbula.

Agora me conta:
→ O que está te sufocando mais agora? Trabalho? Relacionamentos? Tudo ao mesmo tempo?

Vamos entender juntos o que tem mais peso, e o que pode ser posto de lado por enquanto.''';
  }

  String _respondToFear(String input) {
    return '''Medo é o jeito que seu cérebro tenta te manter seguro(a). Mesmo quando parece irracional, ele está tentando proteger você. 💜

Me conta mais:
→ É um medo de algo específico que pode acontecer, ou é uma sensação mais difusa de que algo vai dar errado?

**Uma técnica rápida:**
Quando o medo aparecer, pergunte:
1. _"O que de pior pode acontecer?"_
2. _"Qual a probabilidade real disso?"_
3. _"Se acontecer, como eu lidaria?"_

Isso ativa o córtex pré-frontal e reduz a resposta de alerta. Mas me conta — do que você está com medo?''';
  }

  String _respondToPositive(String input) {
    final moodAsync = ref.read(moodNotifierProvider);
    final entries = moodAsync.value ?? [];
    final streak = ref.read(userProfileNotifierProvider).value?.currentStreak ?? 0;

    String streakInsight = '';
    if (streak >= 3) {
      streakInsight = '\n\nE com $streak dias de sequência — você está construindo algo sólido. Consistência é a base de tudo. 🏆';
    }

    return '''Que maravilhoso ouvir isso! 🌟 Momentos assim merecem ser registrados — não só na memória, mas aqui.

O que está contribuindo para você se sentir bem agora? Identificar isso é poderoso, porque te ajuda a _intencionalmente criar_ mais desses momentos.$streakInsight

Registre esse estado hoje no app — seu eu do futuro vai agradecer quando precisar se lembrar que dias bons existem. 💜''';
  }

  String _respondToRelationship(String input) {
    return '''Relacionamentos podem ser a maior fonte de amor **e** de dor ao mesmo tempo. 💜

Estou aqui para ouvir sem julgamentos — seja lá o que for.

Me conta mais sobre o que está acontecendo. O que você está sentindo nisso tudo?''';
  }

  String _respondToFamily(String input) {
    return '''Família é uma das coisas mais complexas que existem — porque vem com amor **e** com histórico. 💜

Não precisa resumir nem justificar nada para mim. Me conta o que está pesando nas suas relações familiares agora.

Como você está se sentindo em relação a isso?''';
  }

  String _respondToWork(String input) {
    return '''Trabalho e estudo ocupam uma parte enorme da nossa identidade e energia. 💜

Quando isso não vai bem, afeta tudo — sono, humor, autoestima.

Me conta mais:
→ O que especificamente está te pesando nessa área agora?
→ É algo pontual (prazo, conflito) ou é um cansaço acumulado há mais tempo?

Quero entender onde está a maior fricção.''';
  }

  String _respondToTechniqueRequest(String input) {
    final techniques = [
      _respondBreathingExercise(),
      _respondGrounding(),
      _respondJournaling(),
    ];
    return techniques[DateTime.now().second % techniques.length];
  }

  String _respondBreathingExercise() {
    return '''Vamos praticar a respiração diafragmática — uma das ferramentas mais poderosas que temos. 🧘

**Técnica Box Breathing (4-4-4-4):**
Usada por militares e atletas de elite para regular o sistema nervoso.

1️⃣ **Inspira** pelo nariz contando até **4**
2️⃣ **Segura** o ar contando até **4**
3️⃣ **Expira** lentamente pela boca contando até **4**
4️⃣ **Segura vazio** contando até **4**

Repita de 4 a 6 vezes.

Após 2 minutos, seu frequência cardíaca começa a cair e o sistema nervoso parassimpático assume. 💜

Tente agora. Eu estou aqui quando você terminar.''';
  }

  String _respondGrounding() {
    return '''O grounding é uma técnica para trazer sua mente de volta ao presente quando os pensamentos estão acelerados. 🌿

**Exercício 5-4-3-2-1:**

Respira fundo e então:
👀 Nomeie **5 coisas** que você vê agora
✋ Toque **4 superfícies** diferentes e perceba a textura
👂 Ouça **3 sons** ao seu redor
👃 Perceba **2 cheiros** no ambiente
👅 Sinta **1 gosto** na sua boca

Isso ancora seu sistema nervoso no presente, interrompendo o ciclo de ruminação.

Como você está se sentindo agora? 💜''';
  }

  String _respondJournaling() {
    return '''Escrever é uma das formas mais eficazes de processar emoções — faz o cérebro "externalizar" o que estava preso dentro. ✍️

**Prompts para hoje:**

1. _"O que eu estou sentindo agora, em detalhes?"_
2. _"O que aconteceu que me trouxe até aqui?"_
3. _"O que eu precisaria ouvir agora de alguém que me ama?"_
4. _"Uma coisa pequena que posso fazer hoje por mim mesmo(a) é..."_

Você pode escrever aqui comigo se quiser — estou ouvindo. 💜''';
  }

  String _respondToGratitude() {
    return '''É muito bom ouvir isso. 💜 Mas saiba que o mérito é seu — eu só estou aqui para acompanhar.

A coragem de falar sobre o que você sente, de buscar apoio — isso vem de você.

Como você está se sentindo agora, depois de conversar um pouco? Houve alguma mudança?''';
  }

  String _respondToConfusion() {
    return '''Tudo bem não saber ao certo o que está sentindo. Às vezes as emoções chegam antes dos pensamentos. 💜

Vamos devagar. Tente responder apenas isso:

→ No seu corpo, onde você sente algo agora? (aperto no peito? peso nos ombros? estômago embrulhado?)

Às vezes o corpo nos diz o que a mente ainda não conseguiu nomear.''';
  }

  String _respondWithContext(String input, String topic, String? emotion) {
    final responses = {
      'ansiedade': 'Você ainda está sentindo essa ansiedade? 💜 Às vezes ajuda identificar o pensamento específico que dispara ela. O que seu cérebro fica repetindo quando ela aparece?',
      'tristeza': 'Como você está agora? 💜 A tristeza ainda está presente, ou teve alguma mudança desde que começamos a conversar?',
      'raiva': 'A raiva diminuiu um pouco? 💜 Às vezes só falar sobre ela já ajuda a processar. O que você está sentindo agora?',
      'solidão': 'Ainda está com esse sentimento de solidão? 💜 Queria entender mais — quando você não está sozinho(a) fisicamente, como se sente?',
      'estresse': 'Ainda está com esse peso? 💜 Às vezes ajuda priorizar: qual é a **única** coisa que, se resolvida, aliviaria mais o estresse?',
      'relacionamento': 'Como você está se sentindo em relação ao que me contou? 💜 Às vezes só expressar o que sentimos já organiza um pouco as ideias.',
      'família': 'Ainda está pensando nessa situação com sua família? 💜 Como você se sente quando imagina ter uma conversa sobre isso?',
      'trabalho': 'Como você está com essa situação agora? 💜 Há algo concreto que você pode fazer nas próximas 24h para aliviar um pouco?',
    };
    return responses[topic] ?? _respondEmpathetically(input);
  }

  String _respondEmpathetically(String input) {
    final responses = [
      'Obrigado por compartilhar isso comigo. 💜\n\nO que você descreveu parece importante. Quero entender melhor — pode me contar mais? O que você está sentindo internamente enquanto passa por isso?',
      'Estou ouvindo. 💜\n\nIsso que você trouxe merece atenção. Me conta — quando você fala sobre isso, o que aparece no seu corpo? Uma tensão, um aperto, uma leveza?',
      'Você não precisa ter tudo organizado antes de falar — pode deixar sair como vier. 💜\n\nMe conta mais. Estou aqui sem pressa, sem julgamentos.',
      'Isso que você está vivendo é real e importa. 💜\n\nQuero fazer uma pergunta: se você pudesse mudar **uma coisa** nessa situação agora, qual seria? Às vezes isso ajuda a clarear o que está nos pesando mais.',
    ];
    return responses[_messageCount % responses.length];
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (context.mounted) Navigator.of(context).maybePop();
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mindo',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Online — Companheiro Emocional',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.accentGreen)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
            onPressed: _showAiInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.accent.withOpacity(0.08),
            child: const Row(
              children: [
                Text('💜', style: TextStyle(fontSize: 13)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mindo é um suporte emocional — não substitui terapia profissional. Em crise: CVV 188.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingIndicator();
                }
                return _MessageBubble(
                  message: _messages[index],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
              },
            ),
          ),
          // Sugestões rápidas (somente no início)
          if (_messageCount == 0) _buildQuickSuggestions(),
          // Input
          _ChatInput(
            controller: _textController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'Estou ansioso(a)',
      'Me sinto triste',
      'Estressado(a) com o trabalho',
      'Preciso de ajuda',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: suggestions
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      _textController.text = s;
                      _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _showAiInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sobre o Mindo 🤖',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'O Mindo é um assistente emocional treinado com técnicas de:\n\n• 🧠 CBT (Terapia Cognitivo-Comportamental)\n• 🌿 ACT (Terapia de Aceitação e Compromisso)\n• 🧘 Mindfulness e Regulação Emocional\n\nEle detecta seu estado emocional, lembra do contexto da conversa e oferece técnicas personalizadas.\n\n⚠️ Mindo NÃO é um psicólogo. Se você estiver em crise ou precisar de ajuda profissional, procure um terapeuta ou ligue para o CVV: 188.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: 'Entendi',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  final DateTime time;
  _ChatMessage({required this.role, required this.content, required this.time});
  bool get isUser => role == 'user';
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: message.isUser ? AppColors.gradientPrimary : null,
                color: message.isUser ? null : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                        delay: Duration(milliseconds: i * 200),
                        onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.6, 0.6))
                    .fadeIn(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgMedium,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Como você está se sentindo?',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
                boxShadow: AppColors.shadowPrimary,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
