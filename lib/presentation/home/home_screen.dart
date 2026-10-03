import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../descubra/descubra_screen.dart';
import '../state/app_state.dart';

/// Uma leitura tranquila. As ações secundárias ficam na barra superior.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final verse = app.currentVerse;
    final gold = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('UMA PALAVRA PARA HOJE',
                textAlign: TextAlign.center,
                style: TextStyle(
                    letterSpacing: 2.2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD9A857))),
            const SizedBox(height: 22),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: gold.withOpacity(.65)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF243044),
                      Color(0xFF141B27),
                      Color(0xFF10151E)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -42,
                      top: -38,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            gold.withOpacity(.22),
                            gold.withOpacity(0),
                          ]),
                        ),
                      ),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories_rounded,
                                color: gold, size: 34),
                            const SizedBox(height: 30),
                            Text(
                              verse == null
                                  ? 'Preparando sua leitura…'
                                  : '“${verse.text}”',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(color: const Color(0xFFFFF9ED)),
                            ),
                            if (verse != null) ...[
                              const SizedBox(height: 30),
                              Container(width: 42, height: 1, color: gold),
                              const SizedBox(height: 20),
                              Text(verse.reference,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: gold,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DescubraScreen()),
                ),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Encontrar uma palavra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
