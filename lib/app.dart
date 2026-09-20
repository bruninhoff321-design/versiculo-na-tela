import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/shared/app_shell.dart';
import 'presentation/state/app_state.dart';

class VersiculoNaTelaApp extends StatelessWidget {
  const VersiculoNaTelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Versículo na Tela',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return app.settings.onboarded ? const AppShell() : const OnboardingScreen();
  }
}
