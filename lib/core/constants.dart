import 'package:flutter/material.dart';

const prayers = ['Fajr', 'Zohar', 'Asr', 'Maghrib', 'Isha'];
const arabic = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
const prayerIcons = [
  Icons.wb_twilight,
  Icons.wb_sunny_outlined,
  Icons.wb_cloudy_outlined,
  Icons.nights_stay_outlined,
  Icons.dark_mode_outlined,
];

/// What to do at prayer time on a special day, so the routine is never lost.
const specialIdeas = [
  'Astaghfirullah ×100',
  'SubhanAllah ×33',
  'Durood Shareef ×100',
  'Alhamdulillah ×33',
  'Dua ya Quran sunna',
];

const months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const hMonths = [
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Thani",
  'Jumada al-Awwal',
  'Jumada al-Thani',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qi'dah",
  'Dhu al-Hijjah',
];
const weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

class City {
  final String name;
  final double lat, lng;
  const City(this.name, this.lat, this.lng);
}

const makkah = City('Makkah', 21.4225, 39.8262);
const madinah = City('Madinah', 24.5247, 39.5692);

/// Makkah & Madinah are shown in their own local time (UTC+3).
const holyUtcMinutes = 180; // Saudi Arabia: UTC+03:00 (no DST)

/// Order matters: saved index points into this list. Only append at the end.
const cities = [
  City('Nashik', 19.9975, 73.7898),
  City('Mumbai', 19.076, 72.8777),
  City('Pune', 18.5204, 73.8567),
  City('Delhi', 28.6139, 77.209),
  City('Hyderabad', 17.385, 78.4867),
  City('Kolkata', 22.5726, 88.3639),
  makkah,
  City('Chennai', 13.0827, 80.2707),
  City('Bengaluru', 12.9716, 77.5946),
  City('Lucknow', 26.8467, 80.9462),
  City('Ahmedabad', 23.0225, 72.5714),
  madinah,
];
