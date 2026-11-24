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
    text: '“$text”\n$reference\n\nBíblia e Oração',
  );
}

Future<Uint8List> _renderVerseImage({
  required String text,
  required String reference,
}) async {
  // Formato vertical do status do WhatsApp / Stories.
  const size = Size(1080, 1920);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

  final gradient = ui.Gradient.linear(
    Offset.zero,
    Offset(0, size.height),
    const [
      Color(0xFF0B1433),
      Color(0xFF2A2360),
      Color(0xFFB8566B),
      Color(0xFFF6A04D),
    ],
    const [0, 0.45, 0.8, 1],
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
      fontSize: text.length > 220 ? 54 : 66,
      fontStyle: FontStyle.italic,
      fontFamily: 'Fraunces',
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
      color: const Color(0xFFF7D27A),
      fontSize: 40,
      fontWeight: FontWeight.bold,
      fontFamily: 'Manrope',

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
    text: 'Bíblia e Oração',
    style: TextStyle(
      color: textColor.withOpacity(0.85),
      fontSize: 34,
      fontWeight: FontWeight.w700,
      fontFamily: 'Manrope',
    ),
  );
  final brandLayout = TextPainter(
    text: brandSpan,
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 160);
  brandLayout.paint(
    canvas,
    Offset((size.width - brandLayout.width) / 2, size.height - 170),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
