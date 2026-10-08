import 'package:flutter/material.dart';

/// Textos originais para a pessoa acompanhar a oração. O áudio será ligado
/// a esta tela quando a voz autorizada estiver disponível no projeto.
class PrayerScreen extends StatelessWidget {
  final bool morning;

  const PrayerScreen({super.key, required this.morning});

  @override
  Widget build(BuildContext context) {
    final title = morning ? 'Oração da manhã' : 'Oração da noite';
    final prayer = morning
        ? 'Senhor Deus, obrigado por este novo dia. Guia meus passos, dá-me '
            'sabedoria nas escolhas e um coração atento às pessoas ao meu '
            'redor. Quando eu me sentir fraco, lembra-me de que não caminho '
            'sozinho. Que a tua Palavra ilumine o meu caminho e que eu leve '
            'paz aonde for. Em nome de Jesus, amém.'
        : 'Senhor Deus, obrigado por me acompanhar neste dia. Entrego a ti '
            'minhas alegrias, preocupações e tudo o que não consegui resolver. '
            'Perdoa minhas falhas, renova minhas forças e cuida das pessoas '
            'que amo. Dá-me descanso e esperança para recomeçar amanhã. '
            'Em nome de Jesus, amém.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(morning ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                color: Theme.of(context).colorScheme.primary, size: 44),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text(prayer,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.7)),
          ],
        ),
      ),
    );
  }
}
