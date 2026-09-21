import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Implementa a seção 17 do briefing: gera uma imagem com o versículo, a
/// referência e uma identificação discreta do app, e abre o menu nativo de
/// compartilhamento do Android/iOS (share_plus usa os intents/UIActivity
/// nativos de cada plataforma).
Future<void> shareVerseAsImage({
  required BuildContext context,
  required String text,
  required String reference,
}) async {
  final bytes = await _renderVerseImage(text: text, reference: reference);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/versiculo_compartilhado.png');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: '“$text”\n$reference\n\nVersículo na Tela',
  );
}

Future<Uint8List> _renderVerseImage({
  required String text,
  required String reference,
}) async {
  const size = Size(1080, 1080);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

  final gradient = ui.Gradient.linear(
    Offset.zero,
    Offset(size.width, size.height),
    [const Color(0xFF3A2E55), const Color(0xFFA8763A)],
  );
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, size.height),
    Paint()..shader = gradient,
  );

  final textColor = const Color(0xFFFBF3E7);

  final verseSpan = TextSpan(
    text: '“$text”',
    style: TextStyle(
      color: textColor,
      fontSize: 52,
      fontStyle: FontStyle.italic,
      fontFamily: 'serif',
      height: 1.35,
    ),
  );
  final verseLayout = TextPainter(
    text: verseSpan,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 160);
  final verseOffset = Offset(
    (size.width - verseLayout.width) / 2,
    (size.height - verseLayout.height) / 2 - 60,
  );
  verseLayout.paint(canvas, verseOffset);

  final refSpan = TextSpan(
    text: reference,
    style: TextStyle(
      color: textColor,
      fontSize: 34,
      fontWeight: FontWeight.bold,
      fontFamily: 'serif',
    ),
  );
  final refLayout = TextPainter(
    text: refSpan,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 160);
  refLayout.paint(
    canvas,
    Offset((size.width - refLayout.width) / 2,
        verseOffset.dy + verseLayout.height + 30),
  );

  final brandSpan = TextSpan(
    text: 'Versículo na Tela',
    style: TextStyle(
      color: textColor.withOpacity(0.75),
      fontSize: 24,
      fontFamily: 'serif',
    ),
  );
  final brandLayout = TextPainter(
    text: brandSpan,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 160);
  brandLayout.paint(
    canvas,
    Offset((size.width - brandLayout.width) / 2, size.height - 90),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
