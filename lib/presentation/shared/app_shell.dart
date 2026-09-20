import 'package:flutter/material.dart';

import '../ajustes/ajustes_screen.dart';
import '../favoritos/favoritos_screen.dart';
import '../historico/historico_screen.dart';
import '../home/home_screen.dart';

/// Casca com navegação inferior — Início / Favoritos / Histórico / Ajustes
/// (seção 2 do briefing). "O que você precisa ouvir?" não é uma aba fixa:
/// é acessado pelo cartão de destaque na Home, como no briefing original.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['Versículo na Tela', 'Favoritos', 'Histórico', 'Ajustes'];
  static const _screens = [
    HomeScreen(),
    FavoritosScreen(),
    HistoricoScreen(),
    AjustesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
