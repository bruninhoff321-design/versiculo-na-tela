import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/audio/speech_service.dart';
import '../../domain/models/situation.dart';
import '../biblia/chapter_reader_screen.dart';
import '../oracao/prayer_screen.dart';
import '../shared/share_image.dart';
import '../shared/verse_actions.dart';
import '../sos/breathing_screen.dart';
import '../state/app_state.dart';
import '../temas/theme_verses_screen.dart';

/// "Hoje": ofensiva, oração do momento, versículo do dia e
/// "Como você está?".
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _moodIds = [
    'ansiedade', 'tristeza', 'medo', 'cansaco', 'paz', 'dinheiro', 'luto',
    'solidao', 'familia', 'forca', 'esperanca', 'gratidao',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;
    final hour = DateTime.now().hour;
    final morning = hour >= 3 && hour < 15;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';
    final verse = app.verseOfTheDay;
    final moods = [
      for (final id in _moodIds)
        for (final s in kSituations)
          if (s.themeIds.first == id) s,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(greeting,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            _StreakChip(streak: app.streak, best: app.bestStreak),
          ],
        ),
        const SizedBox(height: 16),
        // Oração do momento (5h manhã / 18h noite).
        _GradientCard(
          colors: morning
              ? const [Color(0xFF2A2360), Color(0xFFB8566B), Color(0xFFF6A04D)]
              : const [Color(0xFF0B1433), Color(0xFF1E2A5A), Color(0xFF3B2A6B)],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                PrayerScreen(morning: morning, themeIds: app.prayerThemeIds),
          )),
          child: Row(
            children: [
              Icon(morning ? Icons.wb_twilight_rounded : Icons.nightlight_round,
                  color: const Color(0xFFFFE6A3), size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(morning ? 'AMANHECER COM DEUS' : 'ANOITECER COM DEUS',
                        style: const TextStyle(
                            color: Color(0xFFFFE6A3),
                            fontSize: 12,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                        morning
                            ? 'Ouça a oração da manhã'
                            : 'Ouça a oração da noite',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 44),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (verse != null)
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showVerseActions(context, verse),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VERSÍCULO DO DIA',
                        style: TextStyle(
                            color: gold,
                            fontSize: 12,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text('“${verse.text}”',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                fontSize:
                                    22 * app.settings.readingTextSize.scale)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(verse.reference,
                              style: TextStyle(
                                  color: gold, fontWeight: FontWeight.w800)),
                        ),
                        ValueListenableBuilder<String?>(
                          valueListenable: SpeechService.instance.speaking,
                          builder: (_, speaking, __) => IconButton(
                            tooltip: 'Ouvir',
                            icon: Icon(speaking == verse.id
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded),
                            onPressed: () => SpeechService.instance.toggle(
                                verse.id, '${verse.text}. ${verse.reference}.'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Compartilhar no status',
                          icon: const Icon(Icons.ios_share_rounded),
                          onPressed: () => shareVerseAsImage(
                              context: context,
                              text: verse.text,
                              reference: verse.reference),
                        ),
                        IconButton(
                          tooltip: 'Ler o capítulo',
                          icon: const Icon(Icons.menu_book_rounded),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChapterReaderScreen(
                                abbr: verse.bookAbbr,
                                chapter: verse.chapter,
                                highlightVerse: verse.verseNumber,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        const Text('Como você está hoje?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in moods)
              ActionChip(
                avatar: Text(s.emoji),
                label: Text(_shortLabel(s)),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ThemeVersesScreen(situation: s),
                )),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _GradientCard(
          colors: const [Color(0xFF13544E), Color(0xFF1F6F66), Color(0xFF6FB3A0)],
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BreathingScreen())),
          child: const Row(
            children: [
              Icon(Icons.spa_rounded, color: Colors.white, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS — Ansiedade agora?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Respire com Deus por 1 minuto',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  static String _shortLabel(Situation s) {
    const labels = {
      'ansiedade': 'Ansioso(a)',
      'tristeza': 'Triste',
      'medo': 'Com medo',
      'cansaco': 'Cansado(a)',
      'paz': 'Preciso de paz',
      'dinheiro': 'Sem dinheiro',
      'luto': 'De luto',
      'solidao': 'Sozinho(a)',
      'familia': 'Família',
      'forca': 'Sem forças',
      'esperanca': 'Sem esperança',
      'gratidao': 'Grato(a)',
    };
    return labels[s.themeIds.first] ?? s.label;
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;
  final int best;
  const _StreakChip({required this.streak, required this.best});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Dias seguidos com Deus · recorde: $best',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6A04D).withOpacity(.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('🔥 $streak dia${streak == 1 ? '' : 's'}',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFFF6B26B))),
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final VoidCallback onTap;
  const _GradientCard(
      {required this.colors, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
