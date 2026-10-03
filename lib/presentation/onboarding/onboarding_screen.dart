import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/widget_setup.dart';
import '../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  Future<void> _finish() async {
    await context.read<AppState>().markOnboarded();
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _step ? gold : Theme.of(context).dividerColor,
                  ),
                )),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _step == 0
                        ? const _OnboardingText(
                            title: 'Uma palavra de Deus para o seu dia.',
                            body: 'Leia o versículo e receba outra palavra sempre que quiser.',
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _OnboardingText(
                                title: 'Leve o versículo com você.',
                                body: 'Toque no botão para colocar o versículo na tela inicial. O celular pedirá sua confirmação.',
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton.icon(
                                  onPressed: () => addWidgetToHome(context),
                                  icon: const Icon(Icons.add_to_home_screen_rounded),
                                  label: const Text('Ativar na tela inicial'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Você também pode fazer isso depois em Ajustes.',
                                  textAlign: TextAlign.center),
                            ],
                          ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step = 0),
                      child: const Text('Voltar'),
                    ),
                  FilledButton(
                    onPressed: _step == 1 ? _finish : () => setState(() => _step = 1),
                    child: Text(_step == 1 ? 'Começar' : 'Continuar'),
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

class _OnboardingText extends StatelessWidget {
  final String title;
  final String body;
  const _OnboardingText({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/brand_icon.png', width: 112, height: 112),
          ),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor)),
        ],
      );
}
