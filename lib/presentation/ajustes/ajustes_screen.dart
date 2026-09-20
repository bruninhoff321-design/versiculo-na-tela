import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/app_settings.dart';
import '../state/app_state.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settings = app.settings;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle('Quando o versículo deve mudar?'),
        const _Hint(
          'Preferência de atualização — o sistema operacional pode ajustar '
          'o momento exato por bateria/desempenho.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UpdateFrequency.values.map((f) {
            return ChoiceChip(
              label: Text(f.label),
              selected: settings.frequency == f,
              onSelected: (_) =>
                  app.updateSettings((s) => s.copyWith(frequency: f)),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        _SectionTitle('Não repetir versículos'),
        const _Hint(
          'Evite que um versículo apareça novamente até que você tenha '
          'visto outros.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NoRepeatOption.values.map((o) {
            return ChoiceChip(
              label: Text(o.label),
              selected: settings.noRepeat == o,
              onSelected: (_) =>
                  app.updateSettings((s) => s.copyWith(noRepeat: o)),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        _SectionTitle('Tema do widget'),
        _Hint(
          'Temas Premium ficam disponíveis após o desbloqueio vitalício.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: WidgetVisualTheme.values.map((t) {
            final locked = t.isPremium && !settings.premium;
            final (bg, fg) = AppTheme.widgetThemeColors(t.name);
            return GestureDetector(
              onTap: () {
                if (locked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Tema Premium — desbloqueie a versão vitalícia')),
                  );
                  return;
                }
                app.updateSettings((s) => s.copyWith(widgetTheme: t));
              },
              child: Opacity(
                opacity: locked ? 0.5 : 1,
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: settings.widgetTheme == t
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: locked
                            ? Icon(Icons.lock, size: 16, color: fg)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(t.label, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        _SectionTitle('Tamanho do widget'),
        const SizedBox(height: 10),
        SegmentedButton<WidgetSize>(
          segments: const [
            ButtonSegment(value: WidgetSize.small, label: Text('Pequeno')),
            ButtonSegment(value: WidgetSize.medium, label: Text('Médio')),
            ButtonSegment(value: WidgetSize.large, label: Text('Grande')),
          ],
          selected: {settings.widgetSize},
          onSelectionChanged: (v) =>
              app.updateSettings((s) => s.copyWith(widgetSize: v.first)),
        ),
        const SizedBox(height: 28),

        _SectionTitle('Versículo diário'),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notificação diária'),
          value: settings.dailyNotificationEnabled,
          onChanged: (v) => app.updateSettings(
              (s) => s.copyWith(dailyNotificationEnabled: v)),
        ),
        if (settings.dailyNotificationEnabled)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Horário'),
            trailing: TextButton(
              child: Text(settings.dailyNotificationTime),
              onPressed: () async {
                final parts = settings.dailyNotificationTime.split(':');
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  ),
                );
                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:'
                      '${picked.minute.toString().padLeft(2, '0')}';
                  await app.updateSettings(
                      (s) => s.copyWith(dailyNotificationTime: formatted));
                }
              },
            ),
          ),
        const SizedBox(height: 28),

        _SectionTitle('Versículo na Tela Premium'),
        const SizedBox(height: 6),
        Text(
          settings.premium
              ? 'Compra vitalícia ativa neste dispositivo.'
              : 'Pague uma vez. Use para sempre. Sem assinatura, sem '
                  'renovação automática.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (!settings.premium)
              FilledButton(
                onPressed: app.purchases.buyPremium,
                child: const Text('Comprar Premium'),
              ),
            OutlinedButton(
              onPressed: app.purchases.restore,
              child: const Text('Restaurar compra'),
            ),
          ],
        ),
        ValueListenableBuilder<String?>(
          valueListenable: app.purchases.lastError,
          builder: (context, error, _) {
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            );
          },
        ),
        const SizedBox(height: 28),

        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Sobre / licença do texto bíblico'),
          children: const [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Todas as Escrituras em português citadas são da Bíblia '
                'Livre (BLIVRE), Copyright © Diego Santos, Mario Sérgio e '
                'Marco Teles — sites.google.com/site/biblialivre. Licença '
                'Creative Commons Atribuição 3.0 Brasil (CC BY 3.0 BR). '
                'Reprodução permitida desde que devidamente mencionados '
                'fonte e autores.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor));
  }
}
