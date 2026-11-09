import 'package:flutter/material.dart';

import 'api.dart';
import 'format.dart';
import 'listing.dart';
import 'models.dart';
import 'settings.dart';

const _typeWords = {
  'plot': 'plot', 'site': 'plot', 'land': 'plot',
  'farmland': 'agricultural_land', 'farm': 'agricultural_land', 'agri': 'agricultural_land',
  'agricultural': 'agricultural_land', 'agricultural_land': 'agricultural_land',
  'apartment': 'apartment', 'flat': 'apartment',
  'house': 'independent_house', 'villa': 'independent_house', 'independent_house': 'independent_house',
};

class _Row {
  _Row(this.line);

  final String line;
  Area? area;
  String? type;
  double? rate;
  String? unit;
  DateTime? date;
  String? note;
  String? problem;
  bool saved = false;

  bool get ready => problem == null && area != null && !saved;
}

/// Paste many market rates at once, one per line:
///   place, type, rate, unit[, date][, note]
class BulkImportPage extends StatefulWidget {
  const BulkImportPage({super.key});

  @override
  State<BulkImportPage> createState() => _BulkImportPageState();
}

class _BulkImportPageState extends State<BulkImportPage> {
  final _api = NelaBeleApi();
  final _text = TextEditingController();
  List<_Row> _rows = [];
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final lines = _text.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !RegExp(r'^(place|area)\s*,', caseSensitive: false).hasMatch(l))
        .take(200)
        .toList();
    setState(() {
      _busy = true;
      _status = 'Checking ${lines.length} line${lines.length == 1 ? '' : 's'}…';
    });
    final cache = <String, List<Area>>{};
    final rows = <_Row>[];
    for (final line in lines) {
      final row = _Row(line);
      rows.add(row);
      final cells = line.split(RegExp(r'\s*[,\t]\s*'));
      if (cells.length < 4) {
        row.problem = 'Needs place, type, rate and unit';
        continue;
      }
      row.type = _typeWords[cells[1].toLowerCase()];
      if (row.type == null) {
        row.problem = 'Unknown type "${cells[1]}"';
        continue;
      }
      row.rate = parseMoney(cells[2]);
      if (row.rate == null || row.rate! <= 0) {
        row.problem = 'Rate "${cells[2]}" is not a number';
        continue;
      }
      row.unit = unitCode(cells[3].replaceFirst(RegExp(r'^per\s*', caseSensitive: false), ''));
      if (row.unit == null) {
        row.problem = 'Unknown unit "${cells[3]}"';
        continue;
      }
      if (cells.length > 4 && cells[4].isNotEmpty) {
        row.date = DateTime.tryParse(cells[4]);
        if (row.date == null) {
          row.note = cells.sublist(4).join(', ');
        } else if (cells.length > 5) {
          row.note = cells.sublist(5).join(', ');
        }
      }
      // "Place / taluk" picks between places with the same name
      final parts = cells[0].split('/').map((s) => s.trim()).toList();
      final name = parts.first;
      final parent = parts.length > 1 ? parts[1].toLowerCase() : null;
      try {
        var found = cache[name.toLowerCase()] ??= await _api.findByName(name);
        if (parent != null) {
          found = found
              .where((a) =>
                  (a.parentName ?? '').toLowerCase().contains(parent) || a.district.toLowerCase().contains(parent))
              .toList();
        }
        if (found.isEmpty) {
          row.problem = 'No place called "${cells[0]}"';
        } else if (found.length > 1) {
          row.problem = '${found.length} places called $name – write "$name / ${found.first.parentName ?? 'taluk'}"';
        } else {
          row.area = found.first;
        }
      } catch (e) {
        row.problem = e.toString();
      }
      if (mounted) setState(() => _rows = [...rows]);
    }
    if (!mounted) return;
    final ok = rows.where((r) => r.ready).length;
    setState(() {
      _rows = rows;
      _busy = false;
      _status = '$ok of ${rows.length} ready to save';
    });
  }

  Future<void> _save() async {
    final key = EditorKey.current.value;
    if (key == null) return;
    final todo = _rows.where((r) => r.ready).toList();
    setState(() => _busy = true);
    var done = 0;
    for (final r in todo) {
      setState(() => _status = 'Saving ${done + 1} of ${todo.length}…');
      try {
        await _api.addMarketRate(
          editorKey: key,
          areaId: r.area!.id,
          propertyType: r.type!,
          rate: r.rate!,
          unit: r.unit!,
          observedOn: r.date ?? DateTime.now(),
          source: 'listing',
          note: r.note ?? 'Bulk import',
        );
        r.saved = true;
        done++;
      } catch (e) {
        r.problem = e.toString();
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = 'Saved $done of ${todo.length}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final ready = _rows.where((r) => r.ready).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'One rate per line: place, type, rate, unit, then an optional date (YYYY-MM-DD) and note. '
            'Types: plot, farmland, apartment, house. Units: sqft, sqm, sqyd, guntha, acre. '
            'Rates can be written as 85 L or 1.2 Cr. If two places share a name, write "Place / taluk".',
            style: muted,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 14,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Whitefield, apartment, 9500, sqft, 2026-10-12, 99acres\n'
                  'Hosahalli / Nelamangala, farmland, 1.1 Cr, acre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: _busy ? null : _check, child: const Text('Check')),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _busy || ready == 0 || EditorKey.current.value == null ? null : _save,
                child: Text('Save $ready rate${ready == 1 ? '' : 's'}'),
              ),
            ],
          ),
          if (_status != null) ...[const SizedBox(height: 12), Text(_status!, style: theme.textTheme.bodyMedium)],
          const SizedBox(height: 8),
          for (final r in _rows)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                r.saved
                    ? Icons.cloud_done_outlined
                    : r.ready
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                color: r.saved || r.ready ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
              title: Text(r.line, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                r.problem ??
                    '${r.area!.name} · ${r.area!.subtitle} · '
                        '${headline(r.type!, perSqft(r.rate!, r.unit!))}${r.saved ? ' · saved' : ''}',
              ),
            ),
        ],
      ),
    );
  }
}
