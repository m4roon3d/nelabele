import 'dart:async';

import 'add_rate_page.dart';
import 'api.dart';
import 'format.dart';
import 'listing.dart';
import 'models.dart';
import 'settings.dart';
import 'ui.dart';

const _unitLabels = {'sqft': 'sq ft', 'sqm': 'sq m', 'sqyd': 'sq yard', 'guntha': 'guntha', 'acre': 'acre'};

/// Turns listing text shared from a portal (or pasted) into a market rate:
/// reads the price, size and locality, then lets you pick the place.
class ListingImportPage extends StatefulWidget {
  const ListingImportPage({super.key, this.initialText = ''});

  final String initialText;

  @override
  State<ListingImportPage> createState() => _ListingImportPageState();
}

class _ListingImportPageState extends State<ListingImportPage> {
  final _api = NelaBeleApi();
  late final _text = TextEditingController(text: widget.initialText);
  final _place = TextEditingController();
  late ParsedListing _parsed = parseListing(widget.initialText);
  Timer? _debounce;
  int _requestId = 0;
  List<Area> _matches = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _place.text = _parsed.locality ?? '';
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _place.dispose();
    super.dispose();
  }

  void _onTextChanged(String t) {
    final before = _parsed.locality;
    setState(() => _parsed = parseListing(t));
    if (_parsed.locality != null && _parsed.locality != before && (_place.text.isEmpty || _place.text == before)) {
      _place.text = _parsed.locality!;
      _scheduleSearch();
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final q = _place.text.trim();
    final id = ++_requestId;
    if (q.length < 2) {
      setState(() => _matches = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final areas = await _api.fetchAreas(query: q);
      if (id != _requestId || !mounted) return;
      setState(() {
        _matches = areas.take(12).toList();
        _searching = false;
      });
    } catch (_) {
      if (id == _requestId && mounted) setState(() => _searching = false);
    }
  }

  Future<void> _use(Area area) async {
    final p = _parsed;
    final note = [
      if (p.size != null) 'Listing: ${_fmt(p.size!)} ${_unitLabels[p.sizeUnit]}',
      if (p.price != null) rupeesShort(p.price!),
      if (p.url != null) p.url!,
    ].join(' · ');
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AddRatePage(
        area: area,
        initialType: p.type,
        initialRate: p.rate,
        initialUnit: p.rateUnit,
        initialNote: note.length > 200 ? note.substring(0, 200) : note,
        initialSource: 'listing',
      ),
    ));
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final p = _parsed;
    return Scaffold(
      appBar: AppBar(title: const Text('Rate from a listing')),
      body: ValueListenableBuilder<String?>(
        valueListenable: EditorKey.current,
        builder: (context, key, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (key == null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: const ListTile(
                  leading: Icon(Icons.key_off_outlined),
                  title: Text('Add your editor key in Settings to save rates'),
                ),
              ),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Listing text',
                hintText: 'Share a listing to NelaBele, or paste its title, price and size here',
                border: OutlineInputBorder(),
              ),
              onChanged: _onTextChanged,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Found('Type', p.type == null ? null : propertyLabel(p.type!)),
                _Found('Price', p.price == null ? null : rupeesShort(p.price!)),
                _Found('Size', p.size == null ? null : '${_fmt(p.size!)} ${_unitLabels[p.sizeUnit]}'),
                _Found(
                  'Rate',
                  p.hasRate ? headline(p.type ?? 'plot', perSqft(p.rate!, p.rateUnit!)) : null,
                ),
              ],
            ),
            if (!p.hasRate) ...[
              const SizedBox(height: 8),
              Text(
                'No rate yet. Shared links often carry only a title: add the price and size '
                '(e.g. "₹85 L, 1200 sq ft") or the rate ("₹7,000/sq ft"), or fill it in on the next screen.',
                style: muted,
              ),
            ],
            const SizedBox(height: 20),
            Text('Which place is it?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _place,
              decoration: InputDecoration(
                hintText: 'Village or locality',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _scheduleSearch(),
            ),
            const SizedBox(height: 8),
            for (final a in _matches)
              Card.outlined(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(a.name),
                  subtitle: Text(a.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: key != null,
                  onTap: () => _use(a),
                ),
              ),
            if (!_searching && _matches.isEmpty && _place.text.trim().length >= 2)
              Text('No place matches. Try a nearby village or another spelling.', style: muted),
          ],
        ),
      ),
    );
  }
}

class _Found extends StatelessWidget {
  const _Found(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final found = value != null;
    return Chip(
      avatar: Icon(found ? Icons.check_circle : Icons.help_outline,
          size: 18, color: found ? scheme.primary : scheme.outline),
      label: Text(found ? '$label: $value' : '$label: not found'),
    );
  }
}
