import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/ativacao/activation_service.dart';
import '../state/app_state.dart';

/// Tela de liberação: a pessoa digita o e-mail usado na compra da Cakto.
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  static const checkoutUrl = String.fromEnvironment('CHECKOUT_URL');

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _message = 'Digite o e-mail que você usou na compra.');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await context.read<AppState>().activate(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = switch (result) {
        ActivationResult.ok => null,
        ActivationResult.notFound =>
          'Não achamos compra com esse e-mail. Confira se digitou igual ao da '
              'compra. Se acabou de pagar com Pix, espere 1 minuto e tente de novo.',
        ActivationResult.cancelled =>
          'Essa compra foi cancelada ou reembolsada.',
        ActivationResult.deviceLimit =>
          'Essa compra já foi usada em 3 celulares. Fale com o suporte.',
        ActivationResult.offline =>
          'Sem internet. Conecte-se só desta vez para liberar o app.',
        ActivationResult.error =>
          'Algo deu errado. Tente de novo em instantes.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/brand_icon.png',
                        width: 104, height: 104),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Bíblia e Oração',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                const Text(
                  'Para liberar o app, digite o e-mail que você usou na compra. '
                  'Você só precisa fazer isso uma vez.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _activate(),
                  decoration: const InputDecoration(
                    labelText: 'E-mail da compra',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _activate,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Liberar meu app'),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                if (ActivationScreen.checkoutUrl.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(
                          text: ActivationScreen.checkoutUrl));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Link de compra copiado. Cole no navegador.'),
                      ));
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Ainda não comprou? Copiar link'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
