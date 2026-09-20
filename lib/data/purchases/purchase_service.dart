import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Compra única vitalícia (seções 22 e 23 do briefing) — SEM assinatura,
/// SEM renovação automática.
///
/// Usa o plugin oficial `in_app_purchase`, que por baixo chama:
///  - Google Play Billing (produto do tipo "in-app product" não recorrente)
///    no Android;
///  - StoreKit, como produto "Non-Consumable" (não consumível), no iOS.
///
/// PRÉ-REQUISITO (fora do código): o id abaixo precisa existir, com esse
/// mesmo texto, cadastrado no Google Play Console (produto gerenciado,
/// compra única) e no App Store Connect (In-App Purchase, tipo
/// Non-Consumable). Isso não é algo que se resolve por código — é
/// configuração feita no console de cada loja.
class PurchaseService {
  static const String premiumProductId = 'premium_vitalicio';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  ProductDetails? _productDetails;
  ProductDetails? get productDetails => _productDetails;

  Future<void> init({required bool initiallyPremium}) async {
    isPremium.value = initiallyPremium;

    final available = await _iap.isAvailable();
    if (!available) {
      lastError.value =
          'Loja indisponível neste dispositivo (sem Play Store/App Store).';
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        lastError.value = error.toString();
      },
    );

    final response =
        await _iap.queryProductDetails({premiumProductId});
    if (response.notFoundIDs.isNotEmpty) {
      lastError.value =
          'Produto "$premiumProductId" não encontrado na loja — verifique '
          'se ele foi cadastrado no Play Console / App Store Connect.';
    }
    if (response.productDetails.isNotEmpty) {
      _productDetails = response.productDetails.first;
    }
  }

  Future<void> buyPremium() async {
    final product = _productDetails;
    if (product == null) {
      lastError.value = 'Produto Premium ainda não carregado.';
      return;
    }
    final param = PurchaseParam(productDetails: product);
    // Não-consumível: compra única, permanece "dona" para sempre.
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          lastError.value = purchase.error?.message ?? 'Erro na compra.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == premiumProductId) {
            isPremium.value = true;
          }
          break;
        case PurchaseStatus.canceled:
          break;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  bool get isIOS => Platform.isIOS;

  void dispose() {
    _subscription?.cancel();
  }
}
