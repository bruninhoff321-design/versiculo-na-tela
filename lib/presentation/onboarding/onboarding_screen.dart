import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// Duas telas curtas; as opções avançadas ficam em Ajustes.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 2;

  Future<void> _finish() async {
    final app = context.read<AppState>();
    // O widget raiz troca o onboarding pela Home ao observar `onboarded`.
    // Empilhar outra rota aqui criava duas Homes e um botão Voltar confuso.
    await app.markOnboarded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalSteps, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _step
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Expanded(child: Center(child: _buildStep())),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Voltar'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (_step == _totalSteps - 1) {
                        _finish();
                      } else {
                        setState(() => _step++);
                      }
                    },
                    child: Text(
                        _step == _totalSteps - 1 ? 'Começar' : 'Continuar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return const _OnboardingText(
          title: 'Uma palavra de Deus para o seu dia.',
          body:
              'Abra o app, leia o versículo e toque para receber outra palavra quando quiser.',
        );
      default:
        return const _OnboardingText(
          title: 'Leve o versículo com você.',
          body: 'Em Ajustes, abra “Tela de bloqueio” para mostrar o '
              'versículo ali. Para colocar o widget na tela inicial, '
              'segure um espaço vazio nela e escolha “Versículo na Tela”.',
        );
    }
  }
}

class _OnboardingText extends StatelessWidget {
  final String title;
  final String body;
  const _OnboardingText({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset('assets/brand_icon.png', width: 112, height: 112),
        ),
        const SizedBox(height: 24),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(body,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor)),
      ],
    );
  }
}
