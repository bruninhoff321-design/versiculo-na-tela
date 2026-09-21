import 'package:flutter_test/flutter_test.dart';
import 'package:versiculo_na_tela/core/theme/app_theme.dart';
import 'package:versiculo_na_tela/domain/models/app_settings.dart';

void main() {
  test('AppTheme.light() e AppTheme.dark() constroem temas válidos', () {
    expect(AppTheme.light(), isNotNull);
    expect(AppTheme.dark(), isNotNull);
  });

  test('AppSettings tem valores padrão sensatos', () {
    const settings = AppSettings();
    expect(settings.frequency, UpdateFrequency.min60);
    expect(settings.noRepeat, NoRepeatOption.next20);
    expect(settings.onboarded, isFalse);
  });
}
