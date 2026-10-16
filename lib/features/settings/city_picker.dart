import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/prayer_utils.dart';
import '../../core/theme.dart';
import '../../providers/settings_provider.dart';

/// Searchable list of cities, plus "any other place" by latitude / longitude.
void showCityPicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CityPicker(),
  );
}

class _CityPicker extends ConsumerStatefulWidget {
  const _CityPicker();
  @override
  ConsumerState<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends ConsumerState<_CityPicker> {
  String q = '';

  Future<void> _custom() async {
    final s = ref.read(settingsProvider);
    final name = TextEditingController(text: s.isCustom ? s.customName : '');
    final lat = TextEditingController(text: s.isCustom ? '${s.customLat}' : '');
    final lng = TextEditingController(text: s.isCustom ? '${s.customLng}' : '');
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Apni jagah daalein'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Naam')),
              const SizedBox(height: 10),
              TextField(
                  controller: lat,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration:
                      const InputDecoration(labelText: 'Latitude (jaise 19.99)')),
              const SizedBox(height: 10),
              TextField(
                  controller: lng,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration:
                      const InputDecoration(labelText: 'Longitude (jaise 73.78)')),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final la = double.tryParse(lat.text.trim());
                final lo = double.tryParse(lng.text.trim());
                if (!isValidCoordinates(la, lo)) {
                  setD(() => error =
                      'Latitude -90 se 90 aur longitude -180 se 180 ke beech hona chahiye');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final n = name.text.trim().isEmpty ? 'My location' : name.text.trim();
      ref.read(settingsProvider.notifier).setCustomLocation(
          n, double.parse(lat.text.trim()), double.parse(lng.text.trim()));
      if (mounted) Navigator.pop(context);
    }
    name.dispose();
    lat.dispose();
    lng.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final matches = [
      for (var i = 0; i < cities.length; i++)
        if (cities[i].name.toLowerCase().contains(q.toLowerCase())) i
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
            left: 16,
            right: 16),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Shehar dhundhein'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(children: [
                for (final i in matches)
                  ListTile(
                    leading: Icon(
                        s.city == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: s.city == i ? p.accent : p.faint),
                    title: Text(cities[i].name),
                    onTap: () {
                      n.setCity(i);
                      Navigator.pop(context);
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.edit_location_alt_outlined, color: p.gold),
                  title: Text(s.isCustom
                      ? 'Custom: ${s.customName}'
                      : 'Apni jagah (latitude / longitude)'),
                  onTap: _custom,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
