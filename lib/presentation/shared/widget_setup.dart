import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _widgetChannel = MethodChannel('com.versiculonatela.app/widget_scheduler');

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
/// A Samsung controla quais widgets aparecem no espaço abaixo do relógio.
Future<void> showLockScreenWidgetGuide(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Versículo pequeno na tela de bloqueio'),
      content: const SingleChildScrollView(
        child: Text(
          'O espaço abaixo do relógio é controlado pela Samsung. '
          'Se “Versículo na Tela” não aparece na lista comum, tente pelo '
          'Good Lock da Samsung:\n\n'
          '1. Abra Good Lock e entre em LockStar.\n\n'
          '2. Edite a tela de bloqueio e toque em adicionar widget.\n\n'
          '3. Procure “Versículo na Tela (compacto)” e ajuste abaixo do relógio.\n\n'
          'Se o LockStar não estiver disponível no seu A33 ou não listar o '
          'widget, essa posição não pode ser ativada pelo app. A opção de '
          'papel de parede abaixo substitui a foto; deixe-a desligada para '
          'preservar sua imagem. Se já foi usada, escolha sua foto novamente '
          'em “Papéis de parede”.',
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
