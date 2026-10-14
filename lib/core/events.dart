/// Notable Hijri dates. Returns null for ordinary days.
({String name, bool major})? islamicEvent(int m, int d) {
  switch (m * 100 + d) {
    case 101:
      return (name: 'Islamic New Year', major: true);
    case 109:
      return (name: "Tasu'a (sunnah roza with Ashura)", major: false);
    case 110:
      return (name: 'Ashura', major: true);
    case 312:
      return (name: "Mawlid (12 Rabi' al-Awwal)", major: true);
    case 727:
      return (name: "Shab-e-Meraj (Isra & Mi'raj)", major: true);
    case 815:
      return (name: 'Shab-e-Barat', major: true);
    case 901:
      return (name: 'Ramadan begins', major: true);
    case 927:
      return (name: 'Laylat al-Qadr (likely)', major: true);
    case 1001:
      return (name: 'Eid ul-Fitr', major: true);
    case 1209:
      return (name: 'Day of Arafah', major: true);
    case 1210:
      return (name: 'Eid ul-Adha', major: true);
  }
  if (m == 12 && d >= 11 && d <= 13) {
    return (name: 'Ayyam al-Tashreeq', major: false);
  }
  // Ramadan's fasts are obligatory, so the "sunnah roza" label would be wrong.
  if (m != 9 && d >= 13 && d <= 15) {
    return (name: 'Ayyam al-Bidh · sunnah roza', major: false);
  }
  return null;
}
