/// Prepara uma oração local quando não há um serviço de geração conectado.
/// A mesma data, período e necessidade produzem o mesmo texto; no dia seguinte
/// a escolha das frases muda. Não depende de rede nem envia o relato da pessoa.
class PrayerComposer {
  const PrayerComposer();

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
    final themes = themeIds.toSet().toList()..sort();
    final needs = themes
        .map((id) => _themePetitions[id])
        .whereType<String>()
        .take(2)
        .toList();

    final parts = <String>[
      opening[variation % opening.length],
      petition[(variation ~/ 5) % petition.length],
      if (needs.isEmpty)
        _generalPetitions[(variation ~/ 25) % _generalPetitions.length]
      else
        ...needs,
      _reflections[(variation ~/ 25) % _reflections.length],
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

  static const _generalPetitions = [
    'Tu conheces o que trago no coração; dá-me esperança para seguir.',
    'Mesmo quando não encontro palavras, escuta o que meu coração precisa.',
    'Sustenta-me com tua presença e mostra-me o próximo passo.',
    'Ajuda-me a reconhecer tua companhia nos momentos simples deste dia.',
    'Que eu encontre em ti consolo, direção e força para continuar.',
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
}
