import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

/// Resultado de uma tentativa de ativar o app com o e-mail da compra.
enum ActivationResult { ok, notFound, cancelled, deviceLimit, offline, error }

/// Libera o app para quem comprou na Cakto.
///
/// O endereço do servidor vem da compilação (`--dart-define=ACTIVATION_URL`,
/// lido da variável ACTIVATION_URL do repositório no GitHub). Enquanto ele
/// estiver vazio, o app fica liberado para todos — útil para testes.
class ActivationService {
  static const activationUrl = String.fromEnvironment('ACTIVATION_URL');
  static const _boxName = 'ativacao';

  Box? _box;

  bool get required => activationUrl.isNotEmpty;

  Future<void> init() async {
    // Sem servidor configurado o app é liberado: nem abre o armazenamento.
    if (!required) return;
    _box ??= await Hive.openBox(_boxName);
  }

  bool get isActivated => !required || (_box?.get('ativo') as bool? ?? false);

  String? get email => _box?.get('email') as String?;

  /// Identificador aleatório deste celular (não identifica a pessoa).
  String _deviceId() {
    final saved = _box?.get('aparelho') as String?;
    if (saved != null) return saved;
    final rnd = Random.secure();
    final id = List.generate(16, (_) => rnd.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _box?.put('aparelho', id);
    return id;
  }

  Future<ActivationResult> activate(String email) async {
    await init();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.postUrl(Uri.parse(activationUrl));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'email': email.trim().toLowerCase(),
        'aparelho': _deviceId(),
      }));
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['ok'] == true) {
        await _box?.putAll({'ativo': true, 'email': email.trim()});
        return ActivationResult.ok;
      }
      return switch (data['motivo']) {
        'nao_encontrado' => ActivationResult.notFound,
        'cancelado' => ActivationResult.cancelled,
        'limite' => ActivationResult.deviceLimit,
        _ => ActivationResult.error,
      };
    } on SocketException {
      return ActivationResult.offline;
    } on HttpException {
      return ActivationResult.offline;
    } catch (_) {
      return ActivationResult.error;
    } finally {
      client.close();
    }
  }
}
