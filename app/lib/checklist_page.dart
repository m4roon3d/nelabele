import 'i18n.dart';
import 'models.dart';
import 'ui.dart';

/// What to check before buying, by property type. Rules that change (khata,
/// land conversion) carry the date they were checked; the monthly refresh
/// does not update this page, so it says where to confirm.
class ChecklistPage extends StatelessWidget {
  const ChecklistPage({super.key, required this.type, this.district});

  final String type;
  final String? district;

  static const checkedOn = 'Nov 2026';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final city = district == 'Bangalore Urban';
    final sections = <(String, List<(String, String)>)>[
      ('Title and ownership (every property)', _common),
      ...switch (type) {
        'plot' => [
            if (city) ('Khata in Bengaluru (GBA)', _cityKhata) else ('Village property (gram panchayat)', _villageKhata),
            ('Layout and plot', _plot),
          ],
        'agricultural_land' => [('Farmland', _farmland), ('Converting it for building', _conversion)],
        'apartment' => [('The building and project', _apartment), if (city) ('Khata in Bengaluru (GBA)', _cityKhata)],
        'independent_house' => [
            if (city) ('Khata in Bengaluru (GBA)', _cityKhata) else ('Village property (gram panchayat)', _villageKhata),
            ('The house', _house),
          ],
        _ => const <(String, List<(String, String)>)>[],
      },
      ('Before you pay', _payment),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t('Checklist: buying a {type}', {'type': Lang.kannada ? propertyLabel(type) : propertyLabel(type).toLowerCase()}))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final (title, items) in sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            for (final (item, why) in items) _Item(item, why),
          ],
          const SizedBox(height: 20),
          Text(
            t('A general guide, checked {date}, not legal advice. Khata and land-conversion rules '
                'changed in 2025–26 and may change again: confirm with the sub-registrar, GBA (e-Aasthi), '
                'the gram panchayat or the planning authority, and have a property lawyer read the documents '
                'before you pay an advance.', {'date': checkedOn}),
            style: muted,
          ),
          const SizedBox(height: 8),
          Text(
            'Sources: Karnataka Land Revenue (Amendment) Rules, 2025 and the Urban Development '
            'circular of 18 Feb 2026 on conversion (via Cyril Amarchand Mangaldas, Nov 2026); GBA e-khata '
            'rules and the 2026 B-khata conversion window (NoBroker, updated Jun 2026); e-Swathu 2.0 '
            '(GKToday, Dec 2025).',
            style: muted,
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.item, this.why);

  final String item;
  final String why;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 10),
            child: Icon(Icons.check_box_outline_blank, size: 18, color: theme.colorScheme.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(why, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _common = [
  ('Sale deeds going back 30 years (the "chain")',
      'Each owner must have bought from the one before. Gaps, gifts or partitions need their own papers.'),
  ('Encumbrance certificate (EC) for the same 30 years',
      'From Kaveri Online. Shows mortgages and other sales registered on the property; it should be clear.'),
  ('Seller ID and every co-owner signing',
      'All legal heirs or co-owners named in the records must sign, or there is a dispute waiting.'),
  ('Guidance value for the registration',
      'Stamp duty and registration are paid on the higher of the price and the guidance value shown in this app.'),
];

const _cityKhata = [
  ('e-khata from GBA (e-Aasthi), in the seller\'s name',
      'Needed for registration in Bengaluru since Nov 2025. Check it on e-Aasthi with the ePID or property tax number.'),
  ('A-khata or B-khata?',
      'B-khata means approvals, layout or building issues are pending: harder to get a loan or resell. '
      'Conversion to A-khata costs a share of the guidance value (a reduced 2% window ran May–Aug 2026).'),
  ('Property tax paid up to date', 'Ask for the receipts; arrears pass to the buyer.'),
];

const _villageKhata = [
  ('e-Swathu Form 11A or 11B from the gram panchayat',
      'The digital khata for village properties (e-Swathu 2.0, Dec 2025). 11A is for approved layouts and '
      'converted land; 11B covers older or unapproved properties and is weaker.'),
  ('Form 9 / 11 matches the sale deed', 'Same survey number, extent and owner name.'),
];

const _plot = [
  ('Layout approval from BDA, BMRDA, BIAAPA or the local planning authority',
      'Ask for the approved layout plan and check this plot\'s number and size on it.'),
  ('Land conversion order for the layout land', 'The layout must stand on land converted for residential use (see farmland).'),
  ('RERA registration for new layouts', 'Check the project on the Karnataka RERA site; unregistered new layouts are a red flag.'),
  ('Road width and access', 'A plot on a public road wide enough for building permission; corner and wide-road plots cost more.'),
];

const _farmland = [
  ('RTC (Pahani) on Bhoomi in the seller\'s name', 'Shows owner, extent and crop; it should match the deed.'),
  ('Mutation register (MR) entries', 'How the land came to the seller: inheritance, partition or purchase.'),
  ('Survey sketch (11E / Tippan) and boundaries', 'Have the land measured; the extent on the ground often differs.'),
  ('Not government, inam or PTCL land',
      'Granted land (PTCL) and some inam land cannot be freely sold. Check the RTC remarks and with the tahsildar.'),
];

const _conversion = [
  ('Is the land inside an approved Master Plan?',
      'Inside one (rules of Dec 2025, circular of Feb 2026): no Deputy Commissioner (DC) order; conversion comes '
      'with the planning authority\'s layout approval, a Form 21B affidavit and a fee. Ask for the digital payment receipt.'),
  ('Outside a Master Plan: DC conversion (Form 21C)',
      'The DC must decide in 30 days, or it is deemed approved once the fee is paid. Ask for the order or proof of deemed approval.'),
  ('Land use matches what you plan to build', 'Check the Master Plan zoning; residential use on agricultural zoning won\'t pass.'),
];

const _apartment = [
  ('RERA registration and the RERA project page', 'Shows approvals, completion date and complaints. Check on the Karnataka RERA site.'),
  ('Occupancy certificate (OC) for a ready flat', 'Without an OC the flat can\'t get an A-khata, and many banks won\'t lend.'),
  ('Approved building plan matches the building', 'Extra floors or deviations beyond the plan can block the OC.'),
  ('Your share of the land (UDS)', 'The undivided share of land should be stated in the sale deed.'),
  ('Carpet area, not just super built-up', 'Prices are quoted on super built-up; carpet area is what you use, often 25–30% less.'),
];

const _house = [
  ('Approved building plan and completion or occupancy certificate', 'Floors built beyond the plan are a common B-khata cause.'),
  ('Electricity, water and sewer connections in the owner\'s name', 'BESCOM and BWSSB bills; transfer them after registration.'),
  ('A structural look by an engineer for older houses', 'Damp, cracks and wiring change what the building is worth.'),
];

const _payment = [
  ('A lawyer\'s title report before any advance', 'Costs a few thousand rupees and catches most problems.'),
  ('Advance by bank transfer, against a signed sale agreement', 'With a refund clause if the title doesn\'t clear.'),
  ('Loan sanction in hand, if you need one', 'A bank\'s legal check is a useful second opinion on the papers.'),
];
