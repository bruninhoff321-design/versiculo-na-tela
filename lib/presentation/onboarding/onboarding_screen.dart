import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/app_settings.dart';
import '../shared/app_shell.dart';
import '../state/app_state.dart';

/// Onboarding de 5 telas — seção 21 do briefing, texto praticamente
/// verbatim do documento original.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 5;

  Future<void> _finish() async {
    final app = context.read<AppState>();
    await app.markOnboarded();
    if (!mounted) return;
    // A Home já mostra o cartão "O que você precisa ouvir?" em destaque
    // (seção 2), então basta levar para a casca principal — sem precisar
    // empilhar uma segunda navegação sobre o mesmo context.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

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
              Expanded(child: Center(child: _buildStep(app))),
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
                    child: Text(_step == _totalSteps - 1 ? 'Começar' : 'Continuar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppState app) {
    switch (_step) {
      case 0:
        return const _OnboardingText(
          title: 'Que bom ter você aqui.',
          body: 'Vamos preparar o Versículo na Tela em menos de um minuto.',
        );
      case 1:
        return const _OnboardingText(
          title: 'Leve uma palavra da Bíblia com você todos os dias.',
          body: 'Um versículo sempre visível, sem precisar abrir o app.',
        );
      case 2:
        return const _OnboardingText(
          title: 'Adicione o widget à sua tela inicial.',
          body: 'Depois de instalar, segure a tela inicial do celular e '
              'escolha "Versículo na Tela" entre os widgets disponíveis.',
        );
      case 3:
        return _FrequencyStep(app: app);
      default:
        return const _OnboardingText(
          title: 'Quer receber uma palavra quando precisar?',
          body: 'A qualquer momento, toque em "O que você precisa ouvir?" '
              'e conte o que você está vivendo.',
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

class _FrequencyStep extends StatelessWidget {
  final AppState app;
  const _FrequencyStep({required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Quando o versículo deve mudar?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: UpdateFrequency.values.map((f) {
            return ChoiceChip(
              label: Text(f.label),
              selected: app.settings.frequency == f,
              onSelected: (_) =>
                  app.updateSettings((s) => s.copyWith(frequency: f)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
