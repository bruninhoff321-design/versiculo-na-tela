/// As duas próximas orações agendadas no horário local do aparelho.
class PrayerSlot {
  const PrayerSlot(this.day, this.morning);

  final DateTime day;
  final bool morning;

  DateTime get scheduledAt =>
      DateTime(day.year, day.month, day.day, morning ? 5 : 18);
}

List<PrayerSlot> nextTwoPrayerSlots(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  return [
    PrayerSlot(today, true),
    PrayerSlot(today, false),
    PrayerSlot(tomorrow, true),
    PrayerSlot(tomorrow, false),
  ].where((slot) => slot.scheduledAt.isAfter(now)).take(2).toList();
}
