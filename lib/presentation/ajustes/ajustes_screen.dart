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
    final gold = Theme.of(context).colorScheme.primary;

    Widget section({
      required String title,
      required String subtitle,
      required IconData icon,
      required List<Widget> children,
    }) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(icon, color: gold),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
          childrenPadding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          children: children,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text('Do seu jeito',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Toque em uma seção para ajustar apenas o que precisar.'),
        const SizedBox(height: 20),
        section(
          title: 'Troca de versículos',
          subtitle: settings.frequency.label,
          icon: Icons.autorenew_rounded,
          children: [
            const _SettingLabel('Quando mudar?'),
            const SizedBox(height: 8),
            for (final frequency in UpdateFrequency.values)
              RadioListTile<UpdateFrequency>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(frequency.label),
                value: frequency,
                groupValue: settings.frequency,
                onChanged: (value) {
                  if (value != null) {
                    app.updateSettings((s) => s.copyWith(frequency: value));
                  }
                },
              ),
            const SizedBox(height: 8),
            const _SettingLabel('Evitar repetições'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NoRepeatOption.values
                  .map((option) => ChoiceChip(
                        label: Text(option.label),
                        selected: settings.noRepeat == option,
                        onSelected: (_) => app.updateSettings(
                            (s) => s.copyWith(noRepeat: option)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text(
                'O Android pode atrasar a atualização para economizar bateria.',
                style: TextStyle(fontSize: 13)),
          ],
        ),
        section(
          title: 'Tela de bloqueio',
          subtitle: app.lockWallpaperEnabled ? 'Ativada' : 'Desativada',
          icon: Icons.lock_outline_rounded,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar versículo na tela de bloqueio'),
              subtitle: const Text(
                  'O app atualiza o papel de parede da tela de bloqueio.'),
              value: app.lockWallpaperEnabled,
              onChanged: (enabled) async {
                try {
                  await app.setLockWallpaperEnabled(enabled);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Este celular não permitiu alterar a tela de bloqueio.'),
                    ));
                  }
                }
              },
            ),
          ],
        ),
        section(
          title: 'Aparência do widget',
          subtitle:
              '${settings.widgetTheme.label} · tamanho ${settings.widgetSize.name}',
          icon: Icons.palette_outlined,
          children: [
            const _SettingLabel('Estilo'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: WidgetVisualTheme.values.map((visual) {
                final (background, _) = AppTheme.widgetThemeColors(visual.name);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => app
                      .updateSettings((s) => s.copyWith(widgetTheme: visual)),
                  child: SizedBox(
                    width: 76,
                    child: Column(children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: settings.widgetTheme == visual
                                ? gold
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(visual.label, style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            const _SettingLabel('Tamanho'),
            const SizedBox(height: 10),
            SegmentedButton<WidgetSize>(
              segments: const [
                ButtonSegment(value: WidgetSize.small, label: Text('Pequeno')),
                ButtonSegment(value: WidgetSize.medium, label: Text('Médio')),
                ButtonSegment(value: WidgetSize.large, label: Text('Grande')),
              ],
              selected: {settings.widgetSize},
              onSelectionChanged: (values) => app
                  .updateSettings((s) => s.copyWith(widgetSize: values.first)),
            ),
          ],
        ),
        section(
          title: 'Lembrete diário',
          subtitle: settings.dailyNotificationEnabled
              ? 'Ativado às ${settings.dailyNotificationTime}'
              : 'Desativado',
          icon: Icons.notifications_outlined,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Receber uma notificação diária'),
              value: settings.dailyNotificationEnabled,
              onChanged: (enabled) => app.updateSettings(
                (s) => s.copyWith(dailyNotificationEnabled: enabled),
              ),
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
          ],
        ),
        section(
          title: 'Sobre o app',
          subtitle: 'Criador e licença do texto bíblico',
          icon: Icons.info_outline_rounded,
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Versículo na Tela · Criado por Bruno Brasil.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            SizedBox(height: 14),
            Text(
              'Texto bíblico: Bíblia Livre (BLIVRE), Copyright © Diego '
              'Santos, Mario Sérgio e Marco Teles — edição de fevereiro '
              'de 2018. https://sites.google.com/site/biblialivre/. '
              'Licença Creative Commons Atribuição 3.0 Brasil '
              '(CC BY 3.0 BR).',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingLabel extends StatelessWidget {
  final String text;
  const _SettingLabel(this.text);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}
