/// Um cartão selecionável da tela "O que você precisa ouvir?" (seção 10).
/// `themeIds` referencia os ids definidos em assets/taxonomia_temas.json.
class Situation {
  final String emoji;
  final String label;
  final List<String> themeIds;

  const Situation({
    required this.emoji,
    required this.label,
    required this.themeIds,
  });
}

/// Lista fixa dos cartões de situação, na ordem do briefing (seção 10).
/// Permite selecionar mais de um cartão ao mesmo tempo (multi-seleção é
/// tratada na tela, não aqui).
const List<Situation> kSituations = [
  Situation(emoji: '😔', label: 'Estou triste', themeIds: ['tristeza']),
  Situation(emoji: '😰', label: 'Estou preocupado(a)', themeIds: ['ansiedade']),
  Situation(emoji: '😨', label: 'Estou com medo', themeIds: ['medo']),
  Situation(emoji: '😴', label: 'Estou cansado(a)', themeIds: ['cansaco']),
  Situation(emoji: '🕊️', label: 'Preciso de paz', themeIds: ['paz']),
  Situation(emoji: '🙏', label: 'Preciso fortalecer minha fé', themeIds: ['fe']),
  Situation(emoji: '💪', label: 'Preciso de força', themeIds: ['forca']),
  Situation(emoji: '❤️', label: 'Estou sofrendo por amor', themeIds: ['amor_sofrimento']),
  Situation(emoji: '💰', label: 'Estou preocupado com dinheiro', themeIds: ['dinheiro']),
  Situation(emoji: '🏠', label: 'Minha família', themeIds: ['familia']),
  Situation(emoji: '💼', label: 'Meu trabalho', themeIds: ['trabalho']),
  Situation(emoji: '❤️', label: 'Meu relacionamento', themeIds: ['relacionamento']),
  Situation(emoji: '🤲', label: 'Preciso perdoar', themeIds: ['perdao']),
  Situation(emoji: '✨', label: 'Quero recomeçar', themeIds: ['recomeco']),
  Situation(emoji: '🌅', label: 'Preciso de esperança', themeIds: ['esperanca']),
  Situation(emoji: '🧭', label: 'Preciso tomar uma decisão', themeIds: ['decisao']),
  Situation(emoji: '🎯', label: 'Tenho sonhos e objetivos', themeIds: ['proposito']),
  Situation(emoji: '🙏', label: 'Quero me aproximar de Deus', themeIds: ['aproximar_de_deus']),
  Situation(emoji: '🫂', label: 'Estou me sentindo sozinho(a)', themeIds: ['solidao']),
  Situation(emoji: '🌧️', label: 'Estou passando por uma fase difícil', themeIds: ['fase_dificil']),
  Situation(emoji: '🕯️', label: 'Estou passando por uma perda', themeIds: ['luto']),
  Situation(emoji: '❤️', label: 'Quero agradecer', themeIds: ['gratidao']),
];
