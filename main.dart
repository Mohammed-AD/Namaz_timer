import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const prayerIcons = [
  Icons.wb_twilight, Icons.wb_sunny, Icons.wb_cloudy, Icons.nights_stay, Icons.dark_mode
];
const gold = Color(0xFFD4AF37);
const bg = Color(0xFF0B1512);
const card = Color(0xFF12211C);
const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
String p2(int n) => n.toString().padLeft(2, '0');
DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Each day = one int bitmask (5 bits). O(1) toggle/read, tiny storage, all local.
class Store extends ChangeNotifier {
  late SharedPreferences _p;
  Map<String, int> data = {};
  int style = 0;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    style = _p.getInt('style') ?? 0;
    try {
      final s = _p.getString('log');
      if (s != null) {
        data = (jsonDecode(s) as Map).map((k, v) => MapEntry(k as String, v as int));
      }
    } catch (_) {
      data = {};
    }
  }

  static String key(DateTime d) => '${d.year}${p2(d.month)}${p2(d.day)}';
  int mask(DateTime d) => data[key(d)] ?? 0;
  int count(DateTime d) {
    var m = mask(d), c = 0;
    while (m > 0) { c += m & 1; m >>= 1; }
    return c;
  }

  void toggle(DateTime d, int i) {
    final k = key(d);
    final m = (data[k] ?? 0) ^ (1 << i);
    m == 0 ? data.remove(k) : data[k] = m;
    _p.setString('log', jsonEncode(data));
    notifyListeners();
  }

  void setStyle(int v) {
    style = v;
    _p.setInt('style', v);
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final s = Store();
  await s.load();
  runApp(App(s));
}

class App extends StatelessWidget {
  final Store s;
  const App(this.s, {super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Namaz & Islamic Calendar',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
          scaffoldBackgroundColor: bg,
          cardTheme: CardThemeData(color: card, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 4)),
        ),
        home: Home(s),
      );
}

class Home extends StatefulWidget {
  final Store s;
  const Home(this.s, {super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [WatchPage(widget.s, i == 0), NamazPage(widget.s), CalendarPage(widget.s), const TimerPage()];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: IndexedStack(index: i, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.watch_outlined), label: 'Watch'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Namaz'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Timer'),
        ],
      ),
    );
  }
}

// ---------------- Watch ----------------
class WatchPage extends StatefulWidget {
  final Store s;
  final bool active;
  const WatchPage(this.s, this.active, {super.key});
  @override
  State<WatchPage> createState() => _WatchState();
}

class _WatchState extends State<WatchPage> {
  DateTime now = DateTime.now();
  Timer? t;
  void _sync() {
    t?.cancel();
    t = null;
    if (widget.active) {
      now = DateTime.now();
      t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => now = DateTime.now()));
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(WatchPage o) {
    super.didUpdateWidget(o);
    if (o.active != widget.active) _sync();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = HijriCalendar.fromDate(now);
    final h12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return ListenableBuilder(
      listenable: widget.s,
      builder: (_, _) {
        final st = widget.s.style;
        Widget face;
        if (st == 0) {
          face = CustomPaint(painter: AnalogPainter(now), size: const Size(280, 280));
        } else if (st == 1) {
          face = Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24), border: Border.all(color: gold, width: 2)),
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${p2(h12)}:${p2(now.minute)}', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w300, color: gold, fontFeatures: [FontFeature.tabularFigures()])),
              Padding(padding: const EdgeInsets.only(bottom: 10, left: 6), child: Text('${p2(now.second)} ${now.hour < 12 ? 'AM' : 'PM'}', style: const TextStyle(fontSize: 18))),
            ]),
          );
        } else {
          face = SizedBox(
            width: 260, height: 260,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(value: (now.second + 1) / 60, strokeWidth: 10, color: gold, backgroundColor: card)),
              Text('${p2(h12)}:${p2(now.minute)}', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w200)),
            ]),
          );
        }
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          face,
          const SizedBox(height: 28),
          Text('${h.hDay} ${h.longMonthName} ${h.hYear} AH', style: const TextStyle(fontSize: 22, color: gold)),
          const SizedBox(height: 4),
          Text('${now.day} ${months[now.month - 1]} ${now.year}', style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 28),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Analog')),
              ButtonSegment(value: 1, label: Text('Digital')),
              ButtonSegment(value: 2, label: Text('Ring')),
            ],
            selected: {st},
            onSelectionChanged: (v) => widget.s.setStyle(v.first),
          ),
        ]);
      },
    );
  }
}

class AnalogPainter extends CustomPainter {
  final DateTime t;
  AnalogPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.shortestSide / 2;
    c.drawCircle(ctr, r, Paint()..color = card);
    c.drawCircle(ctr, r - 2, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 4);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(ctr + d * (r * .84), ctr + d * (r * .93), Paint()..color = gold..strokeWidth = i % 3 == 0 ? 4 : 2);
    }
    void hand(double f, double len, double w, Color col) {
      final a = f * 2 * math.pi - math.pi / 2;
      c.drawLine(ctr, ctr + Offset(math.cos(a), math.sin(a)) * (r * len),
          Paint()..color = col..strokeWidth = w..strokeCap = StrokeCap.round);
    }
    hand(((t.hour % 12) + t.minute / 60) / 12, .5, 6, Colors.white);
    hand((t.minute + t.second / 60) / 60, .75, 4, Colors.white);
    hand(t.second / 60, .85, 2, Colors.redAccent);
    c.drawCircle(ctr, 6, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(AnalogPainter o) => o.t.second != t.second;
}

// ---------------- Prayer tiles (shared) ----------------
class PrayerTiles extends StatelessWidget {
  final Store s;
  final DateTime d;
  const PrayerTiles(this.s, this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    final future = dayOnly(d).isAfter(dayOnly(DateTime.now()));
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) {
        final m = s.mask(d);
        return Column(children: [
          for (var i = 0; i < 5; i++)
            Card(
              child: CheckboxListTile(
                value: ((m >> i) & 1) == 1,
                onChanged: future ? null : (_) { HapticFeedback.selectionClick(); s.toggle(d, i); },
                title: Text(prayers[i]),
                secondary: Icon(prayerIcons[i], color: gold),
                activeColor: gold,
                checkColor: Colors.black,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ),
        ]);
      },
    );
  }
}

// ---------------- Namaz + year heatmap ----------------
class NamazPage extends StatefulWidget {
  final Store s;
  const NamazPage(this.s, {super.key});
  @override
  State<NamazPage> createState() => _NamazState();
}

class _NamazState extends State<NamazPage> {
  int year = DateTime.now().year;
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return ListView(padding: const EdgeInsets.all(16), children: [
      ListenableBuilder(
        listenable: widget.s,
        builder: (_, _) => Text('Today: ${widget.s.count(today)}/5 namaz',
            style: const TextStyle(fontSize: 24, color: gold, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 8),
      PrayerTiles(widget.s, today),
      const SizedBox(height: 20),
      Row(children: [
        IconButton(onPressed: () => setState(() => year--), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Center(child: Text('$year overview', style: const TextStyle(fontSize: 18)))),
        IconButton(onPressed: () => setState(() => year++), icon: const Icon(Icons.chevron_right)),
      ]),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ListenableBuilder(
          listenable: widget.s,
          builder: (_, _) => RepaintBoundary(
            child: CustomPaint(size: const Size(54 * HeatPainter.cell, 7 * HeatPainter.cell), painter: HeatPainter(widget.s, year)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text('Gold jitna gehra, utni zyada namaz (5/5 = full gold)', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }
}

/// Draws the whole year in ONE canvas pass: O(365) time, O(1) widgets.
class HeatPainter extends CustomPainter {
  static const cell = 16.0;
  final Store s;
  final int year;
  HeatPainter(this.s, this.year);
  @override
  void paint(Canvas c, Size size) {
    final start = DateTime(year, 1, 1);
    final off = start.weekday % 7;
    final days = DateTime(year + 1, 1, 1).difference(start).inDays;
    final p = Paint();
    for (var i = 0; i < days; i++) {
      final n = s.count(DateTime(year, 1, 1 + i));
      p.color = n == 0 ? card : gold.withValues(alpha: .2 + .16 * n);
      final x = ((i + off) ~/ 7) * cell, y = ((i + off) % 7) * cell;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 1.5, y + 1.5, cell - 3, cell - 3), const Radius.circular(3)), p);
    }
  }

  @override
  bool shouldRepaint(HeatPainter o) => true;
}

// ---------------- Hijri calendar ----------------
class CalendarPage extends StatefulWidget {
  final Store s;
  const CalendarPage(this.s, {super.key});
  @override
  State<CalendarPage> createState() => _CalState();
}

class _CalState extends State<CalendarPage> {
  late int hy, hm;
  DateTime sel = dayOnly(DateTime.now());
  final hc = HijriCalendar();
  @override
  void initState() {
    super.initState();
    final n = HijriCalendar.now();
    hy = n.hYear;
    hm = n.hMonth;
  }

  void move(int delta) => setState(() {
        hm += delta;
        if (hm > 12) { hm = 1; hy++; }
        if (hm < 1) { hm = 12; hy--; }
      });

  @override
  Widget build(BuildContext context) {
    final days = hc.getDaysInMonth(hy, hm);
    final first = hc.hijriToGregorian(hy, hm, 1);
    final lead = first.weekday % 7;
    hc.hMonth = hm;
    final name = hc.longMonthName;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        IconButton(onPressed: () => move(-1), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Center(child: Text('$name $hy AH', style: const TextStyle(fontSize: 20, color: gold)))),
        IconButton(onPressed: () => move(1), icon: const Icon(Icons.chevron_right)),
      ]),
      Row(children: [for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) Expanded(child: Center(child: Text(d, style: const TextStyle(color: Colors.white54))))]),
      const SizedBox(height: 6),
      ListenableBuilder(
        listenable: widget.s,
        builder: (_, _) => GridView.count(
          crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < lead; i++) const SizedBox(),
            for (var d = 1; d <= days; d++) _day(d),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text('${sel.day} ${months[sel.month - 1]} ${sel.year}', style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 6),
      PrayerTiles(widget.s, sel),
    ]);
  }

  Widget _day(int d) {
    final g = dayOnly(hc.hijriToGregorian(hy, hm, d));
    final isSel = g == sel;
    final isToday = g == dayOnly(DateTime.now());
    final c = widget.s.count(g);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => sel = g),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSel ? gold.withValues(alpha: .25) : card,
          border: isToday ? Border.all(color: gold) : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$d', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${g.day}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 2),
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c == 0 ? Colors.transparent : gold.withValues(alpha: .3 + .14 * c))),
        ]),
      ),
    );
  }
}

// ---------------- Timer with alarm ----------------
Uint8List _beepWav() {
  const sr = 8000, n = sr;
  final b = ByteData(44 + n * 2);
  void tag(int o, String t) { for (var i = 0; i < 4; i++) { b.setUint8(o + i, t.codeUnitAt(i)); } }
  tag(0, 'RIFF'); b.setUint32(4, 36 + n * 2, Endian.little); tag(8, 'WAVE'); tag(12, 'fmt ');
  b.setUint32(16, 16, Endian.little); b.setUint16(20, 1, Endian.little); b.setUint16(22, 1, Endian.little);
  b.setUint32(24, sr, Endian.little); b.setUint32(28, sr * 2, Endian.little);
  b.setUint16(32, 2, Endian.little); b.setUint16(34, 16, Endian.little);
  tag(36, 'data'); b.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final v = (t % 0.5) < 0.2 ? math.sin(2 * math.pi * 880 * t) * .6 : 0.0;
    b.setInt16(44 + i * 2, (v * 32767).toInt(), Endian.little);
  }
  return b.buffer.asUint8List();
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});
  @override
  State<TimerPage> createState() => _TimerState();
}

class _TimerState extends State<TimerPage> {
  int minutes = 10;
  Duration left = const Duration(minutes: 10);
  DateTime? endAt;
  Timer? tick;
  bool ringing = false;
  final player = AudioPlayer();

  @override
  void dispose() {
    tick?.cancel();
    player.dispose();
    super.dispose();
  }

  void start() {
    endAt = DateTime.now().add(left);
    tick?.cancel();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = endAt!.difference(DateTime.now());
      if (r <= Duration.zero) {
        tick?.cancel();
        endAt = null;
        setState(() { left = Duration.zero; ringing = true; });
        ring();
      } else {
        setState(() => left = Duration(seconds: (r.inMilliseconds / 1000).ceil()));
      }
    });
    setState(() {});
  }

  void pause() {
    tick?.cancel();
    endAt = null;
    setState(() {});
  }

  void reset() {
    tick?.cancel();
    endAt = null;
    stopAlarm();
    setState(() { left = Duration(minutes: minutes); ringing = false; });
  }

  Future<void> ring() async {
    HapticFeedback.heavyImpact();
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(BytesSource(_beepWav()));
    } catch (_) {}
  }

  Future<void> stopAlarm() async {
    try { await player.stop(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final running = endAt != null;
    final total = Duration(minutes: minutes).inMilliseconds;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        width: 240, height: 240,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(value: total == 0 ? 0 : left.inMilliseconds / total, strokeWidth: 10, color: ringing ? Colors.redAccent : gold, backgroundColor: card)),
          Text('${p2(left.inMinutes)}:${p2(left.inSeconds % 60)}', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w200)),
        ]),
      ),
      const SizedBox(height: 24),
      if (!running && !ringing) ...[
        Wrap(spacing: 8, children: [
          for (final m in [1, 5, 10, 15, 30, 60])
            ChoiceChip(label: Text('${m}m'), selected: minutes == m, onSelected: (_) => setState(() { minutes = m; left = Duration(minutes: m); })),
        ]),
        const SizedBox(height: 16),
      ],
      if (ringing)
        FilledButton.icon(onPressed: reset, icon: const Icon(Icons.alarm_off), label: const Text('Stop alarm'))
      else
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FilledButton.icon(onPressed: running ? pause : (left > Duration.zero ? start : null), icon: Icon(running ? Icons.pause : Icons.play_arrow), label: Text(running ? 'Pause' : 'Start')),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: reset, child: const Text('Reset')),
        ]),
    ]);
  }
}
