import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/verse.dart';
import '../state/app_state.dart';

/// SOS de ansiedade: respiração guiada (inspira 4s, segura 4s, solta 6s)
/// com versículos de paz trocando devagar.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _inhale = 4, _hold = 4, _exhale = 6;
  static const _cycle = _inhale + _hold + _exhale;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _cycle),
  )..repeat();

  List<Verse> _verses = const [];
  int _verseIndex = 0;
  int _cycles = 0;
  Timer? _verseTimer;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _verses = [
      ...app.versesForTheme('ansiedade'),
      ...app.versesForTheme('paz'),
    ];
    _controller.addListener(_onTick);
    _verseTimer = Timer.periodic(const Duration(seconds: _cycle * 2), (_) {
      if (!mounted || _verses.isEmpty) return;
      setState(() => _verseIndex = (_verseIndex + 1) % _verses.length);
    });
  }

  double _last = 0;
  void _onTick() {
    if (_controller.value < _last) setState(() => _cycles++);
    _last = _controller.value;
  }

  @override
  void dispose() {
    _verseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verse = _verses.isEmpty ? null : _verses[_verseIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF0E2B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Respire com Deus'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value * _cycle;
                  String label;
                  double scale;
                  if (t < _inhale) {
                    label = 'Inspire…';
                    scale = .55 + .45 * (t / _inhale);
                  } else if (t < _inhale + _hold) {
                    label = 'Segure…';
                    scale = 1;
                  } else {
                    label = 'Solte devagar…';
                    scale = 1 - .45 * ((t - _inhale - _hold) / _exhale);
                  }
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: Center(
                            child: Container(
                              width: 260 * scale,
                              height: 260 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(colors: [
                                  Color(0xFFBFF0DF),
                                  Color(0xFF6FB3A0),
                                  Color(0xFF1F6F66),
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6FB3A0)
                                        .withOpacity(.45),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                            _cycles == 0
                                ? 'Siga o círculo'
                                : '$_cycles respiraç${_cycles == 1 ? 'ão' : 'ões'}',
                            style: const TextStyle(color: Colors.white60)),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (verse != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: Padding(
                  key: ValueKey(verse.id),
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: Column(
                    children: [
                      Text('“${verse.text}”',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFF4FFFA),
                              fontSize: 20,
                              height: 1.45)),
                      const SizedBox(height: 8),
                      Text(verse.reference,
                          style: const TextStyle(
                              color: Color(0xFFBFF0DF),
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Se a angústia estiver muito forte, você não precisa passar '
                'por isso sozinho(a): ligue 188 (CVV), de graça, 24 horas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
