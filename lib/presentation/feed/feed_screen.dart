import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/audio/speech_service.dart';
import '../../domain/models/verse.dart';
import '../oracao/prayer_screen.dart';
import '../shared/share_image.dart';
import '../shared/verse_actions.dart';
import '../state/app_state.dart';
import 'quiz_data.dart';

/// "Palavra": versículos em tela cheia, um atrás do outro, como Reels.
/// No meio aparecem pausas para orar e perguntas de quiz.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

sealed class _FeedItem {}

class _VerseItem extends _FeedItem {
  final Verse verse;
  final int palette;
  _VerseItem(this.verse, this.palette);
}

class _PauseItem extends _FeedItem {}

class _QuizItem extends _FeedItem {
  final QuizQuestion question;
  _QuizItem(this.question);
}

class _MindfulItem extends _FeedItem {
  final int seen;
  _MindfulItem(this.seen);
}

const _palettes = <List<Color>>[
  [Color(0xFF0B1433), Color(0xFF2A2360), Color(0xFFB8566B)],
  [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  [Color(0xFF1F1C2C), Color(0xFF4B3B6B), Color(0xFF928DAB)],
  [Color(0xFF2B1A12), Color(0xFF6B3E26), Color(0xFFD9A441)],
  [Color(0xFF0A2E2A), Color(0xFF13544E), Color(0xFF6FB3A0)],
  [Color(0xFF231942), Color(0xFF5E548E), Color(0xFFE0B1CB)],
];

class _FeedScreenState extends State<FeedScreen> {
  final _items = <_FeedItem>[];
  final _page = PageController();
  int _versesSeen = 0;
  int _quizIndex = 0;
  bool _autoNarrate = false;
  bool _countedToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _loadMore() {
    final app = context.read<AppState>();
    final batch = app.nextFeedBatch(12, seed: _items.length);
    setState(() {
      for (final v in batch) {
        _items.add(_VerseItem(v, _items.length % _palettes.length));
        final n = _items.length;
        if (n % 9 == 0) _items.add(_PauseItem());
        if (n % 13 == 0) {
          _items.add(_QuizItem(kQuiz[_quizIndex++ % kQuiz.length]));
        }
      }
    });
  }

  void _onPage(int index) {
    if (index >= _items.length - 4) _loadMore();
    final item = _items[index];
    if (item is _VerseItem) {
      _versesSeen++;
      if (_versesSeen % 40 == 0) {
        setState(() => _items.insert(index + 1, _MindfulItem(_versesSeen)));
      }
      if (!_countedToday && _versesSeen >= 5) {
        _countedToday = true;
        unawaited(context.read<AppState>().registerActivity());
      }
      if (_autoNarrate) {
        unawaited(SpeechService.instance.toggle(
            item.verse.id, '${item.verse.text}. ${item.verse.reference}.'));
      } else {
        unawaited(SpeechService.instance.stop());
      }
    } else {
      unawaited(SpeechService.instance.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _page,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPage,
          itemCount: _items.length,
          itemBuilder: (context, i) {
            final item = _items[i];
            return switch (item) {
              _VerseItem() => _VersePage(item: item),
              _PauseItem() => const _PausePage(),
              _QuizItem() => _QuizPage(question: item.question),
              _MindfulItem() => _MindfulPage(seen: item.seen),
            };
          },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: IconButton.filledTonal(
              tooltip: _autoNarrate
                  ? 'Desligar narração automática'
                  : 'Ligar narração automática',
              onPressed: () {
                setState(() => _autoNarrate = !_autoNarrate);
                if (!_autoNarrate) unawaited(SpeechService.instance.stop());
              },
              icon: Icon(_autoNarrate
                  ? Icons.record_voice_over_rounded
                  : Icons.voice_over_off_rounded),
            ),
          ),
        ),
      ],
    );
  }
}

class _VersePage extends StatelessWidget {
  final _VerseItem item;
  const _VersePage({required this.item});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final v = item.verse;
    final colors = _palettes[item.palette];
    final favorite = app.favoriteIds.contains(v.id);
    final long = v.text.length > 160;
    return GestureDetector(
      onDoubleTap: () {
        if (!favorite) app.toggleFavorite(v.id);
      },
      onLongPress: () => showVerseActions(context, v),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 84, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '“${v.text}”',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontStyle: FontStyle.italic,
                          fontSize: long ? 25 : 31,
                          height: 1.4,
                          color: const Color(0xFFFFF8EA),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        v.reference,
                        style: const TextStyle(
                          color: Color(0xFFF7D27A),
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 40,
                child: Column(
                  children: [
                    _SideButton(
                      icon: favorite ? Icons.favorite : Icons.favorite_border,
                      label: 'Amém',
                      color: favorite ? const Color(0xFFF4A3C4) : null,
                      onTap: () => app.toggleFavorite(v.id),
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: SpeechService.instance.speaking,
                      builder: (_, speaking, __) => _SideButton(
                        icon: speaking == v.id
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        label: 'Ouvir',
                        onTap: () => SpeechService.instance
                            .toggle(v.id, '${v.text}. ${v.reference}.'),
                      ),
                    ),
                    _SideButton(
                      icon: Icons.ios_share_rounded,
                      label: 'Status',
                      onTap: () => shareVerseAsImage(
                          context: context,
                          text: v.text,
                          reference: v.reference),
                    ),
                    _SideButton(
                      icon: Icons.more_horiz_rounded,
                      label: 'Mais',
                      onTap: () => showVerseActions(context, v),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _SideButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 32, color: color ?? Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PausePage extends StatelessWidget {
  const _PausePage();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final morning = hour >= 3 && hour < 15;
    return _CardPage(
      colors: const [Color(0xFF1B1530), Color(0xFF3C2A5E), Color(0xFF9A6A3A)],
      icon: Icons.self_improvement_rounded,
      title: 'Pausa para orar',
      text:
          'Respire fundo. Entregue a Deus o que está pesando agora.\nUm minuto com Ele muda o dia.',
      action: 'Ouvir a oração de hoje',
      onAction: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PrayerScreen(
          morning: morning,
          themeIds: context.read<AppState>().prayerThemeIds,
        ),
      )),
    );
  }
}

class _MindfulPage extends StatelessWidget {
  final int seen;
  const _MindfulPage({required this.seen});

  @override
  Widget build(BuildContext context) {
    return _CardPage(
      colors: const [Color(0xFF0D141E), Color(0xFF17212E), Color(0xFF2B3A55)],
      icon: Icons.favorite_rounded,
      title: 'Você já leu $seen versículos',
      text:
          'Que tal guardar um deles no coração? Feche os olhos, agradeça a Deus e volte quando quiser.',
      action: null,
      onAction: null,
    );
  }
}

class _CardPage extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final String title;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _CardPage({
    required this.colors,
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: const Color(0xFFF7D27A)),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Text(text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 18, height: 1.5)),
                if (action != null) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(action!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizPage extends StatefulWidget {
  final QuizQuestion question;
  const _QuizPage({required this.question});

  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF102A43), Color(0xFF243B53), Color(0xFF486581)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('QUIZ BÍBLICO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFFF7D27A),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Text(q.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3)),
                const SizedBox(height: 24),
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _picked == null
                            ? Colors.white.withOpacity(.12)
                            : i == q.answer
                                ? const Color(0xFF2E9E6A)
                                : i == _picked
                                    ? const Color(0xFFB5473A)
                                    : Colors.white.withOpacity(.08),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_picked == null) setState(() => _picked = i);
                      },
                      child: Text(q.options[i]),
                    ),
                  ),
                if (_picked != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _picked == q.answer ? 'Isso mesmo! 🙌' : 'Quase!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(q.explanation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16, height: 1.4)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
