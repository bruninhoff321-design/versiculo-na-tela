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
