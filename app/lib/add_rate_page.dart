import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import 'api.dart';
import 'format.dart';
import 'location_picker.dart';
import 'models.dart';
import 'settings.dart';

const _units = {
  'sqft': 'per sq ft',
  'sqm': 'per sq m',
  'sqyd': 'per sq yard',
  'guntha': 'per guntha',
  'acre': 'per acre',
};
const _sources = {'listing': 'Listing (portal, ad)', 'manual': 'Deal or quote I heard'};
const _approvals = {
  'unknown': "Don't know",
  'a_khata': 'A khata',
  'b_khata': 'B khata',
  'e_khata': 'E khata',
  'dc_converted': 'DC converted',
  'bda_approved': 'BDA approved',
  'bmrda_approved': 'BMRDA approved',
  'biaapa_approved': 'BIAAPA approved',
  'agricultural': 'Agricultural',
};

/// Form for logging a market rate seen for an area. Pops `true` when saved.
class AddRatePage extends StatefulWidget {
  const AddRatePage({
    super.key,
    required this.area,
    this.initialType,
    this.initialRate,
    this.initialUnit,
    this.initialNote,
    this.initialSource,
  });

  final Area area;
  final String? initialType;
  final double? initialRate;
  final String? initialUnit;
  final String? initialNote;
  final String? initialSource;

  @override
  State<AddRatePage> createState() => _AddRatePageState();
}

class _AddRatePageState extends State<AddRatePage> {
  final _form = GlobalKey<FormState>();
  late final _rate = TextEditingController(text: _initialRateText());
  late final _note = TextEditingController(text: widget.initialNote ?? '');
  late String _type = widget.initialType ?? 'plot';
  late String _unit = _units.containsKey(widget.initialUnit) ? widget.initialUnit! : (_type == 'agricultural_land' ? 'acre' : 'sqft');
  late String _source = widget.initialSource ?? 'listing';
  String _approval = 'unknown';
  DateTime _date = DateTime.now();
  LatLng? _pin;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _rate.dispose();
    _note.dispose();
    super.dispose();
  }

  String _initialRateText() {
    final r = widget.initialRate;
    if (r == null) return '';
    return r >= 100 ? r.round().toString() : r.toStringAsFixed(2);
  }

  double? get _rateValue => double.tryParse(_rate.text.replaceAll(',', '').trim());

  String? get _perSqftPreview {
    final v = _rateValue;
    if (v == null || v <= 0) return null;
    final perSqft = switch (_unit) {
      'sqm' => v / sqftPerSqm,
      'sqyd' => v / 9,
      'guntha' => v / sqftPerGuntha,
      'acre' => v / sqftPerAcre,
      _ => v,
    };
    return '= ${headline(_type, perSqft)}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickLocation() async {
    final a = widget.area;
    final start = _pin ?? (a.lat != null && a.lon != null ? LatLng(a.lat!, a.lon!) : null);
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => LocationPickerPage(title: 'Where is ${a.name}?', initial: start)),
    );
    if (picked != null) setState(() => _pin = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final key = EditorKey.current.value;
    if (key == null) {
      setState(() => _error = 'Add your editor key in Settings first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await NelaBeleApi().addMarketRate(
        editorKey: key,
        areaId: widget.area.id,
        propertyType: _type,
        rate: _rateValue!,
        unit: _unit,
        observedOn: _date,
        source: _source,
        approvalStatus: _approval,
        note: _note.text,
        lat: _pin?.latitude,
        lon: _pin?.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Market rate saved')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Log a market rate')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.area.name, style: theme.textTheme.titleLarge),
            Text(widget.area.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: [
                for (final t in ['plot', 'agricultural_land', 'apartment', 'independent_house'])
                  ButtonSegment(value: t, label: Text(propertyLabel(t))),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                if (_type == 'agricultural_land' && _unit == 'sqft') _unit = 'acre';
              }),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rate,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Rate (₹)',
                      helperText: _perSqftPreview,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '').trim());
                      if (n == null) return 'Enter the rate as a number';
                      if (n <= 0) return 'Rate must be more than zero';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('unit-$_unit'),
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                    items: [for (final e in _units.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _source,
              decoration: const InputDecoration(labelText: 'Where it came from', border: OutlineInputBorder()),
              items: [for (final e in _sources.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _source = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _approval,
              decoration: const InputDecoration(labelText: 'Khata / approval', border: OutlineInputBorder()),
              items: [for (final e in _approvals.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _approval = v!),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text('Seen on ${_date.day} ${monthYear(_date)}'),
            ),
            const SizedBox(height: 16),
            _LocationRow(
              onMap: widget.area.lat != null,
              pinned: _pin != null,
              onPick: _pickLocation,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. 30×40 corner site, 99acres listing',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save rate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.onMap, required this.pinned, required this.onPick});

  final bool onMap;
  final bool pinned;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text, action) = pinned
        ? (Icons.where_to_vote_outlined, 'Location pinned', 'Change')
        : onMap
            ? (Icons.place_outlined, 'On the map', 'Adjust')
            : (Icons.wrong_location_outlined, 'Not on the map yet', 'Set location');
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: pinned ? theme.colorScheme.primary : null),
        title: Text(text),
        subtitle: !onMap && !pinned ? const Text('Drop a pin so this place shows on the map') : null,
        trailing: TextButton(onPressed: onPick, child: Text(action)),
      ),
    );
  }
}
