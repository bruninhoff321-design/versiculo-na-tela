import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _widgetChannel =
    MethodChannel('com.versiculonatela.app/widget_scheduler');

Future<void> addWidgetToHome(BuildContext context) async {
  bool requested = false;
  try {
    requested = await _widgetChannel.invokeMethod<bool>('pinWidget') ?? false;
  } on MissingPluginException {
    // Orientação manual para plataformas sem canal nativo.
  } on PlatformException {
    // O launcher pode recusar o pedido automático.
  }

  if (!context.mounted) return;
  if (requested) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Confirme em “Adicionar” na janela do celular.'),
    ));
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Colocar na tela inicial'),
      content: const Text(
        '1. Vá para a tela inicial do celular.\n\n'
        '2. Toque e segure um espaço vazio.\n\n'
        '3. Toque em “Widgets”, procure “Versículo na Tela” e toque em “Adicionar”.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}

/// O seletor de widgets no bloqueio depende do fabricante e do launcher.
Future<void> showLockScreenWidgetGuide(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Widget na tela de bloqueio'),
      content: const SingleChildScrollView(
        child: Text(
          'Alguns Androids permitem adicionar widgets ao bloqueio. Abra a '
          'personalização da tela de bloqueio do seu celular e procure '
          '“Versículo na Tela (compacto)” na lista de widgets.\n\n'
          'Se não aparecer, o seletor padrão desse aparelho não oferece essa '
          'posição para nosso widget. Você ainda pode ativar o versículo como notificação '
          'silenciosa nos Ajustes do app.\n\n'
          'Em aparelhos Samsung com Good Lock compatível, o LockStar também '
          'pode oferecer widgets de outros apps. A posição final é sempre '
          'controlada pelo celular. A opção de imagem do app substitui sua '
          'foto; deixe-a desligada para preservar seu papel de parede.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}
