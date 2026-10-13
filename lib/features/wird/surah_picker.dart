import 'package:flutter/material.dart';

import '../../core/surahs.dart';
import '../../core/theme.dart';

/// Searchable list of all 114 surahs. Returns the chosen name (or null).
Future<String?> pickSurah(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _Picker(),
    );

class _Picker extends StatefulWidget {
  const _Picker();
  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = <int>[
      for (var i = 0; i < surahNames.length; i++)
        if (q.isEmpty ||
            surahNames[i].toLowerCase().contains(q.toLowerCase()) ||
            '${i + 1}' == q)
          i,
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            autofocus: false,
            decoration: const InputDecoration(
                hintText: 'Surah ka naam ya number', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => q = v.trim()),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, k) {
              final i = items[k];
              return ListTile(
                leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: p.accentSoft,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: p.accent))),
                title: Text(surahNames[i]),
                onTap: () => Navigator.pop(context, surahNames[i]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
