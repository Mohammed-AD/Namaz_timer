import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/backup.dart';
import '../../providers/log_provider.dart';
import '../../providers/prefs_provider.dart';
import '../../providers/rest_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wird_provider.dart';
import 'city_picker.dart';
import 'times_editor_page.dart';

void showSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showSettings(context),
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Settings',
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  Widget _title(BuildContext c, String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
                color: c.pal.accent)),
      );

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final msg = ScaffoldMessenger.of(context);
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup restore karein?'),
        content: Text(clip.trim().isEmpty
            ? 'Clipboard khaali hai. Pehle apna backup text copy karein.'
            : 'Clipboard ka backup lagu hoga aur maujooda data badal jayega.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          if (clip.trim().isNotEmpty)
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restore')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await importBackup(ref.read(prefsProvider), clip);
      ref
        ..invalidate(settingsProvider)
        ..invalidate(logProvider)
        ..invalidate(specialLogProvider)
        ..invalidate(restProvider)
        ..invalidate(wirdProvider);
      msg.showSnackBar(const SnackBar(content: Text('Backup restore ho gaya.')));
    } on FormatException catch (e) {
      msg.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              _title(context, 'NAMAZ KE WAQT'),
              AppTile(
                icon: Icons.location_on_outlined,
                title: s.place.name,
                subtitle: 'Shehar badlein ya apni jagah daalein',
                onTap: () => showCityPicker(context),
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Asr: Hanafi')),
                  ButtonSegment(value: false, label: Text("Asr: Shafi'i")),
                ],
                selected: {s.hanafi},
                onSelectionChanged: (v) => n.setHanafi(v.first),
              ),
              const SizedBox(height: 10),
              AppTile(
                icon: Icons.edit_calendar_outlined,
                title: 'Apne namaz ke waqt set karein',
                subtitle: s.anyCustom
                    ? 'Aapke kuch waqt badle hue hain'
                    : 'Masjid ke hisaab se har namaz ka waqt badlein',
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.push(MaterialPageRoute<void>(
                      builder: (_) => const TimesEditorPage()));
                },
              ),
              _title(context, 'HIJRI TAREEKH'),
              Text('Chaand dikhne ke hisaab se 1 din aage/peeche karein.',
                  style: TextStyle(color: p.muted, fontSize: 12)),
              const SizedBox(height: 10),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: -1, label: Text('-1 din')),
                  ButtonSegment(value: 0, label: Text('Auto')),
                  ButtonSegment(value: 1, label: Text('+1 din')),
                ],
                selected: {s.hijriAdj},
                onSelectionChanged: (v) => n.setHijriAdj(v.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maghrib par tareekh badlein'),
                subtitle: Text(
                    'Islami din Maghrib se shuru hota hai. On karne par Maghrib ke baad agli Hijri tareekh dikhegi.',
                    style: TextStyle(fontSize: 12, color: p.muted)),
                value: s.hijriMaghrib,
                onChanged: n.setHijriMaghrib,
              ),
              _title(context, 'THEME'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Auto')),
                  ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light')),
                  ButtonSegment(
                      value: 2,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => n.setThemeMode(v.first),
              ),
              _title(context, 'PERSONAL'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Special days (optional)'),
                subtitle: Text(
                    'For days when you want to pause namaz tracking. These dates show a dhikr routine instead. Off by default.',
                    style: TextStyle(fontSize: 12, color: p.muted)),
                value: s.restEnabled,
                onChanged: n.setRestEnabled,
              ),
              _title(context, 'BACKUP'),
              Text(
                  'Namaz log, wird aur settings sirf is phone me hain. Phone badalne ya app delete karne se pehle backup copy kar lein.',
                  style: TextStyle(color: p.muted, fontSize: 12)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final msg = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(
                          text: exportBackup(ref.read(prefsProvider))));
                      msg.showSnackBar(const SnackBar(
                          content: Text(
                              'Backup copy ho gaya. Kisi safe jagah paste karke rakh lein.')));
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Backup copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _restore(context, ref),
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore'),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }
}

/// Tappable row used in settings.
class AppTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const AppTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: p.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: p.muted)),
                  ]),
            ),
            Icon(Icons.chevron_right, color: p.faint),
          ]),
        ),
      ),
    );
  }
}
