import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/wird_provider.dart';
import 'surah_picker.dart';

/// Add a new surah / dhikr, or edit an existing one. The user decides the
/// name AND how many times they want to read it.
Future<void> showWirdEditor(BuildContext context, {WirdItem? item}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _Editor(item: item),
    );

class _Editor extends ConsumerStatefulWidget {
  final WirdItem? item;
  const _Editor({this.item});
  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late int kind = widget.item?.kind ?? 0;
  late bool daily = widget.item?.daily ?? true;
  late final name = TextEditingController(text: widget.item?.name ?? '');
  late final arabicC = TextEditingController(text: widget.item?.arabic ?? '');
  late final target =
      TextEditingController(text: '${widget.item?.target ?? 1}');
  String? error;

  @override
  void dispose() {
    name.dispose();
    arabicC.dispose();
    target.dispose();
    super.dispose();
  }

  void _save() {
    final n = name.text.trim();
    final t = int.tryParse(target.text.trim()) ?? 0;
    if (n.isEmpty) {
      setState(() => error = 'Naam likhein ya list se chunein');
      return;
    }
    if (t < 1 || t > 100000) {
      setState(() => error = 'Target 1 se 100000 ke beech hona chahiye');
      return;
    }
    final notifier = ref.read(wirdProvider.notifier);
    final old = widget.item;
    if (old == null) {
      notifier.add(WirdItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: n,
        arabic: arabicC.text.trim(),
        kind: kind,
        target: t,
        daily: daily,
      ));
    } else {
      notifier.update(old.copyWith(
          name: n, arabic: arabicC.text.trim(), kind: kind, target: t, daily: daily));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item == null ? 'Naya wird jodein' : 'Wird badlein',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.menu_book_rounded),
                        label: Text('Surah')),
                    ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.blur_circular),
                        label: Text('Dhikr / Dua')),
                  ],
                  selected: {kind},
                  onSelectionChanged: (v) => setState(() => kind = v.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: kind == 0 ? 'Surah ka naam' : 'Dhikr / dua ka naam',
                    suffixIcon: kind == 0
                        ? IconButton(
                            tooltip: '114 surah ki list',
                            icon: const Icon(Icons.list_alt_rounded),
                            onPressed: () async {
                              final s = await pickSurah(context);
                              if (s != null) setState(() => name.text = s);
                            })
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: arabicC,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'Arabic (optional)'),
                ),
                const SizedBox(height: 16),
                Text('Kitni baar padhna hai? (limit)',
                    style: TextStyle(fontWeight: FontWeight.w800, color: p.accent)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final v in [1, 3, 7, 11, 33, 41, 100])
                    ChoiceChip(
                        label: Text('$v'),
                        selected: target.text == '$v',
                        onSelected: (_) => setState(() => target.text = '$v')),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: target,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Ya apni marzi ka number likhein'),
                  onChanged: (_) => setState(() {}),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Roz naye sire se shuru'),
                  subtitle: Text(
                      daily
                          ? 'Har din count 0 se shuru hoga'
                          : 'Count jama hota rahega (total)',
                      style: TextStyle(fontSize: 12, color: p.muted)),
                  value: daily,
                  onChanged: (v) => setState(() => daily = v),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(error!,
                        style: const TextStyle(color: Color(0xFFFF6B6B))),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: _save, child: const Text('Save karein')),
                ),
              ]),
        ),
      ),
    );
  }
}
