import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/situation.dart';
import '../sos/breathing_screen.dart';
import '../state/app_state.dart';
import 'prayer_screen.dart';

/// Aba "Orar": orações da manhã e da noite, orações por necessidade e
/// respiração guiada.
class OrarScreen extends StatelessWidget {
  const OrarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;

    void open(bool morning, List<String> themes) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PrayerScreen(morning: morning, themeIds: themes),
      ));
    }

    final hour = DateTime.now().hour;
    final morningNow = hour >= 3 && hour < 15;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _BigTile(
                icon: Icons.wb_twilight_rounded,
                title: 'Manhã',
                subtitle: 'Todo dia às 5h',
                colors: const [Color(0xFFB8566B), Color(0xFFF6A04D)],
                onTap: () => open(true, app.prayerThemeIds),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BigTile(
                icon: Icons.nightlight_round,
                title: 'Noite',
                subtitle: 'Todo dia às 18h',
                colors: const [Color(0xFF0B1433), Color(0xFF3B2A6B)],
                onTap: () => open(false, app.prayerThemeIds),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Me lembrar às 5h e às 18h'),
          subtitle: const Text('Uma notificação com a oração do momento'),
          value: app.settings.prayerRemindersEnabled,
          onChanged: (v) async {
            final ok = await app.setPrayerRemindersEnabled(v);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Permita as notificações do app nas configurações do celular.'),
              ));
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.spa_rounded, color: gold),
          title: const Text('Respirar com Deus (SOS ansiedade)'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BreathingScreen())),
        ),
        const SizedBox(height: 12),
        const Text('Orar por uma necessidade',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final s in kSituations)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(s.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(s.label),
            trailing: const Icon(Icons.play_circle_outline_rounded),
            onTap: () => open(morningNow, s.themeIds),
          ),
      ],
    );
  }
}

class _BigTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _BigTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFFFFE6A3), size: 34),
                const Spacer(),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
