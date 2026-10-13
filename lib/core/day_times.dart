
/// One day's six solar/prayer reference times.
class DayTimes {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha;

  const DayTimes(
      this.fajr, this.sunrise, this.dhuhr, this.asr, this.maghrib, this.isha);

  /// [fajr, dhuhr, asr, maghrib, isha]
  List<DateTime> get five => [fajr, dhuhr, asr, maghrib, isha];
}
