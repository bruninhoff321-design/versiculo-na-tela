import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// "Versículo diário" (seção 18 do briefing). Usa flutter_local_notifications,
/// que por baixo aciona as APIs oficiais de notificação de cada plataforma
/// (NotificationManager no Android, UNUserNotificationCenter no iOS) — não
/// existe implementação própria de agendamento aqui.
class NotificationService {
  static const int _dailyNotificationId = 1001;
  static const int _lockScreenVerseId = 1002;
  static const int _morningPrayerId = 2001;
  static const int _eveningPrayerId = 2002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<String?> openedPrayer = ValueNotifier<String?>(null);

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // pedimos explicitamente depois
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload?.startsWith('prayer:') == true) {
          openedPrayer.value = response.payload;
        }
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true &&
        payload?.startsWith('prayer:') == true) {
      openedPrayer.value = payload;
    }
  }

  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? true;
    final iosGranted = await iosImpl?.requestPermissions(
          alert: true,
          badge: false,
          sound: false,
        ) ??
        true;
    return androidGranted && iosGranted;
  }

  /// [timeOfDay] no formato "HH:mm".
  Future<void> scheduleDaily(String timeOfDay) async {
    await _plugin.cancel(_dailyNotificationId);

    final parts = timeOfDay.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      'Versículo na Tela',
      'Seu versículo de hoje está esperando por você 📖',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'versiculo_diario_silencioso',
          'Lembrete diário silencioso',
          channelDescription: 'Lembrete diário sem som ou vibração',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
        ),
        iOS: DarwinNotificationDetails(presentSound: false),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repete todo dia
    );
  }

  Future<void> cancelDaily() async {
    await _plugin.cancel(_dailyNotificationId);
  }

  Future<void> schedulePrayerReminders() async {
    await cancelPrayerReminders();
    await _schedulePrayer(_morningPrayerId, 5, 'prayer:morning');
    await _schedulePrayer(_eveningPrayerId, 18, 'prayer:evening');
  }

  Future<void> _schedulePrayer(int id, int hour, String payload) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) {
      scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, hour);
    }
    await _plugin.zonedSchedule(
      id,
      'Hora da oração',
      hour == 5 ? 'Comece o dia em oração.' : 'Termine o dia em oração.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hora_da_oracao_silenciosa',
          'Hora da oração',
          channelDescription: 'Lembretes de oração sem som nem vibração',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
        ),
        iOS: DarwinNotificationDetails(presentSound: false),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelPrayerReminders() async {
    await _plugin.cancel(_morningPrayerId);
    await _plugin.cancel(_eveningPrayerId);
  }

  Future<void> showLockScreenVerse(String text, String reference) async {
    await _plugin.show(
      _lockScreenVerseId,
      reference,
      text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'versiculo_no_bloqueio',
          'Versículo na tela de bloqueio',
          channelDescription: 'Exibe o versículo sem som ou vibração',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(text),
        ),
      ),
    );
  }

  Future<void> cancelLockScreenVerse() => _plugin.cancel(_lockScreenVerseId);
}
