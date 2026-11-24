import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/widget_setup.dart';
import '../state/app_state.dart';

/// Primeira abertura: boas-vindas, escolha da tradição (muda os livros da
/// Bíblia) e lembretes de oração às 5h e às 18h.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const _steps = 3;

  Future<void> _finish() async {
    await context.read<AppState>().markOnboarded();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;
    final canContinue = _step != 1 || app.tradition != null;

    Widget body;
    switch (_step) {
      case 0:
        body = const _OnboardingText(
          title: 'Bem-vindo ao Bíblia e Oração',
          body:
              'A Bíblia completa, orações em áudio de manhã e à noite, e uma '
              'palavra de Deus para cada momento do seu dia.',
        );
      case 1:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _OnboardingText(
              title: 'Qual é a sua tradição?',
              body:
                  'Isso muda os livros da Bíblia e as orações. Dá para trocar '
                  'depois em "Mais".',
            ),
            const SizedBox(height: 24),
            _ChoiceButton(
              label: 'Evangélica',
              detail: 'Bíblia com 66 livros',
              selected: app.tradition == 'evangelico',
              onTap: () => app.setTradition('evangelico'),
            ),
            const SizedBox(height: 12),
            _ChoiceButton(
              label: 'Católica',
              detail: 'Os 7 livros católicos chegam numa próxima atualização',
              selected: app.tradition == 'catolico',
              onTap: () => app.setTradition('catolico'),
            ),
          ],
        );
      default:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _OnboardingText(
              title: 'Comece e termine o dia com Deus',
              body:
                  'Receba a oração da manhã às 5h e a da noite às 18h, e '
                  'deixe um versículo na tela do celular.',
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Lembrete de oração às 5h e às 18h'),
              value: app.settings.prayerRemindersEnabled,
              onChanged: (v) => app.setPrayerRemindersEnabled(v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => addWidgetToHome(context),
                icon: const Icon(Icons.add_to_home_screen_rounded),
                label: const Text('Pôr versículo na tela inicial'),
              ),
            ),
          ],
        );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _steps,
                    (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _step
                                ? gold
                                : Theme.of(context).dividerColor,
                          ),
                        )),
              ),
              Expanded(
                child: Center(child: SingleChildScrollView(child: body)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Voltar'),
                    ),
                  FilledButton(
                    onPressed: !canContinue
                        ? null
                        : _step == _steps - 1
                            ? _finish
                            : () => setState(() => _step++),
                    child: Text(_step == _steps - 1 ? 'Começar' : 'Continuar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceButton({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? gold : Theme.of(context).dividerColor,
              width: selected ? 2 : 1),
          color: selected ? gold.withOpacity(.12) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(detail),
                ],
              ),
            ),
            Icon(selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
                color: selected ? gold : null),
          ],
        ),
      ),
    );
  }
}

class _OnboardingText extends StatelessWidget {
  final String title;
  final String body;
  const _OnboardingText({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child:
                Image.asset('assets/brand_icon.png', width: 112, height: 112),
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
