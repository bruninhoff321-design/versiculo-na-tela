/// Prepara uma oração local quando não há um serviço de geração conectado.
/// A mesma data, período e necessidade produzem o mesmo texto; no dia seguinte
/// a escolha das frases muda. Não depende de rede nem envia o relato da pessoa.
class PrayerComposer {
  const PrayerComposer();

  String? labelFor(String themeId) => _themeLabels[themeId];

  String idFor({
    required DateTime day,
    required bool morning,
    Iterable<String> themeIds = const [],
    String? verseReference,
  }) {
    final themes = themeIds.toSet().toList();
    return 'v2-${day.year}-${day.month}-${day.day}'
        '-${morning ? 'manha' : 'noite'}-${themes.join('_')}'
        '-${verseReference?.trim() ?? ''}';
  }

  String compose({
    required DateTime day,
    required bool morning,
    Iterable<String> themeIds = const [],
    String? verseReference,
  }) {
    final date = DateTime.utc(day.year, day.month, day.day);
    final dayNumber = date.difference(DateTime.utc(2020)).inDays;
    final period = morning ? 0 : 1;
    final variation = dayNumber * 2 + period;
    final opening = morning ? _morningOpenings : _eveningOpenings;
    final petition = morning ? _morningPetitions : _eveningPetitions;
    final themes = themeIds.toSet().where(_themePetitions.containsKey).toList();
    final focusedThemes = themes.take(2).toList();
    // Sem uma necessidade escolhida, o assunto também varia a cada dia.
    final dailyNeed = _dailyThemes[variation % _dailyThemes.length];

    final parts = <String>[
      if (focusedThemes.isNotEmpty)
        'Senhor Deus, tu conheces o que estou vivendo, inclusive o que ainda '
            'não consigo colocar em palavras. Acolhe-me neste momento.',
      for (final theme in focusedThemes) ...[
        'Hoje trago especialmente a ti minha necessidade de ${_themeLabels[theme]}.',
        _themePetitions[theme]!,
        if (theme == focusedThemes.first) _themeReflections[theme]!,
      ],
      opening[variation % opening.length],
      petition[(variation ~/ 5) % petition.length],
      if (focusedThemes.isEmpty) _themePetitions[dailyNeed]!,
      if (focusedThemes.isEmpty)
        _gratitudes[(variation ~/ 3) % _gratitudes.length]
      else
        'Obrigado por me ouvir com paciência e por me lembrar que posso pedir ajuda.',
      if (focusedThemes.isEmpty)
        _intercessions[(variation ~/ 7) % _intercessions.length]
      else
        'Cuida também de quem vive uma dor parecida e aproxima de nós pessoas dispostas a ouvir.',
      if (focusedThemes.isNotEmpty)
        'Volto a colocar ${_themeLabels[focusedThemes.first]} diante de ti. '
            'Que esta oração se torne apoio concreto para o próximo passo de hoje.',
      _reflections[(variation ~/ 25) % _reflections.length],
      if (focusedThemes.isEmpty)
        _commitments[(variation ~/ 11) % _commitments.length],
      if (verseReference != null && verseReference.trim().isNotEmpty)
        'Ao lembrar da tua Palavra em ${verseReference.trim()}, '
            'ajuda-me a vivê-la hoje.',
      _closings[(variation ~/ 125) % _closings.length],
    ];
    return parts.join(' ');
  }

  static const _morningOpenings = [
    'Senhor Deus, obrigado por este novo dia e pelo cuidado que me trouxe até aqui.',
    'Pai amado, começo este dia na tua presença e entrego a ti meus caminhos.',
    'Meu Deus, recebo esta manhã com gratidão pela vida e pela tua misericórdia.',
    'Senhor, antes de começar minhas tarefas, quero descansar meu coração em ti.',
    'Pai, obrigado pela oportunidade de recomeçar e caminhar contigo hoje.',
  ];

  static const _eveningOpenings = [
    'Senhor Deus, ao chegar a noite, agradeço por tua presença durante o dia.',
    'Pai amado, entrego a ti este dia com suas alegrias e dificuldades.',
    'Meu Deus, agora que a noite chegou, aquieta meus pensamentos diante de ti.',
    'Senhor, obrigado por me sustentar até este momento; acolhe meu descanso.',
    'Pai, deixo em tuas mãos tudo o que vivi hoje e o que ainda não resolvi.',
  ];

  static const _morningPetitions = [
    'Dá-me sabedoria nas escolhas e gentileza com as pessoas que encontrar.',
    'Conduz meus passos e ajuda-me a agir com coragem e amor.',
    'Ensina-me a perceber o que é importante e a cuidar bem de quem está perto.',
    'Que tua Palavra ilumine minhas decisões e fortaleça minha fé.',
    'Ajuda-me a começar sem pressa no coração, confiando no teu cuidado.',
  ];

  static const _eveningPetitions = [
    'Perdoa minhas falhas e renova minhas forças para amanhã.',
    'Afasta a ansiedade e permite que eu descanse em paz.',
    'Ajuda-me a agradecer pelo bem recebido e a aprender com o que foi difícil.',
    'Cuida das pessoas que amo enquanto descanso.',
    'Que eu possa soltar as preocupações que não consigo resolver agora.',
  ];

  static const _dailyThemes = [
    'paz',
    'familia',
    'esperanca',
    'trabalho',
    'fe',
    'gratidao',
    'recomeco',
  ];

  static const _gratitudes = [
    'Obrigado pelas pessoas que caminham comigo, pelos pequenos cuidados que recebo e pelas oportunidades de fazer o bem. Mesmo quando o dia não acontece como imaginei, ajuda-me a perceber motivos sinceros para agradecer.',
    'Agradeço pela vida, pelo pão de hoje e pela chance de aprender de novo. Que eu não passe apressado pelas coisas simples nem esqueça de reconhecer quem me ajuda a continuar.',
    'Obrigado porque posso trazer a ti minhas dúvidas sem esconder o que sinto. Abre meus olhos para as bênçãos discretas deste dia e ensina-me a cuidar delas com alegria.',
  ];

  static const _intercessions = [
    'Lembro também de quem enfrenta dor, solidão ou falta de recursos. Dá consolo, companhia e ajuda concreta a essas pessoas; mostra-me quando posso ser uma resposta por meio de um gesto de bondade.',
    'Cuida de quem amo e de quem hoje precisa de forças para seguir. Aproxima pessoas dispostas a ouvir e a ajudar, e faz de mim alguém atento ao sofrimento do próximo.',
    'Peço por aqueles que estão cansados, doentes ou preocupados com o amanhã. Que encontrem acolhimento e caminhos de cuidado; ensina-nos a não deixar ninguém caminhar sozinho.',
  ];

  static const _commitments = [
    'Quero ouvir antes de responder, agir com justiça e não perder a esperança quando houver obstáculos. Se eu errar, dá-me humildade para reconhecer e coragem para recomeçar.',
    'Ajuda-me a fazer minha parte com honestidade e paciência. Que minhas palavras levem paz, que minhas escolhas respeitem o próximo e que eu saiba pedir ajuda quando precisar.',
    'Ensina-me a transformar esta oração em atitudes: cuidar, perdoar com sabedoria e perseverar no que é bom. Não quero viver apenas de palavras, mas caminhar contigo de verdade.',
  ];

  static const _reflections = [
    'Ajuda-me a reconhecer tua presença também nos pequenos momentos.',
    'Que eu possa tratar os outros com a mesma misericórdia que peço para mim.',
    'Ensina-me a caminhar com humildade, esperança e gratidão.',
    'Quando eu perder o rumo, lembra-me de voltar à tua Palavra.',
    'Mesmo sem todas as respostas, escolho confiar no teu cuidado.',
  ];

  static const _closings = [
    'Que eu me lembre de que não caminho sozinho. Em nome de Jesus, amém.',
    'Fica comigo e guia meu coração. Em nome de Jesus, amém.',
    'Confio a ti o que não posso controlar. Em nome de Jesus, amém.',
    'Que tua paz permaneça comigo. Em nome de Jesus, amém.',
    'Recebe esta oração e fortalece minha fé. Em nome de Jesus, amém.',
  ];

  static const _themePetitions = <String, String>{
    'paz': 'Acalma meu coração e ensina-me a viver tua paz.',
    'ansiedade':
        'Quando a preocupação crescer, ajuda-me a respirar e confiar em ti.',
    'medo': 'Dá-me coragem diante do medo e lembra-me de que estás comigo.',
    'tristeza': 'Acolhe minha tristeza e traz consolo ao meu coração.',
    'cansaco': 'Renova minhas forças e permite que eu descanse sem culpa.',
    'forca': 'Fortalece-me para enfrentar os desafios de hoje sem perder a fé.',
    'fe':
        'Fortalece minha fé mesmo quando não consigo enxergar o caminho inteiro.',
    'amor_sofrimento':
        'Cuida das feridas do meu coração e ensina-me a amar com sabedoria.',
    'dinheiro': 'Dá-me serenidade e sabedoria para lidar com minhas finanças.',
    'familia':
        'Abençoa minha família, aproxima-nos e ajuda-nos a cuidar uns dos outros.',
    'trabalho': 'Guia meu trabalho e abre caminhos justos para minha vida.',
    'relacionamento':
        'Ensina-nos a ouvir, respeitar e construir um relacionamento saudável.',
    'perdao':
        'Ajuda-me a perdoar sem negar a dor e a buscar reconciliação com sabedoria.',
    'recomeco': 'Dá-me coragem para recomeçar um passo de cada vez.',
    'esperanca': 'Acende de novo a esperança onde hoje só vejo dificuldade.',
    'decisao':
        'Dá-me discernimento para tomar a decisão que preciso enfrentar.',
    'proposito': 'Orienta meus sonhos e mostra-me como servir com meus dons.',
    'aproximar_de_deus':
        'Aproxima meu coração de ti e desperta em mim vontade de ouvir tua Palavra.',
    'solidao':
        'Na solidão, lembra-me da tua presença e aproxima pessoas de confiança.',
    'fase_dificil':
        'Sustenta-me nesta fase difícil e ajuda-me a seguir um dia de cada vez.',
    'luto': 'Acolhe minha saudade e consola-me no tempo do luto.',
    'gratidao':
        'Abre meus olhos para reconhecer as bênçãos deste dia e agradecer.',
  };

  static const _themeLabels = <String, String>{
    'paz': 'paz',
    'ansiedade': 'alívio para a ansiedade',
    'medo': 'coragem diante do medo',
    'tristeza': 'consolo na tristeza',
    'cansaco': 'descanso',
    'forca': 'força',
    'fe': 'fé',
    'amor_sofrimento': 'cura para a dor no amor',
    'dinheiro': 'sabedoria financeira',
    'familia': 'cuidado com a família',
    'trabalho': 'direção no trabalho',
    'relacionamento': 'cuidado no relacionamento',
    'perdao': 'perdão',
    'recomeco': 'um recomeço',
    'esperanca': 'esperança',
    'decisao': 'sabedoria para decidir',
    'proposito': 'propósito',
    'aproximar_de_deus': 'proximidade contigo',
    'solidao': 'companhia na solidão',
    'fase_dificil': 'sustento nesta fase difícil',
    'luto': 'consolo no luto',
    'gratidao': 'gratidão',
  };

  static const _themeReflections = <String, String>{
    'paz':
        'Mesmo que a situação ao meu redor ainda não tenha mudado, ajuda-me a encontrar um momento de calma. Ensina-me a responder com serenidade e a cuidar do que está ao meu alcance.',
    'ansiedade':
        'Quando meus pensamentos correrem para o futuro, traz-me de volta ao presente. Ajuda-me a distinguir o que posso fazer agora daquilo que preciso entregar em tuas mãos.',
    'medo':
        'Não quero fingir que não sinto medo. Mostra-me um passo possível e aproxima pessoas que possam caminhar comigo enquanto enfrento o que me assusta.',
    'tristeza':
        'Permite que eu reconheça minha dor sem me sentir culpado por ela. Dá-me companhia, tempo e pequenos sinais de cuidado para atravessar este dia.',
    'cansaco':
        'Mostra-me onde preciso fazer uma pausa e o que posso deixar para depois. Renova meu corpo e minha mente e ensina-me que descansar também é cuidado.',
    'forca':
        'Há desafios que parecem maiores que minhas forças. Ajuda-me a perseverar sem carregar tudo sozinho e a pedir apoio quando eu precisar.',
    'fe':
        'Mesmo com dúvidas, quero continuar buscando tua presença. Abre meus olhos para tua Palavra e dá-me confiança para caminhar um passo de cada vez.',
    'amor_sofrimento':
        'Não deixes que esta ferida defina meu valor. Ajuda-me a reconhecer o que preciso curar, a estabelecer limites bons e a receber amor sem medo.',
    'dinheiro':
        'Tu conheces as contas e as preocupações que tenho. Dá-me clareza para organizar o que posso, coragem para pedir ajuda e oportunidades justas para seguir.',
    'familia':
        'Tu conheces cada pessoa da minha casa e as conversas que ainda precisamos ter. Ensina-nos a ouvir, respeitar e procurar reconciliação com cuidado.',
    'trabalho':
        'Acompanha-me nas tarefas, nas decisões e nas dificuldades do trabalho. Ajuda-me a agir com honestidade e a reconhecer caminhos quando uma porta se fechar.',
    'relacionamento':
        'Ensina-me a comunicar o que sinto com respeito e a escutar sem desprezar a dor do outro. Que haja verdade, cuidado e limites saudáveis entre nós.',
    'perdao':
        'Não quero apressar a cura nem negar o que aconteceu. Guia-me para soltar o peso da amargura, sem abandonar a sabedoria e os limites necessários.',
    'recomeco':
        'Ajuda-me a não medir meu futuro apenas pelos erros de ontem. Mostra-me o primeiro passo possível e dá-me paciência para construir algo novo.',
    'esperanca':
        'Quando o futuro parecer fechado, lembra-me de que este momento não é toda a minha história. Ajuda-me a enxergar uma possibilidade real de seguir e a encontrar apoio para não desistir.',
    'decisao':
        'Acalma a pressa e ajuda-me a avaliar as consequências com clareza. Aproxima conselhos confiáveis e dá-me coragem para escolher com responsabilidade.',
    'proposito':
        'Ajuda-me a perceber meus dons e a usá-los para servir. Que meus planos não sejam guiados só pela ansiedade, mas por amor, verdade e perseverança.',
    'aproximar_de_deus':
        'Ensina-me a reservar um tempo para tua Palavra e a falar contigo com sinceridade. Mesmo quando me sinto distante, ajuda-me a recomeçar esta conversa.',
    'solidao':
        'Tu vês os momentos em que me sinto invisível. Aproxima pessoas com quem eu possa conversar e ajuda-me a dar um pequeno passo em direção à companhia.',
    'fase_dificil':
        'Não preciso resolver toda esta fase hoje. Dá-me forças para o próximo passo, descanso quando necessário e pessoas que possam oferecer ajuda concreta.',
    'luto':
        'A saudade tem seu próprio tempo. Acolhe minhas lembranças e minhas lágrimas; aproxima pessoas que saibam ouvir sem exigir que eu esteja bem depressa.',
    'gratidao':
        'Ajuda-me a nomear as coisas boas sem ignorar as difíceis. Quero agradecer com sinceridade e transformar essa gratidão em cuidado com outras pessoas.',
  };
}
