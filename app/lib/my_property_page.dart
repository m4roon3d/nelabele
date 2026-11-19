import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'format.dart';
import 'i18n.dart';
import 'listing.dart';
import 'photo_store.dart';
import 'property_tax.dart';
import 'ui.dart';

/// Property you own: IDs, a link to pay tax on the official site, a record
/// of each year's payment with its receipt, a rebate reminder and a rough
/// estimate. Everything stays on this device.
class MyPropertyPage extends StatelessWidget {
  const MyPropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ValueListenableBuilder<List<OwnedProperty>>(
      valueListenable: OwnedProperties.all,
      builder: (context, list, _) {
        final now = DateTime.now();
        final fy = financialYear(now);
        final unpaidCity = list.where((p) => !p.village && p.paymentFor(fy) == null).toList();
        final rebateWindow = now.month == 4 || now.month == 5;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(context, null),
            icon: const Icon(Icons.add_home_outlined),
            label: Text(t('Add a property')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              if (rebateWindow && unpaidCity.isNotEmpty)
                Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(t('Pay this year\'s property tax for the 5% rebate')),
                    subtitle: Text(t('Paying the full year early earns 5% off. The cut-off is usually 30 April; for '
                        '2026-27 GBA extended it to 31 May. Check the date on the official site.')),
                  ),
                ),
              if (list.isEmpty) ...[
                const SizedBox(height: 48),
                Icon(Icons.home_work_outlined, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(t('Keep your property\'s tax details here'),
                    textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  t('Property ID, khata and ward, each year\'s payment with its receipt, a reminder for the '
                      'early-payment rebate and a rough tax estimate. Nothing leaves this device.'),
                  textAlign: TextAlign.center,
                  style: muted,
                ),
              ],
              for (final p in list) _PropertyCard(property: p, fy: fy),
              if (list.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  t('Tax is paid only on the official sites; NelaBele does not take payments or fetch your bill. '
                      'Details stay on this device.'),
                  style: muted,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<void> _edit(BuildContext context, OwnedProperty? p) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PropertyEditPage(property: p)),
    );

Future<void> _open(BuildContext context, String url) async {
  if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Could not open {url}', {'url': url}))));
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property, required this.fy});

  final OwnedProperty property;
  final int fy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final p = property;
    final paid = p.paymentFor(fy);
    final ids = [
      if (p.pid.isNotEmpty) ('PID', p.pid),
      if (p.epid.isNotEmpty) ('ePID', p.epid),
      if (p.sasNo.isNotEmpty) (t('SAS application no.'), p.sasNo),
      if (p.ward.isNotEmpty) (t('Ward'), p.ward),
    ];
    final est = p.village ? null : TaxEstimate.of(p);
    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.name.isEmpty ? t('My property') : p.name, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: t('Edit'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, p),
                ),
              ],
            ),
            Text(p.village ? t('Village property: tax goes to the gram panchayat') : t('Bengaluru (GBA) property'),
                style: muted),
            const SizedBox(height: 8),
            for (final (label, value) in ids)
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(t('{label} copied', {'label': label}))));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 150, child: Text(label, style: muted)),
                    Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
                    Icon(Icons.copy, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(paid != null ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20, color: paid != null ? theme.colorScheme.primary : theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paid != null
                        ? t('{fy}: paid {amount} on {date}',
                            {'fy': fyLabel(fy), 'amount': rupees(paid.amount), 'date': dayMonthYear(paid.paidOn)})
                        : t('{fy}: not recorded as paid', {'fy': fyLabel(fy)}),
                  ),
                ),
              ],
            ),
            if (paid == null && p.latest != null)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Text(
                  t('Last paid {amount} for {fy}. GBA has not changed the rates for 2026-27, so expect about the same.',
                      {'amount': rupees(p.latest!.amount), 'fy': fyLabel(p.latest!.fy)}),
                  style: muted,
                ),
              )
            else if (paid == null && est != null)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Text(t('Rough estimate: {amount} a year', {'amount': rupees(est.total)}), style: muted),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (!p.village)
                  FilledButton.tonalIcon(
                    onPressed: () => _open(context, gbaTaxUrl),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(t('Pay on the GBA site')),
                  ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PaymentsPage(propertyId: p.id),
                  )),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(t('Payments and receipts')),
                ),
                if (!p.village)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => TaxEstimatePage(propertyId: p.id),
                    )),
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: Text(t('Estimate')),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _open(
                    context,
                    yearlyReminderLink(
                      nextReminderDate(DateTime.now()),
                      t('Pay property tax: {name}', {'name': p.name.isEmpty ? t('My property') : p.name}),
                      p.village
                          ? t('Pay at the gram panchayat or a Bapuji Seva Kendra.')
                          : t('Pay the full year early for the 5% rebate: {url}', {'url': gbaTaxUrl}),
                    ).toString(),
                  ),
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(t('Yearly reminder')),
                ),
              ],
            ),
            if (p.village)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Text(
                  t('Village property tax is paid to the gram panchayat: at the panchayat office, a Bapuji Seva '
                      'Kendra, or online through the Bapuji Seva Kendra website or app (Panchatantra 2.0) where '
                      'your panchayat offers it. The khata itself is on e-Swathu.'),
                  style: muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Add or edit a property's details.
class PropertyEditPage extends StatefulWidget {
  const PropertyEditPage({super.key, this.property});

  final OwnedProperty? property;

  @override
  State<PropertyEditPage> createState() => _PropertyEditPageState();
}

class _PropertyEditPageState extends State<PropertyEditPage> {
  late final OwnedProperty _p = widget.property ??
      OwnedProperty(id: '${DateTime.now().microsecondsSinceEpoch}');
  late final _name = TextEditingController(text: _p.name);
  late final _pid = TextEditingController(text: _p.pid);
  late final _epid = TextEditingController(text: _p.epid);
  late final _sas = TextEditingController(text: _p.sasNo);
  late final _ward = TextEditingController(text: _p.ward);
  late final _notes = TextEditingController(text: _p.notes);
  late bool _village = _p.village;

  @override
  void dispose() {
    for (final c in [_name, _pid, _epid, _sas, _ward, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    _p
      ..name = _name.text.trim()
      ..pid = _pid.text.trim()
      ..epid = _epid.text.trim()
      ..sasNo = _sas.text.trim()
      ..ward = _ward.text.trim()
      ..notes = _notes.text.trim()
      ..village = _village;
    await OwnedProperties.put(_p);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Delete this property and its receipts?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('Delete'))),
        ],
      ),
    );
    if (ok != true) return;
    for (final pay in _p.payments) {
      if (pay.photo != null) await PhotoStore.remove(pay.photo!);
    }
    await OwnedProperties.remove(_p.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String label, {String? hint, String? helper, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          minLines: lines,
          maxLines: lines == 1 ? 1 : 6,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helper,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property == null ? t('Add a property') : t('Edit property')),
        actions: [
          if (widget.property != null)
            IconButton(tooltip: t('Delete'), icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_name, t('Name'), hint: t('e.g. Home in JP Nagar, site in Hoskote')),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(t('Bengaluru (GBA)'))),
              ButtonSegment(value: true, label: Text(t('Village (panchayat)'))),
            ],
            selected: {_village},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _village = s.first),
          ),
          const SizedBox(height: 16),
          if (!_village) ...[
            _field(_pid, t('Property ID (PID)'), hint: 'e.g. 54-12-301',
                helper: t('On last year\'s tax receipt or the GBA tax site')),
            _field(_epid, t('e-khata ePID'), helper: t('From e-Aasthi, if the property has an e-khata')),
            _field(_sas, t('SAS application no.'), helper: t('Printed on the self-assessment receipt')),
            _field(_ward, t('Ward')),
          ] else ...[
            _field(_pid, t('e-Swathu property no. or khata no.'), helper: t('On Form 9 / 11 or the panchayat receipt')),
            _field(_ward, t('Gram panchayat')),
          ],
          _field(_notes, t('Notes'), lines: 3),
          const SizedBox(height: 8),
          FilledButton(onPressed: _save, child: Text(t('Save'))),
          const SizedBox(height: 12),
          Text(t('Kept only on this device.'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Each year's payment and receipt.
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ValueListenableBuilder<List<OwnedProperty>>(
      valueListenable: OwnedProperties.all,
      builder: (context, list, _) {
        final p = list.where((x) => x.id == propertyId).firstOrNull;
        if (p == null) return const Scaffold();
        final payments = [...p.payments]..sort((a, b) => b.fy.compareTo(a.fy));
        return Scaffold(
          appBar: AppBar(title: Text(t('Payments: {name}', {'name': p.name.isEmpty ? t('My property') : p.name}))),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addPayment(context, p),
            icon: const Icon(Icons.add),
            label: Text(t('Record a payment')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t('Record each year\'s payment and add a photo of the receipt. Buyers and banks ask for '
                        'these receipts.'),
                    style: muted,
                  ),
                ),
              for (final pay in payments)
                Card.outlined(
                  child: ListTile(
                    leading: pay.photo == null
                        ? const Icon(Icons.receipt_long_outlined)
                        : _ReceiptThumb(id: pay.photo!),
                    title: Text('${fyLabel(pay.fy)} · ${rupees(pay.amount)}'),
                    subtitle: Text(t('Paid {date}', {'date': dayMonthYear(pay.paidOn)})),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'photo') await _attachPhoto(context, p, pay);
                        if (v == 'delete') {
                          if (pay.photo != null) await PhotoStore.remove(pay.photo!);
                          p.payments.remove(pay);
                          await OwnedProperties.put(p);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'photo', child: Text(pay.photo == null ? t('Add receipt photo') : t('Replace receipt photo'))),
                        PopupMenuItem(value: 'delete', child: Text(t('Delete'))),
                      ],
                    ),
                    onTap: pay.photo == null
                        ? () => _attachPhoto(context, p, pay)
                        : () async {
                            final bytes = await PhotoStore.read(pay.photo!);
                            if (bytes == null || !context.mounted) return;
                            Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  title: Text(fyLabel(pay.fy)),
                                ),
                                body: InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes))),
                              ),
                            ));
                          },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _attachPhoto(BuildContext context, OwnedProperty p, TaxPayment pay) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(t('Take a photo')),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(t('Choose from gallery')),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 70);
      if (file == null) return;
      final id = await PhotoStore.add(await file.readAsBytes());
      if (pay.photo != null) await PhotoStore.remove(pay.photo!);
      pay.photo = id;
      await OwnedProperties.put(p);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Could not add the photo.'))));
      }
    }
  }

  Future<void> _addPayment(BuildContext context, OwnedProperty p) async {
    final now = DateTime.now();
    var fy = financialYear(now);
    var date = now;
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t('Record a payment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<int>(
                value: fy,
                isExpanded: true,
                items: [
                  for (var y = financialYear(now); y >= financialYear(now) - 6; y--)
                    DropdownMenuItem(value: y, child: Text(fyLabel(y))),
                ],
                onChanged: (v) => setState(() => fy = v ?? fy),
              ),
              TextField(
                controller: amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t('Amount paid'), prefixText: '₹ '),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(now.year - 7),
                    lastDate: now,
                  );
                  if (d != null) setState(() => date = d);
                },
                icon: const Icon(Icons.event, size: 18),
                label: Text(t('Paid {date}', {'date': dayMonthYear(date)})),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('Save'))),
          ],
        ),
      ),
    );
    final value = parseMoney(amount.text);
    amount.dispose();
    if (ok != true || value == null || value <= 0) return;
    p.payments.removeWhere((x) => x.fy == fy);
    p.payments.add(TaxPayment(fy: fy, amount: value, paidOn: date));
    await OwnedProperties.put(p);
  }
}

class _ReceiptThumb extends StatelessWidget {
  const _ReceiptThumb({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
        future: PhotoStore.read(id),
        builder: (context, snap) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 44,
            height: 44,
            child: snap.data == null
                ? const Icon(Icons.receipt_long_outlined)
                : Image.memory(snap.data!, fit: BoxFit.cover, cacheWidth: 120),
          ),
        ),
      );
}

/// A rough yearly tax from the self-assessment formula.
class TaxEstimatePage extends StatefulWidget {
  const TaxEstimatePage({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<TaxEstimatePage> createState() => _TaxEstimatePageState();
}

class _TaxEstimatePageState extends State<TaxEstimatePage> {
  late final OwnedProperty _p = OwnedProperties.all.value.firstWhere((x) => x.id == widget.propertyId);
  late final _area = TextEditingController(text: _p.builtUp == null ? '' : fmtInt(_p.builtUp!).replaceAll(',', ''));
  late final _year = TextEditingController(text: _p.yearBuilt?.toString() ?? '');

  @override
  void dispose() {
    _area.dispose();
    _year.dispose();
    super.dispose();
  }

  void _changed() {
    _p
      ..builtUp = double.tryParse(_area.text.replaceAll(',', '').trim())
      ..yearBuilt = int.tryParse(_year.text.trim());
    OwnedProperties.put(_p);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final est = TaxEstimate.of(_p);
    return Scaffold(
      appBar: AppBar(title: Text(t('Property tax estimate'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('Value zone'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final z in residentialUav.keys)
                ChoiceChip(
                  label: Text(z),
                  selected: _p.zone == z,
                  onSelected: (_) {
                    _p.zone = z;
                    _changed();
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t('GBA puts every street in a zone, A (highest value) to F, by its guidance value. The zone is on '
                'your last self-assessment form or the property\'s page on the GBA tax site.'),
            style: muted,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(t('You live in it'))),
              ButtonSegment(value: true, label: Text(t('Rented out'))),
            ],
            selected: {_p.tenanted},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              _p.tenanted = s.first;
              _changed();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _area,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t('Built-up area (sq ft)'),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t('Year built'), border: const OutlineInputBorder()),
                  onChanged: (_) => _changed(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (est == null)
            Text(t('Pick the zone and enter the built-up area.'), style: muted)
          else
            Card.outlined(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('About {amount} a year', {'amount': rupees(est.total)}),
                        style: theme.textTheme.headlineSmall),
                    Text(t('{amount} if you pay the full year early (5% rebate)',
                        {'amount': rupees(est.total - est.rebate)}), style: muted),
                    const Divider(height: 24),
                    _Row(t('Annual value (area × rate × 10 months)'), rupees(est.gross)),
                    _Row(t('Less {pct}% for age', {'pct': est.depreciationPct.toStringAsFixed(0)}),
                        '−${rupees(est.gross * est.depreciationPct / 100)}'),
                    _Row(t('Tax (20%)'), rupees(est.tax)),
                    _Row(t('Cess (24% of tax)'), rupees(est.cess)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            t('A rough guide for homes only, from the self-assessment formula and its published zone rates '
                '(₹{a} to ₹{f} a sq ft a month for zones A to F, double if rented out). The bill on the GBA site '
                'can differ: it limits rises since the 2016 revision, adds the garbage (SWM) fee and charges '
                'shops, offices and empty land differently. Last year\'s receipt is the better guide.',
                {'a': residentialUav['A']!.toStringAsFixed(2), 'f': residentialUav['F']!.toStringAsFixed(2)}),
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}
