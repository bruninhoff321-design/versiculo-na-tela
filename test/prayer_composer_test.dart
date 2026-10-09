import 'package:flutter_test/flutter_test.dart';
import 'package:versiculo_na_tela/domain/prayer/prayer_composer.dart';

void main() {
  const composer = PrayerComposer();

  test('oração diária muda no dia seguinte e se mantém estável no mesmo dia',
      () {
    final today = DateTime(2026, 10, 8, 5);
    final tomorrow = DateTime(2026, 10, 9, 5);
    final first = composer.compose(day: today, morning: true);
    expect(
        composer.compose(day: DateTime(2026, 10, 8, 18), morning: true), first);
    expect(composer.compose(day: tomorrow, morning: true), isNot(first));
    expect(composer.compose(day: DateTime(2026, 10, 13), morning: true),
        isNot(first));
    expect(composer.compose(day: today, morning: false), isNot(first));
  });

  test('oração por necessidade usa o tema e não inventa texto bíblico', () {
    final prayer = composer.compose(
      day: DateTime(2026, 10, 8),
      morning: true,
      themeIds: const ['ansiedade', 'familia'],
      verseReference: 'Salmos 37:5',
    );
    expect(prayer, contains('preocupação'));
    expect(prayer, contains('família'));
    expect(prayer, contains('Salmos 37:5'));
    expect(prayer, contains('Em nome de Jesus, amém.'));
  });

  test('sem escolha, o assunto varia e o texto tem corpo para narração', () {
    final first = composer.compose(day: DateTime(2026, 10, 8), morning: true);
    final next = composer.compose(day: DateTime(2026, 10, 9), morning: true);
    expect(first, isNot(next));
    expect(first.split(RegExp(r'\s+')).length, inInclusiveRange(130, 190));
    expect(next.split(RegExp(r'\s+')).length, inInclusiveRange(130, 190));
  });

  test('tema força aparece na oração escolhida pela pessoa', () {
    final prayer = composer.compose(
      day: DateTime(2026, 10, 9),
      morning: true,
      themeIds: const ['forca'],
    );
    expect(prayer, contains('enfrentar os desafios'));
  });

  test('oração sobre luto começa acolhendo a dor antes de agradecer', () {
    final prayer = composer.compose(
      day: DateTime(2026, 10, 9),
      morning: true,
      themeIds: const ['luto'],
    );
    expect(prayer, startsWith('Senhor Deus, tu conheces o que estou vivendo'));
    expect(prayer.substring(0, 250), contains('Acolhe minha saudade'));
  });
}
