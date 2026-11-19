/// Kannada for the interface text, keyed by the English. Place names, data
/// sources and the editor-only bulk import format stay in English.
library;

const kn = <String, String>{
  // Navigation and common
  'List': 'ಪಟ್ಟಿ',
  'Map': 'ನಕ್ಷೆ',
  'Saved': 'ಉಳಿಸಿದವು',
  'Settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
  'Try again': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
  'Retry': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
  'Clear': 'ಅಳಿಸಿ',
  'Show all': 'ಎಲ್ಲವನ್ನೂ ತೋರಿಸಿ',
  'Save': 'ಉಳಿಸಿ',
  'Cancel': 'ರದ್ದುಮಾಡಿ',
  'Delete': 'ಅಳಿಸಿ',
  'Add': 'ಸೇರಿಸಿ',
  'Change': 'ಬದಲಿಸಿ',
  'Adjust': 'ಹೊಂದಿಸಿ',
  'Check': 'ಪರಿಶೀಲಿಸಿ',
  'Got it': 'ಸರಿ',
  'Compare': 'ಹೋಲಿಸಿ',
  'Compare {n} places': '{n} ಸ್ಥಳಗಳನ್ನು ಹೋಲಿಸಿ',
  'Total': 'ಒಟ್ಟು',

  // Property types and levels
  'Plot': 'ನಿವೇಶನ',
  'Farmland': 'ಕೃಷಿ ಭೂಮಿ',
  'House': 'ಮನೆ',
  'Apartment': 'ಅಪಾರ್ಟ್‌ಮೆಂಟ್',
  'Village': 'ಗ್ರಾಮ',
  'Locality': 'ಬಡಾವಣೆ',
  'Ward': 'ವಾರ್ಡ್',
  'Zone': 'ವಲಯ',
  'Hobli': 'ಹೋಬಳಿ',
  'Taluk': 'ತಾಲ್ಲೂಕು',
  'District': 'ಜಿಲ್ಲೆ',
  '{place} area': '{place} ಪ್ರದೇಶ',
  '{place} taluk': '{place} ತಾಲ್ಲೂಕು',

  // Units
  'sq ft': 'ಚ.ಅಡಿ',
  'sq m': 'ಚ.ಮೀ',
  'sq m (super built-up)': 'ಚ.ಮೀ (ಸೂಪರ್ ಬಿಲ್ಟ್-ಅಪ್)',
  'sq yard': 'ಚ.ಗಜ',
  'sq yd': 'ಚ.ಗಜ',
  'acre': 'ಎಕರೆ',
  'guntha': 'ಗುಂಟೆ',
  'per sq ft': 'ಪ್ರತಿ ಚ.ಅಡಿ',
  'per sq m': 'ಪ್ರತಿ ಚ.ಮೀ',
  'per sq yard': 'ಪ್ರತಿ ಚ.ಗಜ',
  'per guntha': 'ಪ್ರತಿ ಗುಂಟೆ',
  'per acre': 'ಪ್ರತಿ ಎಕರೆ',
  '1,000 sq ft': '1,000 ಚ.ಅಡಿ',
  '1,250 sq ft': '1,250 ಚ.ಅಡಿ',
  '1,600 sq ft': '1,600 ಚ.ಅಡಿ',
  '10 guntha': '10 ಗುಂಟೆ',
  '20 guntha': '20 ಗುಂಟೆ',
  '1 acre': '1 ಎಕರೆ',
  '2 acres': '2 ಎಕರೆ',
  '{price} for a 30×40 site': '30×40 ನಿವೇಶನಕ್ಕೆ {price}',
  'years': 'ವರ್ಷ',
  'a month': 'ತಿಂಗಳಿಗೆ',

  // Header and list
  'Places near me': 'ನನ್ನ ಹತ್ತಿರದ ಸ್ಥಳಗಳು',
  'Places near you': 'ನಿಮ್ಮ ಹತ್ತಿರದ ಸ್ಥಳಗಳು',
  'All areas': 'ಎಲ್ಲ ಪ್ರದೇಶಗಳು',
  'Urban': 'ನಗರ',
  'Rural': 'ಗ್ರಾಮಾಂತರ',
  'Ramanagara': 'ರಾಮನಗರ',
  'Tumakuru': 'ತುಮಕೂರು',
  'Kolar': 'ಕೋಲಾರ',
  'Chikkaballapura': 'ಚಿಕ್ಕಬಳ್ಳಾಪುರ',
  'All types': 'ಎಲ್ಲ ಬಗೆ',
  'All places in {place} area': '{place} ಪ್ರದೇಶದ ಎಲ್ಲ ಸ್ಥಳಗಳು',
  'Along {place}': '{place} ಉದ್ದಕ್ಕೂ',
  'Near {place}': '{place} ಹತ್ತಿರ',
  '{n} places': '{n} ಸ್ಥಳಗಳು',
  '{d} away': '{d} ದೂರ',
  'No places match. Try another spelling or a nearby place.':
      'ಯಾವ ಸ್ಥಳವೂ ಹೊಂದುತ್ತಿಲ್ಲ. ಬೇರೆ ಕಾಗುಣಿತ ಅಥವಾ ಹತ್ತಿರದ ಸ್ಥಳವನ್ನು ಪ್ರಯತ್ನಿಸಿ.',
  'Distances are to the middle of each place. Place names nearby come from OpenStreetMap.':
      'ದೂರವನ್ನು ಪ್ರತಿ ಸ್ಥಳದ ಮಧ್ಯಭಾಗಕ್ಕೆ ಅಳೆಯಲಾಗಿದೆ. ಹತ್ತಿರದ ಸ್ಥಳಗಳ ಹೆಸರುಗಳು OpenStreetMap ನಿಂದ.',
  'Showing the first {n} places. Search to narrow down.': 'ಮೊದಲ {n} ಸ್ಥಳಗಳನ್ನು ತೋರಿಸಲಾಗಿದೆ. ಹುಡುಕಿ ಕಿರಿದುಗೊಳಿಸಿ.',
  'Government guidance values. Market prices are usually higher.':
      'ಸರ್ಕಾರಿ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯಗಳು. ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು ಸಾಮಾನ್ಯವಾಗಿ ಹೆಚ್ಚು.',
  'market {x}×': 'ಮಾರುಕಟ್ಟೆ {x}×',
  'est. ~{rate}': 'ಅಂದಾಜು ~{rate}',
  'You seem to be outside Bengaluru and nearby districts, which NelaBele covers.':
      'ನೀವು ನೆಲಬೆಲೆ ಒಳಗೊಳ್ಳುವ ಬೆಂಗಳೂರು ಮತ್ತು ಹತ್ತಿರದ ಜಿಲ್ಲೆಗಳ ಹೊರಗಿರುವಂತಿದೆ.',
  'You seem to be outside the area NelaBele covers.': 'ನೀವು ನೆಲಬೆಲೆ ಒಳಗೊಳ್ಳುವ ಪ್ರದೇಶದ ಹೊರಗಿರುವಂತಿದೆ.',
  'Turn on location to see places near you.': 'ಹತ್ತಿರದ ಸ್ಥಳಗಳನ್ನು ನೋಡಲು ಲೊಕೇಶನ್ ಆನ್ ಮಾಡಿ.',
  'NelaBele needs location permission to find places near you.':
      'ಹತ್ತಿರದ ಸ್ಥಳಗಳನ್ನು ಹುಡುಕಲು ನೆಲಬೆಲೆಗೆ ಲೊಕೇಶನ್ ಅನುಮತಿ ಬೇಕು.',
  'Location is blocked for NelaBele. Allow it in your phone settings.':
      'ನೆಲಬೆಲೆಗೆ ಲೊಕೇಶನ್ ತಡೆಹಿಡಿಯಲಾಗಿದೆ. ಫೋನ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಅನುಮತಿಸಿ.',
  "Couldn't get your location. Try again outdoors or with Wi-Fi on.":
      'ನಿಮ್ಮ ಲೊಕೇಶನ್ ಸಿಗಲಿಲ್ಲ. ಹೊರಗೆ ಅಥವಾ ವೈ-ಫೈ ಆನ್ ಮಾಡಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',

  // Place sheet and rate card
  'Your notes and documents': 'ನಿಮ್ಮ ಟಿಪ್ಪಣಿಗಳು ಮತ್ತು ದಾಖಲೆಗಳು',
  'Share this place': 'ಈ ಸ್ಥಳವನ್ನು ಹಂಚಿಕೊಳ್ಳಿ',
  'Remove from saved': 'ಉಳಿಸಿದವುಗಳಿಂದ ತೆಗೆಯಿರಿ',
  'Save this place': 'ಈ ಸ್ಥಳವನ್ನು ಉಳಿಸಿ',
  'NelaBele, indicative rates': 'ನೆಲಬೆಲೆ, ಅಂದಾಜು ದರಗಳು',
  'property rates': 'ಆಸ್ತಿ ದರಗಳು',
  'guidance': 'ಮಾರ್ಗಸೂಚಿ',
  'market': 'ಮಾರುಕಟ್ಟೆ',
  'est. market': 'ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ',
  'est.': 'ಅಂದಾಜು',
  'Govt guidance value': 'ಸರ್ಕಾರಿ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯ',
  'Guidance value': 'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯ',
  'guidance value': 'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯ',
  'Guidance': 'ಮಾರ್ಗಸೂಚಿ',
  'Market': 'ಮಾರುಕಟ್ಟೆ',
  'from {date}': '{date} ರಿಂದ',
  '{change} from {rate} ({date})': '{rate} ({date}) ಇಂದ {change}',
  'No guidance value for this type': 'ಈ ಬಗೆಗೆ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯ ಇಲ್ಲ',
  'Market range': 'ಮಾರುಕಟ್ಟೆ ಶ್ರೇಣಿ',
  'Estimated market': 'ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ',
  'Estimated market range': 'ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ ಶ್ರೇಣಿ',
  '1 data point': '1 ದತ್ತಾಂಶ',
  '{n} data points': '{n} ದತ್ತಾಂಶಗಳು',
  '{level} confidence': '{level} ವಿಶ್ವಾಸ',
  'low': 'ಕಡಿಮೆ',
  'medium': 'ಮಧ್ಯಮ',
  'high': 'ಹೆಚ್ಚು',
  'includes published prices (reports, auction reserves, listing averages)':
      'ಪ್ರಕಟಿತ ಬೆಲೆಗಳು ಸೇರಿವೆ (ವರದಿಗಳು, ಹರಾಜು ಮೀಸಲು ಬೆಲೆ, ಜಾಹೀರಾತು ಸರಾಸರಿ)',
  'Market is about {x}× the guidance value': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯದ ಸುಮಾರು {x}×',
  'Estimate, not data: about {x}× guidance, the ratio seen in {n} areas with published prices. '
          'Log or share a listing to replace it.':
      'ಇದು ಅಂದಾಜು, ದತ್ತಾಂಶವಲ್ಲ: ಪ್ರಕಟಿತ ಬೆಲೆಗಳಿರುವ {n} ಪ್ರದೇಶಗಳಲ್ಲಿ ಕಂಡ ಅನುಪಾತದಂತೆ ಮಾರ್ಗಸೂಚಿಯ ಸುಮಾರು {x}×. '
          'ಇದನ್ನು ಬದಲಿಸಲು ಒಂದು ಜಾಹೀರಾತನ್ನು ದಾಖಲಿಸಿ ಅಥವಾ ಹಂಚಿಕೊಳ್ಳಿ.',
  'several': 'ಹಲವು',
  'Market range: no data or estimate yet': 'ಮಾರುಕಟ್ಟೆ ಶ್ರೇಣಿ: ಇನ್ನೂ ದತ್ತಾಂಶ ಅಥವಾ ಅಂದಾಜು ಇಲ್ಲ',
  'Typical rent: {rent}/sq ft a month': 'ಸಾಮಾನ್ಯ ಬಾಡಿಗೆ: ತಿಂಗಳಿಗೆ {rent}/ಚ.ಅಡಿ',
  'about {pct}% gross yield': 'ಸುಮಾರು {pct}% ಒಟ್ಟು ಆದಾಯ',
  'Is this price fair?': 'ಈ ಬೆಲೆ ನ್ಯಾಯವೇ?',
  'Total cost with registration': 'ನೋಂದಣಿ ಸಹಿತ ಒಟ್ಟು ವೆಚ್ಚ',
  'Value a house on this plot': 'ಈ ನಿವೇಶನದ ಮನೆಯ ಮೌಲ್ಯ',
  'Home loan and EMI': 'ಗೃಹ ಸಾಲ ಮತ್ತು ಇಎಂಐ',
  "Buyer's checklist": 'ಖರೀದಿದಾರರ ಪರಿಶೀಲನಾ ಪಟ್ಟಿ',
  'Log a market rate': 'ಮಾರುಕಟ್ಟೆ ದರ ದಾಖಲಿಸಿ',
  '{city} homes: {pct}% in a year': '{city} ಮನೆಗಳು: ಒಂದು ವರ್ಷದಲ್ಲಿ {pct}%',
  'Guidance values have not changed since Oct 2023.': 'ಅಕ್ಟೋಬರ್ 2023 ರಿಂದ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯಗಳು ಬದಲಾಗಿಲ್ಲ.',
  'metro': 'ಮೆಟ್ರೋ',
  'planned': 'ಯೋಜಿತ',
  'straight line': 'ನೇರ ದೂರ',
  'Price history': 'ಬೆಲೆ ಇತಿಹಾಸ',
  '{n} prices from {date}, {low} – {high}': '{date} ರ {n} ಬೆಲೆಗಳು, {low} – {high}',
  '{n} prices': '{n} ಬೆಲೆಗಳು',
  'dashed: guidance': 'ಗೆರೆ ಚುಕ್ಕೆ: ಮಾರ್ಗಸೂಚಿ',
  'Indicative only. Guidance values are the government minimum used for registration; actual market prices are '
          'usually higher and vary with khata, approvals, road access and plot size.':
      'ಕೇವಲ ಅಂದಾಜು. ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯಗಳು ನೋಂದಣಿಗೆ ಬಳಸುವ ಸರ್ಕಾರಿ ಕನಿಷ್ಠ ಮೌಲ್ಯ; ನಿಜವಾದ ಮಾರುಕಟ್ಟೆ ಬೆಲೆ ಸಾಮಾನ್ಯವಾಗಿ '
          'ಹೆಚ್ಚು ಮತ್ತು ಖಾತೆ, ಅನುಮೋದನೆ, ರಸ್ತೆ ಸಂಪರ್ಕ ಹಾಗೂ ನಿವೇಶನದ ಅಳತೆಯ ಮೇಲೆ ಬದಲಾಗುತ್ತದೆ.',

  // Map
  'Metro & roads': 'ಮೆಟ್ರೋ ಮತ್ತು ರಸ್ತೆಗಳು',
  'Metro': 'ಮೆಟ್ರೋ',
  'Ring roads': 'ವರ್ತುಲ ರಸ್ತೆಗಳು',
  'building': 'ನಿರ್ಮಾಣದಲ್ಲಿ',
  'Show where I am': 'ನಾನಿರುವ ಸ್ಥಳ ತೋರಿಸಿ',
  'under {rate}': '{rate} ಕ್ಕಿಂತ ಕಡಿಮೆ',
  'over {rate}': '{rate} ಕ್ಕಿಂತ ಹೆಚ್ಚು',
  'market (incl. estimates)': 'ಮಾರುಕಟ್ಟೆ (ಅಂದಾಜು ಸೇರಿ)',
  'no market figure yet': 'ಇನ್ನೂ ಮಾರುಕಟ್ಟೆ ಅಂಕಿ ಇಲ್ಲ',

  // Saved and compare
  'No saved places yet. Tap the star on a place to keep it here and compare.':
      'ಇನ್ನೂ ಉಳಿಸಿದ ಸ್ಥಳಗಳಿಲ್ಲ. ಸ್ಥಳದ ನಕ್ಷತ್ರ ಒತ್ತಿ ಇಲ್ಲಿ ಉಳಿಸಿ ಮತ್ತು ಹೋಲಿಸಿ.',
  "What's changed for your saved places": 'ನಿಮ್ಮ ಉಳಿಸಿದ ಸ್ಥಳಗಳಲ್ಲಿ ಏನು ಬದಲಾಗಿದೆ',
  "What's changed since {date}": '{date} ರಿಂದ ಏನು ಬದಲಾಗಿದೆ',
  '{type}: guidance {from} → {to} ({change})': '{type}: ಮಾರ್ಗಸೂಚಿ {from} → {to} ({change})',
  '{type}: market range now {range}': '{type}: ಈಗ ಮಾರುಕಟ್ಟೆ ಶ್ರೇಣಿ {range}',
  '{type}: market middle {from} → {to} ({change})': '{type}: ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆ {from} → {to} ({change})',
  '{type}: 1 new market price': '{type}: 1 ಹೊಸ ಮಾರುಕಟ್ಟೆ ಬೆಲೆ',
  '{type}: {n} new market prices': '{type}: {n} ಹೊಸ ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು',
  'and {n} more': 'ಮತ್ತು ಇನ್ನೂ {n}',
  'Guidance values revised': 'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯಗಳು ಪರಿಷ್ಕೃತ',
  'Guidance values revised from {date}': '{date} ರಿಂದ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯಗಳು ಪರಿಷ್ಕೃತ',
  'Your saved places': 'ನಿಮ್ಮ ಉಳಿಸಿದ ಸ್ಥಳಗಳು',
  'Pick two or three to compare': 'ಹೋಲಿಸಲು ಎರಡು ಅಥವಾ ಮೂರು ಆಯ್ಕೆಮಾಡಿ',
  'Revision': 'ಪರಿಷ್ಕರಣೆ',
  '{change} since {date}': '{date} ರಿಂದ {change}',
  'no data yet': 'ಇನ್ನೂ ದತ್ತಾಂಶ ಇಲ್ಲ',
  'Market ÷ guidance': 'ಮಾರುಕಟ್ಟೆ ÷ ಮಾರ್ಗಸೂಚಿ',
  '30×40 site': '30×40 ನಿವೇಶನ',
  'Per guntha': 'ಪ್ರತಿ ಗುಂಟೆ',
  'Guidance values are the government minimum (Oct 2023). Market ranges come from published reports and rates you '
          'log; "est." ranges are estimates from guidance.':
      'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯಗಳು ಸರ್ಕಾರಿ ಕನಿಷ್ಠ (ಅಕ್ಟೋಬರ್ 2023). ಮಾರುಕಟ್ಟೆ ಶ್ರೇಣಿಗಳು ಪ್ರಕಟಿತ ವರದಿಗಳು ಮತ್ತು ನೀವು ದಾಖಲಿಸಿದ '
          'ದರಗಳಿಂದ; "ಅಂದಾಜು" ಶ್ರೇಣಿಗಳನ್ನು ಮಾರ್ಗಸೂಚಿಯಿಂದ ಲೆಕ್ಕಹಾಕಲಾಗಿದೆ.',

  // Notes
  'Notes: {place}': 'ಟಿಪ್ಪಣಿಗಳು: {place}',
  'Notes': 'ಟಿಪ್ಪಣಿಗಳು',
  'Kept only on this device. Nothing here is uploaded or shared, and it is lost if you uninstall the app or clear '
          "the browser's data.":
      'ಈ ಸಾಧನದಲ್ಲಿ ಮಾತ್ರ ಇರುತ್ತದೆ. ಇಲ್ಲಿಯದೇನೂ ಅಪ್‌ಲೋಡ್ ಅಥವಾ ಹಂಚಿಕೆ ಆಗುವುದಿಲ್ಲ; ಆ್ಯಪ್ ತೆಗೆದರೆ ಅಥವಾ ಬ್ರೌಸರ್ ದತ್ತಾಂಶ '
          'ಅಳಿಸಿದರೆ ಇದು ಕಳೆದುಹೋಗುತ್ತದೆ.',
  'Asking price, plot number, road width, what the seller said…':
      'ಕೇಳುತ್ತಿರುವ ಬೆಲೆ, ನಿವೇಶನ ಸಂಖ್ಯೆ, ರಸ್ತೆ ಅಗಲ, ಮಾರಾಟಗಾರರು ಹೇಳಿದ್ದು…',
  'Saved {date}': '{date} ರಂದು ಉಳಿಸಲಾಗಿದೆ',
  'Contacts': 'ಸಂಪರ್ಕಗಳು',
  'Add a contact': 'ಸಂಪರ್ಕ ಸೇರಿಸಿ',
  'Edit contact': 'ಸಂಪರ್ಕ ತಿದ್ದಿ',
  'Name': 'ಹೆಸರು',
  'Who they are': 'ಅವರು ಯಾರು',
  'Seller, broker, lawyer…': 'ಮಾರಾಟಗಾರ, ದಲ್ಲಾಳಿ, ವಕೀಲ…',
  'Phone': 'ಫೋನ್',
  'Call': 'ಕರೆ ಮಾಡಿ',
  'Seller, broker or lawyer for this place.': 'ಈ ಸ್ಥಳದ ಮಾರಾಟಗಾರ, ದಲ್ಲಾಳಿ ಅಥವಾ ವಕೀಲ.',
  'Document photos': 'ದಾಖಲೆಗಳ ಫೋಟೋಗಳು',
  'Take a photo': 'ಫೋಟೋ ತೆಗೆಯಿರಿ',
  'Choose from gallery': 'ಗ್ಯಾಲರಿಯಿಂದ ಆಯ್ಕೆಮಾಡಿ',
  'Photos of the sale deed, EC, khata or RTC, to check later or show a lawyer.':
      'ನಂತರ ಪರಿಶೀಲಿಸಲು ಅಥವಾ ವಕೀಲರಿಗೆ ತೋರಿಸಲು ಕ್ರಯಪತ್ರ, ಇಸಿ, ಖಾತೆ ಅಥವಾ ಆರ್‌ಟಿಸಿ ಫೋಟೋಗಳು.',
  'Delete this photo?': 'ಈ ಫೋಟೋ ಅಳಿಸಬೇಕೇ?',
  'What is this document?': 'ಇದು ಯಾವ ದಾಖಲೆ?',
  'e.g. Sale deed, EC, khata, RTC': 'ಉದಾ. ಕ್ರಯಪತ್ರ, ಇಸಿ, ಖಾತೆ, ಆರ್‌ಟಿಸಿ',
  'Name this document': 'ಈ ದಾಖಲೆಗೆ ಹೆಸರಿಡಿ',
  'Could not add the photo.': 'ಫೋಟೋ ಸೇರಿಸಲಾಗಲಿಲ್ಲ.',
  "Could not keep the photo: the browser's storage may be full. The Android app has more room.":
      'ಫೋಟೋ ಉಳಿಸಲಾಗಲಿಲ್ಲ: ಬ್ರೌಸರ್ ಸಂಗ್ರಹ ತುಂಬಿರಬಹುದು. ಆಂಡ್ರಾಯ್ಡ್ ಆ್ಯಪ್‌ನಲ್ಲಿ ಹೆಚ್ಚು ಜಾಗವಿದೆ.',

  // Settings
  'Appearance': 'ನೋಟ',
  'Light': 'ಬೆಳಕು',
  'Dark': 'ಕತ್ತಲು',
  'Language': 'ಭಾಷೆ',
  'Place names stay as in the government records.': 'ಸ್ಥಳಗಳ ಹೆಸರುಗಳು ಸರ್ಕಾರಿ ದಾಖಲೆಗಳಲ್ಲಿರುವಂತೆಯೇ ಇರುತ್ತವೆ.',
  'Editor key': 'ಸಂಪಾದಕ ಕೀ',
  'With an editor key you can log market rates you come across. Keep it private: anyone with it can add rates.':
      'ಸಂಪಾದಕ ಕೀ ಇದ್ದರೆ ನೀವು ಕಂಡ ಮಾರುಕಟ್ಟೆ ದರಗಳನ್ನು ದಾಖಲಿಸಬಹುದು. ಇದನ್ನು ಗೋಪ್ಯವಾಗಿಡಿ: ಇದಿರುವ ಯಾರಾದರೂ ದರ ಸೇರಿಸಬಹುದು.',
  'Editor key saved on this device': 'ಸಂಪಾದಕ ಕೀ ಈ ಸಾಧನದಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ',
  'Editor key saved': 'ಸಂಪಾದಕ ಕೀ ಉಳಿಸಲಾಗಿದೆ',
  'Remove key': 'ಕೀ ತೆಗೆಯಿರಿ',
  'Paste your editor key': 'ನಿಮ್ಮ ಸಂಪಾದಕ ಕೀ ಅಂಟಿಸಿ',
  'Save key': 'ಕೀ ಉಳಿಸಿ',
  "That doesn't look like an editor key. Paste the whole key.": 'ಇದು ಸಂಪಾದಕ ಕೀ ಎಂದು ತೋರುತ್ತಿಲ್ಲ. ಪೂರ್ತಿ ಕೀ ಅಂಟಿಸಿ.',
  'Add market rates': 'ಮಾರುಕಟ್ಟೆ ದರಗಳನ್ನು ಸೇರಿಸಿ',
  'On Android you can also share a listing from 99acres, MagicBricks, Housing or any app straight to NelaBele.':
      'ಆಂಡ್ರಾಯ್ಡ್‌ನಲ್ಲಿ 99acres, MagicBricks, Housing ಅಥವಾ ಯಾವುದೇ ಆ್ಯಪ್‌ನಿಂದ ಜಾಹೀರಾತನ್ನು ನೇರವಾಗಿ ನೆಲಬೆಲೆಗೆ ಹಂಚಿಕೊಳ್ಳಬಹುದು.',
  'From a listing': 'ಜಾಹೀರಾತಿನಿಂದ',
  'Paste a listing’s text; NelaBele reads the price and size': 'ಜಾಹೀರಾತಿನ ಪಠ್ಯ ಅಂಟಿಸಿ; ನೆಲಬೆಲೆ ಬೆಲೆ ಮತ್ತು ಅಳತೆ ಓದುತ್ತದೆ',
  'Bulk import': 'ಒಮ್ಮೆಲೇ ಆಮದು',
  'Paste many rates, one per line': 'ಸಾಲಿಗೊಂದರಂತೆ ಹಲವು ದರಗಳನ್ನು ಅಂಟಿಸಿ',

  // Fair price
  '{type} in {place}': '{place} ನಲ್ಲಿ {type}',
  'Asking price': 'ಕೇಳುತ್ತಿರುವ ಬೆಲೆ',
  'e.g. 1.2 cr, 85 L, 45,00,000': 'ಉದಾ. 1.2 cr, 85 L, 45,00,000',
  'Size': 'ಅಳತೆ',
  'Super built-up area': 'ಸೂಪರ್ ಬಿಲ್ಟ್-ಅಪ್ ವಿಸ್ತೀರ್ಣ',
  'Enter the asking price and the size.': 'ಕೇಳುತ್ತಿರುವ ಬೆಲೆ ಮತ್ತು ಅಳತೆ ನಮೂದಿಸಿ.',
  '{rate} asked': '{rate} ಕೇಳಲಾಗಿದೆ',
  '{x}× guidance': 'ಮಾರ್ಗಸೂಚಿಯ {x}×',
  'an estimate, not data': 'ಅಂದಾಜು, ದತ್ತಾಂಶವಲ್ಲ',
  'Registration value (guidance)': 'ನೋಂದಣಿ ಮೌಲ್ಯ (ಮಾರ್ಗಸೂಚಿ)',
  'stamp duty is on the higher of this and the price': 'ಇದು ಮತ್ತು ಬೆಲೆಯಲ್ಲಿ ಹೆಚ್ಚಿನದರ ಮೇಲೆ ಮುದ್ರಾಂಕ ಶುಲ್ಕ',
  'Rental yield': 'ಬಾಡಿಗೆ ಆದಾಯ',
  'Expected rent a month': 'ನಿರೀಕ್ಷಿತ ತಿಂಗಳ ಬಾಡಿಗೆ',
  'typical here: {rent}': 'ಇಲ್ಲಿ ಸಾಮಾನ್ಯ: {rent}',
  'e.g. 35,000': 'ಉದಾ. 35,000',
  'Gross yield {pct}% a year': 'ವರ್ಷಕ್ಕೆ {pct}% ಒಟ್ಟು ಆದಾಯ',
  'Gross yield {pct}% a year at the typical rent here': 'ಇಲ್ಲಿನ ಸಾಮಾನ್ಯ ಬಾಡಿಗೆಯಲ್ಲಿ ವರ್ಷಕ್ಕೆ {pct}% ಒಟ್ಟು ಆದಾಯ',
  'Bengaluru flats usually yield 3–4.5% gross.': 'ಬೆಂಗಳೂರಿನ ಫ್ಲ್ಯಾಟ್‌ಗಳು ಸಾಮಾನ್ಯವಾಗಿ 3–4.5% ಒಟ್ಟು ಆದಾಯ ನೀಡುತ್ತವೆ.',
  'Bengaluru flats usually yield 3–4.5% gross, before maintenance, tax and vacancy.':
      'ಬೆಂಗಳೂರಿನ ಫ್ಲ್ಯಾಟ್‌ಗಳು ಸಾಮಾನ್ಯವಾಗಿ 3–4.5% ಒಟ್ಟು ಆದಾಯ ನೀಡುತ್ತವೆ, ನಿರ್ವಹಣೆ, ತೆರಿಗೆ ಮತ್ತು ಖಾಲಿ ಅವಧಿಗೆ ಮುನ್ನ.',
  'No market range here yet, so only the guidance comparison below is possible.':
      'ಇಲ್ಲಿ ಇನ್ನೂ ಮಾರುಕಟ್ಟೆ ಶ್ರೇಣಿ ಇಲ್ಲ, ಆದ್ದರಿಂದ ಕೆಳಗಿನ ಮಾರ್ಗಸೂಚಿ ಹೋಲಿಕೆ ಮಾತ್ರ ಸಾಧ್ಯ.',
  'Well below the range: check khata, approvals and title closely':
      'ಶ್ರೇಣಿಗಿಂತ ತುಂಬಾ ಕಡಿಮೆ: ಖಾತೆ, ಅನುಮೋದನೆ ಮತ್ತು ಹಕ್ಕುಪತ್ರವನ್ನು ಸೂಕ್ಷ್ಮವಾಗಿ ಪರಿಶೀಲಿಸಿ',
  'Below the range: a good price if the papers are clean': 'ಶ್ರೇಣಿಗಿಂತ ಕಡಿಮೆ: ದಾಖಲೆಗಳು ಸರಿಯಿದ್ದರೆ ಒಳ್ಳೆಯ ಬೆಲೆ',
  'Within the range': 'ಶ್ರೇಣಿಯೊಳಗೆ',
  'A little above the range: room to negotiate': 'ಶ್ರೇಣಿಗಿಂತ ಸ್ವಲ್ಪ ಹೆಚ್ಚು: ಚೌಕಾಸಿಗೆ ಅವಕಾಶವಿದೆ',
  'Well above the range': 'ಶ್ರೇಣಿಗಿಂತ ತುಂಬಾ ಹೆಚ್ಚು',
  '{pct}% against the market middle of {rate}': '{rate} ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆಗೆ ಹೋಲಿಸಿದರೆ {pct}%',
  '{pct}% against the estimated market middle of {rate}': '{rate} ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆಗೆ ಹೋಲಿಸಿದರೆ {pct}%',
  'Indicative: market figures are mostly asking prices from reports and listings. Corner plots, wide roads, khata '
          'status, approvals and condition can justify a price well outside the range, and a price far below it is a '
          'reason to check the papers.':
      'ಅಂದಾಜು: ಮಾರುಕಟ್ಟೆ ಅಂಕಿಗಳು ಹೆಚ್ಚಾಗಿ ವರದಿ ಮತ್ತು ಜಾಹೀರಾತುಗಳಲ್ಲಿ ಕೇಳುವ ಬೆಲೆಗಳು. ಮೂಲೆ ನಿವೇಶನ, ಅಗಲ ರಸ್ತೆ, ಖಾತೆ, '
          'ಅನುಮೋದನೆ ಮತ್ತು ಸ್ಥಿತಿಯಿಂದ ಬೆಲೆ ಶ್ರೇಣಿಯಿಂದ ಹೊರಗಿರಬಹುದು; ತುಂಬಾ ಕಡಿಮೆ ಬೆಲೆ ದಾಖಲೆ ಪರಿಶೀಲಿಸಲು ಕಾರಣ.',

  // Total cost
  'Total cost': 'ಒಟ್ಟು ವೆಚ್ಚ',
  'Size (super built-up)': 'ಅಳತೆ (ಸೂಪರ್ ಬಿಲ್ಟ್-ಅಪ್)',
  'Unit': 'ಮಾನ',
  'Agreed price (optional)': 'ಒಪ್ಪಿದ ಬೆಲೆ (ಐಚ್ಛಿಕ)',
  'e.g. 85 L or 1.2 cr': 'ಉದಾ. 85 L ಅಥವಾ 1.2 cr',
  'Leave empty to use the market mid, {price}': 'ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆ {price} ಬಳಸಲು ಖಾಲಿ ಬಿಡಿ',
  'Leave empty to use the estimated market mid, {price}': 'ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆ {price} ಬಳಸಲು ಖಾಲಿ ಬಿಡಿ',
  'Leave empty to use the guidance value': 'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯ ಬಳಸಲು ಖಾಲಿ ಬಿಡಿ',
  'City / town': 'ನಗರ / ಪಟ್ಟಣ',
  'Village (rural)': 'ಗ್ರಾಮ (ಗ್ರಾಮೀಣ)',
  'Sets the surcharge on stamp duty: 2% in city and town limits, 3% in villages.':
      'ಮುದ್ರಾಂಕ ಶುಲ್ಕದ ಮೇಲಿನ ಸರ್‌ಚಾರ್ಜ್: ನಗರ ಮತ್ತು ಪಟ್ಟಣ ಮಿತಿಯಲ್ಲಿ 2%, ಗ್ರಾಮಗಳಲ್ಲಿ 3%.',
  'Enter a size to see the cost.': 'ವೆಚ್ಚ ನೋಡಲು ಅಳತೆ ನಮೂದಿಸಿ.',
  'About {price}': 'ಸುಮಾರು {price}',
  'all in, of which {amount} is government charges': 'ಎಲ್ಲ ಸೇರಿ, ಇದರಲ್ಲಿ {amount} ಸರ್ಕಾರಿ ಶುಲ್ಕ',
  'Agreed price': 'ಒಪ್ಪಿದ ಬೆಲೆ',
  'Price at market mid': 'ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆಯಲ್ಲಿ',
  'Price at estimated market mid': 'ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆಯಲ್ಲಿ',
  'Price at guidance value': 'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯದಲ್ಲಿ',
  'Charged on (the higher of the two)': 'ಶುಲ್ಕ ವಿಧಿಸುವುದು (ಎರಡರಲ್ಲಿ ಹೆಚ್ಚಿನದರ ಮೇಲೆ)',
  'Stamp duty ({pct}%)': 'ಮುದ್ರಾಂಕ ಶುಲ್ಕ ({pct}%)',
  'Cess (10% of duty)': 'ಸೆಸ್ (ಶುಲ್ಕದ 10%)',
  'Surcharge ({pct}% of duty)': 'ಸರ್‌ಚಾರ್ಜ್ (ಶುಲ್ಕದ {pct}%)',
  'Registration fee (2%)': 'ನೋಂದಣಿ ಶುಲ್ಕ (2%)',
  'Plan the home loan': 'ಗೃಹ ಸಾಲ ಯೋಜಿಸಿ',
  'Indicative. Duty is 2% up to ₹20 L, 3% up to ₹45 L and 5% above, on the higher of the agreed price and the '
          'guidance value.':
      'ಅಂದಾಜು. ಒಪ್ಪಿದ ಬೆಲೆ ಮತ್ತು ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯದಲ್ಲಿ ಹೆಚ್ಚಿನದರ ಮೇಲೆ ₹20 ಲಕ್ಷದವರೆಗೆ 2%, ₹45 ಲಕ್ಷದವರೆಗೆ 3% ಮತ್ತು '
          'ಅದಕ್ಕಿಂತ ಮೇಲೆ 5% ಮುದ್ರಾಂಕ ಶುಲ್ಕ.',
  'Not included:': 'ಸೇರಿಲ್ಲದವು:',
  'GST on under-construction flats (1–5%)': 'ನಿರ್ಮಾಣ ಹಂತದ ಫ್ಲ್ಯಾಟ್‌ಗಳ ಜಿಎಸ್‌ಟಿ (1–5%)',
  'khata transfer, legal checks, brokerage and loan fees.': 'ಖಾತೆ ವರ್ಗಾವಣೆ, ಕಾನೂನು ಪರಿಶೀಲನೆ, ದಲ್ಲಾಳಿ ಮತ್ತು ಸಾಲದ ಶುಲ್ಕಗಳು.',
  'Confirm the exact amount on Kaveri Online (kaveri.karnataka.gov.in) before paying.':
      'ಪಾವತಿಸುವ ಮೊದಲು ಕಾವೇರಿ ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ (kaveri.karnataka.gov.in) ನಿಖರ ಮೊತ್ತ ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ.',

  // House value
  'House value': 'ಮನೆಯ ಮೌಲ್ಯ',
  'Basic': 'ಸಾಮಾನ್ಯ',
  'Standard': 'ಪ್ರಮಾಣಿತ',
  'Premium': 'ಪ್ರೀಮಿಯಂ',
  'Luxury': 'ಐಷಾರಾಮಿ',
  'plain finish, local fittings': 'ಸರಳ ಮುಕ್ತಾಯ, ಸ್ಥಳೀಯ ಫಿಟ್ಟಿಂಗ್‌ಗಳು',
  'vitrified tiles, branded fittings': 'ವಿಟ್ರಿಫೈಡ್ ಟೈಲ್ಸ್, ಬ್ರ್ಯಾಂಡೆಡ್ ಫಿಟ್ಟಿಂಗ್‌ಗಳು',
  'imported tiles, modular kitchen': 'ಆಮದು ಟೈಲ್ಸ್, ಮಾಡ್ಯುಲರ್ ಅಡುಗೆಮನೆ',
  'marble, smart-home': 'ಅಮೃತಶಿಲೆ, ಸ್ಮಾರ್ಟ್-ಹೋಮ್',
  'market mid': 'ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆ',
  'estimated market mid': 'ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆ',
  'Land at the plot {basis}': 'ಭೂಮಿ ನಿವೇಶನದ {basis} ನಲ್ಲಿ',
  'Site area (sq ft)': 'ನಿವೇಶನದ ವಿಸ್ತೀರ್ಣ (ಚ.ಅಡಿ)',
  'Built-up area (sq ft)': 'ನಿರ್ಮಿತ ವಿಸ್ತೀರ್ಣ (ಚ.ಅಡಿ)',
  'Construction quality': 'ನಿರ್ಮಾಣ ಗುಣಮಟ್ಟ',
  '{tier}: about ₹{rate}/sq ft to build today': '{tier}: ಇಂದು ಕಟ್ಟಲು ಸುಮಾರು ₹{rate}/ಚ.ಅಡಿ',
  'Age of the building: 1 year': 'ಕಟ್ಟಡದ ವಯಸ್ಸು: 1 ವರ್ಷ',
  'Age of the building: {n} years': 'ಕಟ್ಟಡದ ವಯಸ್ಸು: {n} ವರ್ಷ',
  'No plot rate here to value the land.': 'ಭೂಮಿಯ ಮೌಲ್ಯ ಲೆಕ್ಕಿಸಲು ಇಲ್ಲಿ ನಿವೇಶನ ದರ ಇಲ್ಲ.',
  'Enter the site and built-up areas.': 'ನಿವೇಶನ ಮತ್ತು ನಿರ್ಮಿತ ವಿಸ್ತೀರ್ಣ ನಮೂದಿಸಿ.',
  '{land} land + {building} building': '{land} ಭೂಮಿ + {building} ಕಟ್ಟಡ',
  'Land, {n} sq ft': 'ಭೂಮಿ, {n} ಚ.ಅಡಿ',
  'Building, new ({tier}, {n} sq ft)': 'ಹೊಸ ಕಟ್ಟಡ ({tier}, {n} ಚ.ಅಡಿ)',
  'Less {pct}% for {n} years of age': '{n} ವರ್ಷದ ವಯಸ್ಸಿಗೆ {pct}% ಕಡಿತ',
  'Building today': 'ಇಂದಿನ ಕಟ್ಟಡ ಮೌಲ್ಯ',
  'Estimated value': 'ಅಂದಾಜು ಮೌಲ್ಯ',
  'Land at guidance value': 'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯದಲ್ಲಿ ಭೂಮಿ',
  'Indicative: land plus what the building would cost to put up today, less 1.5% a year for age (at most 70%). '
          'Build rates are Bengaluru 2026 figures including GST (InfraLens, Brick & Bolt). Location premiums, '
          'interiors, condition, khata status and rental income can move a real price well away from this.':
      'ಅಂದಾಜು: ಭೂಮಿ ಮತ್ತು ಇಂದು ಕಟ್ಟಡ ಕಟ್ಟಲು ತಗಲುವ ವೆಚ್ಚ, ವಯಸ್ಸಿಗೆ ವರ್ಷಕ್ಕೆ 1.5% ಕಡಿತ (ಗರಿಷ್ಠ 70%). ನಿರ್ಮಾಣ ದರಗಳು '
          'ಜಿಎಸ್‌ಟಿ ಸಹಿತ ಬೆಂಗಳೂರಿನ 2026 ಅಂಕಿಗಳು (InfraLens, Brick & Bolt). ಸ್ಥಳ, ಒಳಾಂಗಣ, ಸ್ಥಿತಿ, ಖಾತೆ ಮತ್ತು ಬಾಡಿಗೆ '
          'ಆದಾಯದಿಂದ ನಿಜವಾದ ಬೆಲೆ ಇದರಿಂದ ಬಹಳ ಬೇರೆಯಾಗಬಹುದು.',

  // Loan
  'From a price': 'ಬೆಲೆಯಿಂದ',
  'From my budget': 'ನನ್ನ ಬಜೆಟ್‌ನಿಂದ',
  'Property price': 'ಆಸ್ತಿಯ ಬೆಲೆ',
  'Interest': 'ಬಡ್ಡಿ',
  'Tenure': 'ಅವಧಿ',
  'Down payment': 'ಮುಂಗಡ ಪಾವತಿ',
  'The RBI repo rate is 5.5% (raised in Oct 2026); home loans usually cost about 2–3 points more, depending on the '
          'bank and your credit score.':
      'ಆರ್‌ಬಿಐ ರೆಪೋ ದರ 5.5% (ಅಕ್ಟೋಬರ್ 2026 ರಲ್ಲಿ ಏರಿಕೆ); ಗೃಹ ಸಾಲಗಳು ಬ್ಯಾಂಕ್ ಮತ್ತು ನಿಮ್ಮ ಕ್ರೆಡಿಟ್ ಸ್ಕೋರ್ ಆಧರಿಸಿ '
          'ಸಾಮಾನ್ಯವಾಗಿ ಸುಮಾರು 2–3 ಅಂಕ ಹೆಚ್ಚು.',
  'At this price the bank lends at most {pct}%, so the down payment is at least {down}%.':
      'ಈ ಬೆಲೆಗೆ ಬ್ಯಾಂಕ್ ಗರಿಷ್ಠ {pct}% ಸಾಲ ನೀಡುತ್ತದೆ, ಆದ್ದರಿಂದ ಮುಂಗಡ ಕನಿಷ್ಠ {down}%.',
  'Enter the price and the interest rate.': 'ಬೆಲೆ ಮತ್ತು ಬಡ್ಡಿ ದರ ನಮೂದಿಸಿ.',
  'EMI for {years} years': '{years} ವರ್ಷಗಳ ಇಎಂಐ',
  'Loan': 'ಸಾಲ',
  'Interest over the loan': 'ಒಟ್ಟು ಬಡ್ಡಿ',
  'Total repaid': 'ಒಟ್ಟು ಮರುಪಾವತಿ',
  'Stamp duty and registration (about)': 'ಮುದ್ರಾಂಕ ಶುಲ್ಕ ಮತ್ತು ನೋಂದಣಿ (ಸುಮಾರು)',
  'Cash needed up front': 'ಮೊದಲೇ ಬೇಕಾದ ಹಣ',
  'Take-home pay banks usually want': 'ಬ್ಯಾಂಕುಗಳು ಸಾಮಾನ್ಯವಾಗಿ ಬಯಸುವ ಕೈಗೆ ಬರುವ ಸಂಬಳ',
  'EMI at about half of take-home pay, with no other loans': 'ಬೇರೆ ಸಾಲಗಳಿಲ್ಲದೆ, ಇಎಂಐ ಕೈಗೆ ಬರುವ ಸಂಬಳದ ಸುಮಾರು ಅರ್ಧ',
  'EMI you can pay each month': 'ನೀವು ತಿಂಗಳಿಗೆ ಕಟ್ಟಬಲ್ಲ ಇಎಂಐ',
  'e.g. 45,000': 'ಉದಾ. 45,000',
  'A common rule: no more than 40–50% of take-home pay': 'ಸಾಮಾನ್ಯ ನಿಯಮ: ಕೈಗೆ ಬರುವ ಸಂಬಳದ 40–50% ಕ್ಕಿಂತ ಹೆಚ್ಚಿಲ್ಲ',
  'Savings for down payment and charges': 'ಮುಂಗಡ ಮತ್ತು ಶುಲ್ಕಗಳಿಗೆ ಉಳಿತಾಯ',
  'e.g. 25 L': 'ಉದಾ. 25 L',
  'Enter the EMI you can pay and the interest rate.': 'ನೀವು ಕಟ್ಟಬಲ್ಲ ಇಎಂಐ ಮತ್ತು ಬಡ್ಡಿ ದರ ನಮೂದಿಸಿ.',
  'is what you can buy for': 'ಬೆಲೆಯವರೆಗೆ ನೀವು ಖರೀದಿಸಬಹುದು',
  'the most this EMI repays: {max}': 'ಈ ಇಎಂಐ ತೀರಿಸುವ ಗರಿಷ್ಠ ಸಾಲ: {max}',
  'From your savings': 'ನಿಮ್ಮ ಉಳಿತಾಯದಿಂದ',
  'Your savings limit this, not the EMI: banks lend only part of the price, so more savings would raise it.':
      'ಇದಕ್ಕೆ ಮಿತಿ ಇಎಂಐ ಅಲ್ಲ, ನಿಮ್ಮ ಉಳಿತಾಯ: ಬ್ಯಾಂಕುಗಳು ಬೆಲೆಯ ಭಾಗಕ್ಕೆ ಮಾತ್ರ ಸಾಲ ನೀಡುತ್ತವೆ, ಹೆಚ್ಚು ಉಳಿತಾಯವಿದ್ದರೆ ಇದು ಏರುತ್ತದೆ.',
  'At the market middle here, that is about {n} guntha.': 'ಇಲ್ಲಿನ ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆಯಲ್ಲಿ ಇದು ಸುಮಾರು {n} ಗುಂಟೆ.',
  'At the market middle here, {rate}, that is about {n} sq ft.':
      'ಇಲ್ಲಿನ ಮಾರುಕಟ್ಟೆ ಮಧ್ಯ ಬೆಲೆ {rate} ನಲ್ಲಿ ಇದು ಸುಮಾರು {n} ಚ.ಅಡಿ.',
  'Indicative. Banks lend at most 90% of the price up to ₹30 L, 80% up to ₹75 L and 75% above, and do not lend for '
          'stamp duty and registration, so those come from your savings. Most banks keep all EMIs under about half of '
          'your take-home pay. Processing fees, insurance and rate changes on floating loans are not included.':
      'ಅಂದಾಜು. ಬ್ಯಾಂಕುಗಳು ₹30 ಲಕ್ಷದವರೆಗೆ ಬೆಲೆಯ ಗರಿಷ್ಠ 90%, ₹75 ಲಕ್ಷದವರೆಗೆ 80% ಮತ್ತು ಅದಕ್ಕಿಂತ ಮೇಲೆ 75% ಸಾಲ ನೀಡುತ್ತವೆ; '
          'ಮುದ್ರಾಂಕ ಶುಲ್ಕ ಮತ್ತು ನೋಂದಣಿಗೆ ಸಾಲ ಸಿಗುವುದಿಲ್ಲ, ಅವು ನಿಮ್ಮ ಉಳಿತಾಯದಿಂದ. ಹೆಚ್ಚಿನ ಬ್ಯಾಂಕುಗಳು ಎಲ್ಲ ಇಎಂಐಗಳನ್ನು ಕೈಗೆ '
          'ಬರುವ ಸಂಬಳದ ಅರ್ಧದೊಳಗೆ ಇರಿಸುತ್ತವೆ. ಪ್ರೊಸೆಸಿಂಗ್ ಶುಲ್ಕ, ವಿಮೆ ಮತ್ತು ಫ್ಲೋಟಿಂಗ್ ದರದ ಬದಲಾವಣೆಗಳು ಸೇರಿಲ್ಲ.',

  // Checklist
  'Checklist: buying a {type}': 'ಪರಿಶೀಲನಾ ಪಟ್ಟಿ: {type} ಖರೀದಿ',
  'Title and ownership (every property)': 'ಹಕ್ಕು ಮತ್ತು ಮಾಲೀಕತ್ವ (ಎಲ್ಲ ಆಸ್ತಿಗಳಿಗೆ)',
  'Khata in Bengaluru (GBA)': 'ಬೆಂಗಳೂರಿನಲ್ಲಿ ಖಾತೆ (ಜಿಬಿಎ)',
  'Village property (gram panchayat)': 'ಗ್ರಾಮದ ಆಸ್ತಿ (ಗ್ರಾಮ ಪಂಚಾಯಿತಿ)',
  'Layout and plot': 'ಬಡಾವಣೆ ಮತ್ತು ನಿವೇಶನ',
  'Converting it for building': 'ಕಟ್ಟಡಕ್ಕಾಗಿ ಭೂ ಪರಿವರ್ತನೆ',
  'The building and project': 'ಕಟ್ಟಡ ಮತ್ತು ಯೋಜನೆ',
  'The house': 'ಮನೆ',
  'Before you pay': 'ಹಣ ಪಾವತಿಸುವ ಮೊದಲು',
  'Sale deeds going back 30 years (the "chain")': '30 ವರ್ಷಗಳ ಹಿಂದಿನವರೆಗಿನ ಕ್ರಯಪತ್ರಗಳು ("ಸರಪಳಿ")',
  'Each owner must have bought from the one before. Gaps, gifts or partitions need their own papers.':
      'ಪ್ರತಿ ಮಾಲೀಕರೂ ಹಿಂದಿನವರಿಂದ ಖರೀದಿಸಿರಬೇಕು. ಅಂತರ, ದಾನ ಅಥವಾ ವಿಭಾಗಗಳಿಗೆ ಪ್ರತ್ಯೇಕ ದಾಖಲೆ ಬೇಕು.',
  'Encumbrance certificate (EC) for the same 30 years': 'ಅದೇ 30 ವರ್ಷಗಳ ಋಣಭಾರ ಪ್ರಮಾಣಪತ್ರ (ಇಸಿ)',
  'From Kaveri Online. Shows mortgages and other sales registered on the property; it should be clear.':
      'ಕಾವೇರಿ ಆನ್‌ಲೈನ್‌ನಿಂದ. ಆಸ್ತಿಯ ಮೇಲೆ ನೋಂದಾಯಿತ ಅಡಮಾನ ಮತ್ತು ಇತರ ಮಾರಾಟಗಳನ್ನು ತೋರಿಸುತ್ತದೆ; ಅದು ಸ್ವಚ್ಛವಾಗಿರಬೇಕು.',
  'Seller ID and every co-owner signing': 'ಮಾರಾಟಗಾರರ ಗುರುತು ಮತ್ತು ಎಲ್ಲ ಸಹಮಾಲೀಕರ ಸಹಿ',
  'All legal heirs or co-owners named in the records must sign, or there is a dispute waiting.':
      'ದಾಖಲೆಗಳಲ್ಲಿರುವ ಎಲ್ಲ ಕಾನೂನುಬದ್ಧ ವಾರಸುದಾರರು ಅಥವಾ ಸಹಮಾಲೀಕರು ಸಹಿ ಮಾಡಬೇಕು, ಇಲ್ಲದಿದ್ದರೆ ವ್ಯಾಜ್ಯ ಕಾದಿದೆ.',
  'Guidance value for the registration': 'ನೋಂದಣಿಗೆ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯ',
  'Stamp duty and registration are paid on the higher of the price and the guidance value shown in this app.':
      'ಬೆಲೆ ಮತ್ತು ಈ ಆ್ಯಪ್‌ನಲ್ಲಿರುವ ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯದಲ್ಲಿ ಹೆಚ್ಚಿನದರ ಮೇಲೆ ಮುದ್ರಾಂಕ ಮತ್ತು ನೋಂದಣಿ ಶುಲ್ಕ ಕಟ್ಟಲಾಗುತ್ತದೆ.',
  "e-khata from GBA (e-Aasthi), in the seller's name": 'ಮಾರಾಟಗಾರರ ಹೆಸರಿನಲ್ಲಿ ಜಿಬಿಎ ಇ-ಖಾತೆ (ಇ-ಆಸ್ತಿ)',
  'Needed for registration in Bengaluru since Nov 2025. Check it on e-Aasthi with the ePID or property tax number.':
      'ನವೆಂಬರ್ 2025 ರಿಂದ ಬೆಂಗಳೂರಿನಲ್ಲಿ ನೋಂದಣಿಗೆ ಅಗತ್ಯ. ಇ-ಆಸ್ತಿಯಲ್ಲಿ ಇಪಿಐಡಿ ಅಥವಾ ಆಸ್ತಿ ತೆರಿಗೆ ಸಂಖ್ಯೆಯಿಂದ ಪರಿಶೀಲಿಸಿ.',
  'A-khata or B-khata?': 'ಎ-ಖಾತೆಯೋ ಬಿ-ಖಾತೆಯೋ?',
  'B-khata means approvals, layout or building issues are pending: harder to get a loan or resell. Conversion to '
          'A-khata costs a share of the guidance value (a reduced 2% window ran May–Aug 2026).':
      'ಬಿ-ಖಾತೆ ಎಂದರೆ ಅನುಮೋದನೆ, ಬಡಾವಣೆ ಅಥವಾ ಕಟ್ಟಡದ ಸಮಸ್ಯೆಗಳು ಬಾಕಿ: ಸಾಲ ಅಥವಾ ಮರುಮಾರಾಟ ಕಷ್ಟ. ಎ-ಖಾತೆಗೆ ಬದಲಿಸಲು '
          'ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯದ ಒಂದು ಭಾಗ ಶುಲ್ಕ (ಮೇ–ಆಗಸ್ಟ್ 2026 ರಲ್ಲಿ ಕಡಿಮೆ 2% ಅವಕಾಶವಿತ್ತು).',
  'Property tax paid up to date': 'ಆಸ್ತಿ ತೆರಿಗೆ ಇಂದಿನವರೆಗೆ ಪಾವತಿ',
  'Ask for the receipts; arrears pass to the buyer.': 'ರಸೀದಿಗಳನ್ನು ಕೇಳಿ; ಬಾಕಿ ಖರೀದಿದಾರರಿಗೆ ವರ್ಗವಾಗುತ್ತದೆ.',
  'e-Swathu Form 11A or 11B from the gram panchayat': 'ಗ್ರಾಮ ಪಂಚಾಯಿತಿಯಿಂದ ಇ-ಸ್ವತ್ತು ನಮೂನೆ 11ಎ ಅಥವಾ 11ಬಿ',
  'The digital khata for village properties (e-Swathu 2.0, Dec 2025). 11A is for approved layouts and converted land; '
          '11B covers older or unapproved properties and is weaker.':
      'ಗ್ರಾಮದ ಆಸ್ತಿಗಳ ಡಿಜಿಟಲ್ ಖಾತೆ (ಇ-ಸ್ವತ್ತು 2.0, ಡಿಸೆಂಬರ್ 2025). 11ಎ ಅನುಮೋದಿತ ಬಡಾವಣೆ ಮತ್ತು ಪರಿವರ್ತಿತ ಭೂಮಿಗೆ; '
          '11ಬಿ ಹಳೆಯ ಅಥವಾ ಅನುಮೋದನೆ ಇಲ್ಲದ ಆಸ್ತಿಗಳಿಗೆ, ಮತ್ತು ದುರ್ಬಲ.',
  'Form 9 / 11 matches the sale deed': 'ನಮೂನೆ 9 / 11 ಕ್ರಯಪತ್ರಕ್ಕೆ ಹೊಂದಿಕೆಯಾಗಬೇಕು',
  'Same survey number, extent and owner name.': 'ಅದೇ ಸರ್ವೆ ಸಂಖ್ಯೆ, ವಿಸ್ತೀರ್ಣ ಮತ್ತು ಮಾಲೀಕರ ಹೆಸರು.',
  'Layout approval from BDA, BMRDA, BIAAPA or the local planning authority':
      'ಬಿಡಿಎ, ಬಿಎಂಆರ್‌ಡಿಎ, ಬಿಐಎಎಪಿಎ ಅಥವಾ ಸ್ಥಳೀಯ ಯೋಜನಾ ಪ್ರಾಧಿಕಾರದ ಬಡಾವಣೆ ಅನುಮೋದನೆ',
  "Ask for the approved layout plan and check this plot's number and size on it.":
      'ಅನುಮೋದಿತ ಬಡಾವಣೆ ನಕ್ಷೆ ಕೇಳಿ, ಅದರಲ್ಲಿ ಈ ನಿವೇಶನದ ಸಂಖ್ಯೆ ಮತ್ತು ಅಳತೆ ಪರಿಶೀಲಿಸಿ.',
  'Land conversion order for the layout land': 'ಬಡಾವಣೆ ಭೂಮಿಯ ಭೂ ಪರಿವರ್ತನೆ ಆದೇಶ',
  'The layout must stand on land converted for residential use (see farmland).':
      'ಬಡಾವಣೆ ವಸತಿ ಬಳಕೆಗೆ ಪರಿವರ್ತಿತ ಭೂಮಿಯ ಮೇಲಿರಬೇಕು (ಕೃಷಿ ಭೂಮಿ ನೋಡಿ).',
  'RERA registration for new layouts': 'ಹೊಸ ಬಡಾವಣೆಗಳಿಗೆ ರೆರಾ ನೋಂದಣಿ',
  'Check the project on the Karnataka RERA site; unregistered new layouts are a red flag.':
      'ಕರ್ನಾಟಕ ರೆರಾ ಜಾಲತಾಣದಲ್ಲಿ ಯೋಜನೆ ಪರಿಶೀಲಿಸಿ; ನೋಂದಣಿಯಾಗದ ಹೊಸ ಬಡಾವಣೆ ಅಪಾಯದ ಸೂಚನೆ.',
  'Road width and access': 'ರಸ್ತೆ ಅಗಲ ಮತ್ತು ಸಂಪರ್ಕ',
  'A plot on a public road wide enough for building permission; corner and wide-road plots cost more.':
      'ಕಟ್ಟಡ ಅನುಮತಿಗೆ ಸಾಕಷ್ಟು ಅಗಲದ ಸಾರ್ವಜನಿಕ ರಸ್ತೆಯಲ್ಲಿರುವ ನಿವೇಶನ; ಮೂಲೆ ಮತ್ತು ಅಗಲ ರಸ್ತೆಯ ನಿವೇಶನಗಳು ದುಬಾರಿ.',
  "RTC (Pahani) on Bhoomi in the seller's name": 'ಭೂಮಿ ತಂತ್ರಾಂಶದಲ್ಲಿ ಮಾರಾಟಗಾರರ ಹೆಸರಿನಲ್ಲಿ ಆರ್‌ಟಿಸಿ (ಪಹಣಿ)',
  'Shows owner, extent and crop; it should match the deed.':
      'ಮಾಲೀಕ, ವಿಸ್ತೀರ್ಣ ಮತ್ತು ಬೆಳೆ ತೋರಿಸುತ್ತದೆ; ಕ್ರಯಪತ್ರಕ್ಕೆ ಹೊಂದಿಕೆಯಾಗಬೇಕು.',
  'Mutation register (MR) entries': 'ಮ್ಯುಟೇಶನ್ ರಿಜಿಸ್ಟರ್ (ಎಂಆರ್) ನಮೂದುಗಳು',
  'How the land came to the seller: inheritance, partition or purchase.':
      'ಭೂಮಿ ಮಾರಾಟಗಾರರಿಗೆ ಹೇಗೆ ಬಂತು: ಪಿತ್ರಾರ್ಜಿತ, ವಿಭಾಗ ಅಥವಾ ಖರೀದಿ.',
  'Survey sketch (11E / Tippan) and boundaries': 'ಸರ್ವೆ ನಕ್ಷೆ (11ಇ / ಟಿಪ್ಪಣ್) ಮತ್ತು ಗಡಿಗಳು',
  'Have the land measured; the extent on the ground often differs.':
      'ಭೂಮಿಯನ್ನು ಅಳತೆ ಮಾಡಿಸಿ; ನೆಲದ ಮೇಲಿನ ವಿಸ್ತೀರ್ಣ ಹಲವು ಬಾರಿ ಬೇರೆಯಾಗಿರುತ್ತದೆ.',
  'Not government, inam or PTCL land': 'ಸರ್ಕಾರಿ, ಇನಾಂ ಅಥವಾ ಪಿಟಿಸಿಎಲ್ ಭೂಮಿ ಅಲ್ಲ',
  'Granted land (PTCL) and some inam land cannot be freely sold. Check the RTC remarks and with the tahsildar.':
      'ಮಂಜೂರಾದ ಭೂಮಿ (ಪಿಟಿಸಿಎಲ್) ಮತ್ತು ಕೆಲವು ಇನಾಂ ಭೂಮಿಯನ್ನು ಮುಕ್ತವಾಗಿ ಮಾರುವಂತಿಲ್ಲ. ಆರ್‌ಟಿಸಿ ಷರಾ ಮತ್ತು ತಹಶೀಲ್ದಾರರಲ್ಲಿ ಪರಿಶೀಲಿಸಿ.',
  'Is the land inside an approved Master Plan?': 'ಭೂಮಿ ಅನುಮೋದಿತ ಮಾಸ್ಟರ್ ಪ್ಲಾನ್ ಒಳಗಿದೆಯೇ?',
  "Inside one (rules of Dec 2025, circular of Feb 2026): no Deputy Commissioner (DC) order; conversion comes with the "
          "planning authority's layout approval, a Form 21B affidavit and a fee. Ask for the digital payment receipt.":
      'ಒಳಗಿದ್ದರೆ (ಡಿಸೆಂಬರ್ 2025 ರ ನಿಯಮ, ಫೆಬ್ರವರಿ 2026 ರ ಸುತ್ತೋಲೆ): ಜಿಲ್ಲಾಧಿಕಾರಿ (ಡಿಸಿ) ಆದೇಶ ಬೇಕಿಲ್ಲ; ಯೋಜನಾ ಪ್ರಾಧಿಕಾರದ '
          'ಬಡಾವಣೆ ಅನುಮೋದನೆ, ನಮೂನೆ 21ಬಿ ಪ್ರಮಾಣಪತ್ರ ಮತ್ತು ಶುಲ್ಕದೊಂದಿಗೆ ಪರಿವರ್ತನೆ. ಡಿಜಿಟಲ್ ಪಾವತಿ ರಸೀದಿ ಕೇಳಿ.',
  'Outside a Master Plan: DC conversion (Form 21C)': 'ಮಾಸ್ಟರ್ ಪ್ಲಾನ್ ಹೊರಗೆ: ಡಿಸಿ ಪರಿವರ್ತನೆ (ನಮೂನೆ 21ಸಿ)',
  'The DC must decide in 30 days, or it is deemed approved once the fee is paid. Ask for the order or proof of '
          'deemed approval.':
      'ಡಿಸಿ 30 ದಿನಗಳಲ್ಲಿ ನಿರ್ಧರಿಸಬೇಕು, ಇಲ್ಲವಾದರೆ ಶುಲ್ಕ ಕಟ್ಟಿದ ಮೇಲೆ ಅನುಮೋದಿತವೆಂದು ಪರಿಗಣನೆ. ಆದೇಶ ಅಥವಾ ಪರಿಗಣಿತ '
          'ಅನುಮೋದನೆಯ ಪುರಾವೆ ಕೇಳಿ.',
  'Land use matches what you plan to build': 'ಭೂ ಬಳಕೆ ನೀವು ಕಟ್ಟಲಿರುವುದಕ್ಕೆ ಹೊಂದಬೇಕು',
  "Check the Master Plan zoning; residential use on agricultural zoning won't pass.":
      'ಮಾಸ್ಟರ್ ಪ್ಲಾನ್ ವಲಯ ಪರಿಶೀಲಿಸಿ; ಕೃಷಿ ವಲಯದಲ್ಲಿ ವಸತಿ ಬಳಕೆಗೆ ಅನುಮತಿ ಸಿಗದು.',
  'RERA registration and the RERA project page': 'ರೆರಾ ನೋಂದಣಿ ಮತ್ತು ರೆರಾ ಯೋಜನೆ ಪುಟ',
  'Shows approvals, completion date and complaints. Check on the Karnataka RERA site.':
      'ಅನುಮೋದನೆ, ಪೂರ್ಣಗೊಳ್ಳುವ ದಿನಾಂಕ ಮತ್ತು ದೂರುಗಳನ್ನು ತೋರಿಸುತ್ತದೆ. ಕರ್ನಾಟಕ ರೆರಾ ಜಾಲತಾಣದಲ್ಲಿ ಪರಿಶೀಲಿಸಿ.',
  'Occupancy certificate (OC) for a ready flat': 'ಸಿದ್ಧ ಫ್ಲ್ಯಾಟ್‌ಗೆ ಸ್ವಾಧೀನ ಪ್ರಮಾಣಪತ್ರ (ಒಸಿ)',
  "Without an OC the flat can't get an A-khata, and many banks won't lend.":
      'ಒಸಿ ಇಲ್ಲದೆ ಫ್ಲ್ಯಾಟ್‌ಗೆ ಎ-ಖಾತೆ ಸಿಗುವುದಿಲ್ಲ, ಮತ್ತು ಹಲವು ಬ್ಯಾಂಕುಗಳು ಸಾಲ ನೀಡುವುದಿಲ್ಲ.',
  'Approved building plan matches the building': 'ಅನುಮೋದಿತ ಕಟ್ಟಡ ನಕ್ಷೆ ಕಟ್ಟಡಕ್ಕೆ ಹೊಂದಬೇಕು',
  'Extra floors or deviations beyond the plan can block the OC.': 'ನಕ್ಷೆ ಮೀರಿದ ಹೆಚ್ಚುವರಿ ಮಹಡಿ ಅಥವಾ ಬದಲಾವಣೆಗಳು ಒಸಿಯನ್ನು ತಡೆಯಬಹುದು.',
  'Your share of the land (UDS)': 'ಭೂಮಿಯಲ್ಲಿ ನಿಮ್ಮ ಪಾಲು (ಯುಡಿಎಸ್)',
  'The undivided share of land should be stated in the sale deed.': 'ಅವಿಭಜಿತ ಭೂ ಪಾಲು ಕ್ರಯಪತ್ರದಲ್ಲಿ ನಮೂದಾಗಿರಬೇಕು.',
  'Carpet area, not just super built-up': 'ಸೂಪರ್ ಬಿಲ್ಟ್-ಅಪ್ ಮಾತ್ರವಲ್ಲ, ಕಾರ್ಪೆಟ್ ವಿಸ್ತೀರ್ಣ',
  'Prices are quoted on super built-up; carpet area is what you use, often 25–30% less.':
      'ಬೆಲೆಯನ್ನು ಸೂಪರ್ ಬಿಲ್ಟ್-ಅಪ್ ಮೇಲೆ ಹೇಳಲಾಗುತ್ತದೆ; ನೀವು ಬಳಸುವುದು ಕಾರ್ಪೆಟ್ ವಿಸ್ತೀರ್ಣ, ಸಾಮಾನ್ಯವಾಗಿ 25–30% ಕಡಿಮೆ.',
  'Approved building plan and completion or occupancy certificate':
      'ಅನುಮೋದಿತ ಕಟ್ಟಡ ನಕ್ಷೆ ಮತ್ತು ಪೂರ್ಣಗೊಂಡ ಅಥವಾ ಸ್ವಾಧೀನ ಪ್ರಮಾಣಪತ್ರ',
  'Floors built beyond the plan are a common B-khata cause.': 'ನಕ್ಷೆ ಮೀರಿ ಕಟ್ಟಿದ ಮಹಡಿಗಳು ಬಿ-ಖಾತೆಗೆ ಸಾಮಾನ್ಯ ಕಾರಣ.',
  "Electricity, water and sewer connections in the owner's name": 'ಮಾಲೀಕರ ಹೆಸರಿನಲ್ಲಿ ವಿದ್ಯುತ್, ನೀರು ಮತ್ತು ಒಳಚರಂಡಿ ಸಂಪರ್ಕ',
  'BESCOM and BWSSB bills; transfer them after registration.': 'ಬೆಸ್ಕಾಂ ಮತ್ತು ಜಲಮಂಡಳಿ ಬಿಲ್‌ಗಳು; ನೋಂದಣಿಯ ನಂತರ ವರ್ಗಾಯಿಸಿ.',
  'A structural look by an engineer for older houses': 'ಹಳೆಯ ಮನೆಗಳಿಗೆ ಎಂಜಿನಿಯರ್‌ರಿಂದ ಕಟ್ಟಡ ಪರಿಶೀಲನೆ',
  'Damp, cracks and wiring change what the building is worth.': 'ತೇವ, ಬಿರುಕು ಮತ್ತು ವೈರಿಂಗ್ ಕಟ್ಟಡದ ಮೌಲ್ಯ ಬದಲಿಸುತ್ತವೆ.',
  "A lawyer's title report before any advance": 'ಯಾವುದೇ ಮುಂಗಡಕ್ಕೆ ಮೊದಲು ವಕೀಲರ ಹಕ್ಕು ವರದಿ',
  'Costs a few thousand rupees and catches most problems.': 'ಕೆಲವು ಸಾವಿರ ರೂಪಾಯಿ ಖರ್ಚು, ಹೆಚ್ಚಿನ ಸಮಸ್ಯೆಗಳನ್ನು ಹಿಡಿಯುತ್ತದೆ.',
  'Advance by bank transfer, against a signed sale agreement': 'ಸಹಿ ಮಾಡಿದ ಮಾರಾಟ ಒಪ್ಪಂದದ ಮೇಲೆ ಬ್ಯಾಂಕ್ ವರ್ಗಾವಣೆಯಲ್ಲಿ ಮುಂಗಡ',
  "With a refund clause if the title doesn't clear.": 'ಹಕ್ಕು ಸ್ಪಷ್ಟವಾಗದಿದ್ದರೆ ಹಣ ಹಿಂದಿರುಗಿಸುವ ಷರತ್ತಿನೊಂದಿಗೆ.',
  'Loan sanction in hand, if you need one': 'ಸಾಲ ಬೇಕಿದ್ದರೆ, ಮಂಜೂರಾತಿ ಕೈಯಲ್ಲಿರಲಿ',
  "A bank's legal check is a useful second opinion on the papers.": 'ಬ್ಯಾಂಕಿನ ಕಾನೂನು ಪರಿಶೀಲನೆ ದಾಖಲೆಗಳ ಬಗ್ಗೆ ಉಪಯುಕ್ತ ಎರಡನೇ ಅಭಿಪ್ರಾಯ.',
  'A general guide, checked {date}, not legal advice. Khata and land-conversion rules changed in 2025–26 and may '
          'change again: confirm with the sub-registrar, GBA (e-Aasthi), the gram panchayat or the planning '
          'authority, and have a property lawyer read the documents before you pay an advance.':
      'ಸಾಮಾನ್ಯ ಮಾರ್ಗದರ್ಶಿ, {date} ರಲ್ಲಿ ಪರಿಶೀಲಿಸಲಾಗಿದೆ, ಕಾನೂನು ಸಲಹೆಯಲ್ಲ. ಖಾತೆ ಮತ್ತು ಭೂ ಪರಿವರ್ತನೆ ನಿಯಮಗಳು 2025–26 ರಲ್ಲಿ '
          'ಬದಲಾಗಿವೆ, ಮತ್ತೆ ಬದಲಾಗಬಹುದು: ಉಪನೋಂದಣಾಧಿಕಾರಿ, ಜಿಬಿಎ (ಇ-ಆಸ್ತಿ), ಗ್ರಾಮ ಪಂಚಾಯಿತಿ ಅಥವಾ ಯೋಜನಾ ಪ್ರಾಧಿಕಾರದಲ್ಲಿ '
          'ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ, ಮತ್ತು ಮುಂಗಡ ಕೊಡುವ ಮೊದಲು ಆಸ್ತಿ ವಕೀಲರಿಂದ ದಾಖಲೆಗಳನ್ನು ಓದಿಸಿ.',

  // Editor: log a rate, listing import, location picker
  'Listing (portal, ad)': 'ಜಾಹೀರಾತು (ಪೋರ್ಟಲ್, ಜಾಹೀರಾತು)',
  'Deal or quote I heard': 'ನಾನು ಕೇಳಿದ ವ್ಯವಹಾರ ಅಥವಾ ದರ',
  "Don't know": 'ಗೊತ್ತಿಲ್ಲ',
  'A khata': 'ಎ ಖಾತೆ',
  'B khata': 'ಬಿ ಖಾತೆ',
  'E khata': 'ಇ ಖಾತೆ',
  'DC converted': 'ಡಿಸಿ ಪರಿವರ್ತಿತ',
  'BDA approved': 'ಬಿಡಿಎ ಅನುಮೋದಿತ',
  'BMRDA approved': 'ಬಿಎಂಆರ್‌ಡಿಎ ಅನುಮೋದಿತ',
  'BIAAPA approved': 'ಬಿಐಎಎಪಿಎ ಅನುಮೋದಿತ',
  'Agricultural': 'ಕೃಷಿ',
  'Where is {place}?': '{place} ಎಲ್ಲಿದೆ?',
  'Add your editor key in Settings first.': 'ಮೊದಲು ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಸಂಪಾದಕ ಕೀ ಸೇರಿಸಿ.',
  'Market rate saved': 'ಮಾರುಕಟ್ಟೆ ದರ ಉಳಿಸಲಾಗಿದೆ',
  'Rate (₹)': 'ದರ (₹)',
  'Enter the rate as a number': 'ದರವನ್ನು ಸಂಖ್ಯೆಯಾಗಿ ನಮೂದಿಸಿ',
  'Rate must be more than zero': 'ದರ ಸೊನ್ನೆಗಿಂತ ಹೆಚ್ಚಿರಬೇಕು',
  'Where it came from': 'ಎಲ್ಲಿಂದ ಬಂತು',
  'Khata / approval': 'ಖಾತೆ / ಅನುಮೋದನೆ',
  'Seen on {date}': '{date} ರಂದು ನೋಡಿದ್ದು',
  'Note (optional)': 'ಟಿಪ್ಪಣಿ (ಐಚ್ಛಿಕ)',
  'e.g. 30×40 corner site, 99acres listing': 'ಉದಾ. 30×40 ಮೂಲೆ ನಿವೇಶನ, 99acres ಜಾಹೀರಾತು',
  'Saving…': 'ಉಳಿಸಲಾಗುತ್ತಿದೆ…',
  'Save rate': 'ದರ ಉಳಿಸಿ',
  'Location pinned': 'ಸ್ಥಳ ಗುರುತಿಸಲಾಗಿದೆ',
  'On the map': 'ನಕ್ಷೆಯಲ್ಲಿದೆ',
  'Not on the map yet': 'ಇನ್ನೂ ನಕ್ಷೆಯಲ್ಲಿಲ್ಲ',
  'Set location': 'ಸ್ಥಳ ಗುರುತಿಸಿ',
  'Drop a pin so this place shows on the map': 'ಈ ಸ್ಥಳ ನಕ್ಷೆಯಲ್ಲಿ ಕಾಣಲು ಪಿನ್ ಇಡಿ',
  'Rate from a listing': 'ಜಾಹೀರಾತಿನಿಂದ ದರ',
  'Add your editor key in Settings to save rates': 'ದರ ಉಳಿಸಲು ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಸಂಪಾದಕ ಕೀ ಸೇರಿಸಿ',
  'Listing text': 'ಜಾಹೀರಾತಿನ ಪಠ್ಯ',
  'Share a listing to NelaBele, or paste its title, price and size here':
      'ಜಾಹೀರಾತನ್ನು ನೆಲಬೆಲೆಗೆ ಹಂಚಿಕೊಳ್ಳಿ, ಅಥವಾ ಅದರ ಶೀರ್ಷಿಕೆ, ಬೆಲೆ ಮತ್ತು ಅಳತೆ ಇಲ್ಲಿ ಅಂಟಿಸಿ',
  'Type': 'ಬಗೆ',
  'Price': 'ಬೆಲೆ',
  'Rate': 'ದರ',
  'Which place is it?': 'ಇದು ಯಾವ ಸ್ಥಳ?',
  'Village or locality': 'ಗ್ರಾಮ ಅಥವಾ ಬಡಾವಣೆ',
  'No place matches. Try a nearby village or another spelling.':
      'ಯಾವ ಸ್ಥಳವೂ ಹೊಂದುತ್ತಿಲ್ಲ. ಹತ್ತಿರದ ಗ್ರಾಮ ಅಥವಾ ಬೇರೆ ಕಾಗುಣಿತ ಪ್ರಯತ್ನಿಸಿ.',
  'Move the map so the pin sits on the place.': 'ಪಿನ್ ಸ್ಥಳದ ಮೇಲೆ ಬರುವಂತೆ ನಕ್ಷೆಯನ್ನು ಸರಿಸಿ.',
  'Use this location': 'ಈ ಸ್ಥಳ ಬಳಸಿ',

  // My property and tax
  'Add a property':
      'ಆಸ್ತಿ ಸೇರಿಸಿ',
  'Pay this year\'s property tax for the 5% rebate':
      '5% ರಿಯಾಯಿತಿಗಾಗಿ ಈ ವರ್ಷದ ಆಸ್ತಿ ತೆರಿಗೆ ಕಟ್ಟಿ',
  'Paying the full year early earns 5% off. The cut-off is usually 30 April; for 2026-27 GBA extended it to 31 May. Check the date on the official site.':
      'ಇಡೀ ವರ್ಷದ ತೆರಿಗೆಯನ್ನು ಬೇಗ ಕಟ್ಟಿದರೆ 5% ಕಡಿತ. ಕೊನೆಯ ದಿನ ಸಾಮಾನ್ಯವಾಗಿ ಏಪ್ರಿಲ್ 30; 2026-27 ಕ್ಕೆ ಜಿಬಿಎ ಅದನ್ನು ಮೇ 31 ರವರೆಗೆ ವಿಸ್ತರಿಸಿತ್ತು. ಅಧಿಕೃತ ಜಾಲತಾಣದಲ್ಲಿ ದಿನಾಂಕ ಪರಿಶೀಲಿಸಿ.',
  'Keep your property\'s tax details here':
      'ನಿಮ್ಮ ಆಸ್ತಿಯ ತೆರಿಗೆ ವಿವರಗಳನ್ನು ಇಲ್ಲಿ ಇರಿಸಿ',
  'Property ID, khata and ward, each year\'s payment with its receipt, a reminder for the early-payment rebate and a rough tax estimate. Nothing leaves this device.':
      'ಆಸ್ತಿ ಸಂಖ್ಯೆ, ಖಾತೆ ಮತ್ತು ವಾರ್ಡ್, ಪ್ರತಿ ವರ್ಷದ ಪಾವತಿ ಮತ್ತು ರಸೀದಿ, ಬೇಗ ಪಾವತಿಯ ರಿಯಾಯಿತಿಗೆ ಜ್ಞಾಪನೆ ಮತ್ತು ಅಂದಾಜು ತೆರಿಗೆ. ಯಾವುದೂ ಈ ಸಾಧನದಿಂದ ಹೊರಗೆ ಹೋಗುವುದಿಲ್ಲ.',
  'Tax is paid only on the official sites; NelaBele does not take payments or fetch your bill. Details stay on this device.':
      'ತೆರಿಗೆಯನ್ನು ಅಧಿಕೃತ ಜಾಲತಾಣಗಳಲ್ಲಿ ಮಾತ್ರ ಕಟ್ಟಲಾಗುತ್ತದೆ; ನೆಲಬೆಲೆ ಹಣ ಪಡೆಯುವುದಿಲ್ಲ, ನಿಮ್ಮ ಬಿಲ್ ತರುವುದೂ ಇಲ್ಲ. ವಿವರಗಳು ಈ ಸಾಧನದಲ್ಲೇ ಇರುತ್ತವೆ.',
  'Could not open {url}':
      '{url} ತೆರೆಯಲಾಗಲಿಲ್ಲ',
  'SAS application no.':
      'ಎಸ್‌ಎಎಸ್ ಅರ್ಜಿ ಸಂಖ್ಯೆ',
  'My property':
      'ನನ್ನ ಆಸ್ತಿ',
  'Edit':
      'ತಿದ್ದಿ',
  'Village property: tax goes to the gram panchayat':
      'ಗ್ರಾಮದ ಆಸ್ತಿ: ತೆರಿಗೆ ಗ್ರಾಮ ಪಂಚಾಯಿತಿಗೆ',
  'Bengaluru (GBA) property':
      'ಬೆಂಗಳೂರು (ಜಿಬಿಎ) ಆಸ್ತಿ',
  '{label} copied':
      '{label} ನಕಲಿಸಲಾಗಿದೆ',
  '{fy}: paid {amount} on {date}':
      '{fy}: {date} ರಂದು {amount} ಪಾವತಿಸಲಾಗಿದೆ',
  '{fy}: not recorded as paid':
      '{fy}: ಪಾವತಿ ದಾಖಲಾಗಿಲ್ಲ',
  'Last paid {amount} for {fy}. GBA has not changed the rates for 2026-27, so expect about the same.':
      '{fy} ಕ್ಕೆ ಕೊನೆಯದಾಗಿ {amount} ಕಟ್ಟಲಾಗಿದೆ. 2026-27 ಕ್ಕೆ ಜಿಬಿಎ ದರ ಬದಲಿಸಿಲ್ಲ, ಆದ್ದರಿಂದ ಸುಮಾರು ಅಷ್ಟೇ ನಿರೀಕ್ಷಿಸಿ.',
  'Rough estimate: {amount} a year':
      'ಸ್ಥೂಲ ಅಂದಾಜು: ವರ್ಷಕ್ಕೆ {amount}',
  'Pay on the GBA site':
      'ಜಿಬಿಎ ಜಾಲತಾಣದಲ್ಲಿ ಕಟ್ಟಿ',
  'Payments and receipts':
      'ಪಾವತಿಗಳು ಮತ್ತು ರಸೀದಿಗಳು',
  'Estimate':
      'ಅಂದಾಜು',
  'Pay property tax: {name}':
      'ಆಸ್ತಿ ತೆರಿಗೆ ಕಟ್ಟಿ: {name}',
  'Pay at the gram panchayat or a Bapuji Seva Kendra.':
      'ಗ್ರಾಮ ಪಂಚಾಯಿತಿ ಅಥವಾ ಬಾಪೂಜಿ ಸೇವಾ ಕೇಂದ್ರದಲ್ಲಿ ಕಟ್ಟಿ.',
  'Pay the full year early for the 5% rebate: {url}':
      '5% ರಿಯಾಯಿತಿಗಾಗಿ ಇಡೀ ವರ್ಷದ ತೆರಿಗೆ ಬೇಗ ಕಟ್ಟಿ: {url}',
  'Yearly reminder':
      'ವಾರ್ಷಿಕ ಜ್ಞಾಪನೆ',
  'Village property tax is paid to the gram panchayat: at the panchayat office, a Bapuji Seva Kendra, or online through the Bapuji Seva Kendra website or app (Panchatantra 2.0) where your panchayat offers it. The khata itself is on e-Swathu.':
      'ಗ್ರಾಮದ ಆಸ್ತಿ ತೆರಿಗೆಯನ್ನು ಗ್ರಾಮ ಪಂಚಾಯಿತಿಗೆ ಕಟ್ಟಲಾಗುತ್ತದೆ: ಪಂಚಾಯಿತಿ ಕಚೇರಿ, ಬಾಪೂಜಿ ಸೇವಾ ಕೇಂದ್ರ, ಅಥವಾ ನಿಮ್ಮ ಪಂಚಾಯಿತಿ ಒದಗಿಸಿದಲ್ಲಿ ಬಾಪೂಜಿ ಸೇವಾ ಕೇಂದ್ರದ ಜಾಲತಾಣ ಅಥವಾ ಆ್ಯಪ್ (ಪಂಚತಂತ್ರ 2.0) ಮೂಲಕ ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ. ಖಾತೆ ಇ-ಸ್ವತ್ತಿನಲ್ಲಿ ಇರುತ್ತದೆ.',
  'Delete this property and its receipts?':
      'ಈ ಆಸ್ತಿ ಮತ್ತು ಅದರ ರಸೀದಿಗಳನ್ನು ಅಳಿಸಬೇಕೇ?',
  'Edit property':
      'ಆಸ್ತಿ ತಿದ್ದಿ',
  'e.g. Home in JP Nagar, site in Hoskote':
      'ಉದಾ. ಜೆಪಿ ನಗರದ ಮನೆ, ಹೊಸಕೋಟೆಯ ನಿವೇಶನ',
  'Bengaluru (GBA)':
      'ಬೆಂಗಳೂರು (ಜಿಬಿಎ)',
  'Village (panchayat)':
      'ಗ್ರಾಮ (ಪಂಚಾಯಿತಿ)',
  'Property ID (PID)':
      'ಆಸ್ತಿ ಸಂಖ್ಯೆ (ಪಿಐಡಿ)',
  'On last year\'s tax receipt or the GBA tax site':
      'ಕಳೆದ ವರ್ಷದ ತೆರಿಗೆ ರಸೀದಿ ಅಥವಾ ಜಿಬಿಎ ತೆರಿಗೆ ಜಾಲತಾಣದಲ್ಲಿ',
  'e-khata ePID':
      'ಇ-ಖಾತೆ ಇಪಿಐಡಿ',
  'From e-Aasthi, if the property has an e-khata':
      'ಆಸ್ತಿಗೆ ಇ-ಖಾತೆ ಇದ್ದರೆ, ಇ-ಆಸ್ತಿಯಿಂದ',
  'Printed on the self-assessment receipt':
      'ಸ್ವಯಂ ಮೌಲ್ಯಮಾಪನ ರಸೀದಿಯಲ್ಲಿ ಮುದ್ರಿತ',
  'e-Swathu property no. or khata no.':
      'ಇ-ಸ್ವತ್ತು ಆಸ್ತಿ ಸಂಖ್ಯೆ ಅಥವಾ ಖಾತೆ ಸಂಖ್ಯೆ',
  'On Form 9 / 11 or the panchayat receipt':
      'ನಮೂನೆ 9 / 11 ಅಥವಾ ಪಂಚಾಯಿತಿ ರಸೀದಿಯಲ್ಲಿ',
  'Gram panchayat':
      'ಗ್ರಾಮ ಪಂಚಾಯಿತಿ',
  'Kept only on this device.':
      'ಈ ಸಾಧನದಲ್ಲಿ ಮಾತ್ರ ಇರುತ್ತದೆ.',
  'Payments: {name}':
      'ಪಾವತಿಗಳು: {name}',
  'Record a payment':
      'ಪಾವತಿ ದಾಖಲಿಸಿ',
  'Record each year\'s payment and add a photo of the receipt. Buyers and banks ask for these receipts.':
      'ಪ್ರತಿ ವರ್ಷದ ಪಾವತಿ ದಾಖಲಿಸಿ, ರಸೀದಿಯ ಫೋಟೋ ಸೇರಿಸಿ. ಖರೀದಿದಾರರು ಮತ್ತು ಬ್ಯಾಂಕುಗಳು ಈ ರಸೀದಿಗಳನ್ನು ಕೇಳುತ್ತಾರೆ.',
  'Paid {date}':
      '{date} ರಂದು ಪಾವತಿ',
  'Add receipt photo':
      'ರಸೀದಿ ಫೋಟೋ ಸೇರಿಸಿ',
  'Replace receipt photo':
      'ರಸೀದಿ ಫೋಟೋ ಬದಲಿಸಿ',
  'Amount paid':
      'ಪಾವತಿಸಿದ ಮೊತ್ತ',
  'Property tax estimate':
      'ಆಸ್ತಿ ತೆರಿಗೆ ಅಂದಾಜು',
  'Value zone':
      'ಮೌಲ್ಯ ವಲಯ',
  'GBA puts every street in a zone, A (highest value) to F, by its guidance value. The zone is on your last self-assessment form or the property\'s page on the GBA tax site.':
      'ಜಿಬಿಎ ಪ್ರತಿ ರಸ್ತೆಯನ್ನು ಮಾರ್ಗಸೂಚಿ ಮೌಲ್ಯದ ಆಧಾರದಲ್ಲಿ ಎ (ಅತಿ ಹೆಚ್ಚು ಮೌಲ್ಯ) ಯಿಂದ ಎಫ್ ವರೆಗಿನ ವಲಯಕ್ಕೆ ಸೇರಿಸುತ್ತದೆ. ವಲಯ ನಿಮ್ಮ ಕಳೆದ ಸ್ವಯಂ ಮೌಲ್ಯಮಾಪನ ನಮೂನೆ ಅಥವಾ ಜಿಬಿಎ ತೆರಿಗೆ ಜಾಲತಾಣದ ಆಸ್ತಿ ಪುಟದಲ್ಲಿದೆ.',
  'You live in it':
      'ನೀವೇ ವಾಸಿಸುತ್ತೀರಿ',
  'Rented out':
      'ಬಾಡಿಗೆಗೆ ಕೊಟ್ಟಿದೆ',
  'Year built':
      'ಕಟ್ಟಿದ ವರ್ಷ',
  'Pick the zone and enter the built-up area.':
      'ವಲಯ ಆಯ್ಕೆಮಾಡಿ, ನಿರ್ಮಿತ ವಿಸ್ತೀರ್ಣ ನಮೂದಿಸಿ.',
  'About {amount} a year':
      'ವರ್ಷಕ್ಕೆ ಸುಮಾರು {amount}',
  '{amount} if you pay the full year early (5% rebate)':
      'ಇಡೀ ವರ್ಷದ ತೆರಿಗೆ ಬೇಗ ಕಟ್ಟಿದರೆ {amount} (5% ರಿಯಾಯಿತಿ)',
  'Annual value (area × rate × 10 months)':
      'ವಾರ್ಷಿಕ ಮೌಲ್ಯ (ವಿಸ್ತೀರ್ಣ × ದರ × 10 ತಿಂಗಳು)',
  'Less {pct}% for age':
      'ವಯಸ್ಸಿಗೆ {pct}% ಕಡಿತ',
  'Tax (20%)':
      'ತೆರಿಗೆ (20%)',
  'Cess (24% of tax)':
      'ಸೆಸ್ (ತೆರಿಗೆಯ 24%)',
  'A rough guide for homes only, from the self-assessment formula and its published zone rates (₹{a} to ₹{f} a sq ft a month for zones A to F, double if rented out). The bill on the GBA site can differ: it limits rises since the 2016 revision, adds the garbage (SWM) fee and charges shops, offices and empty land differently. Last year\'s receipt is the better guide.':
      'ಮನೆಗಳಿಗೆ ಮಾತ್ರ ಸ್ಥೂಲ ಮಾರ್ಗದರ್ಶಿ, ಸ್ವಯಂ ಮೌಲ್ಯಮಾಪನ ಸೂತ್ರ ಮತ್ತು ಪ್ರಕಟಿತ ವಲಯ ದರಗಳಿಂದ (ಎ ಯಿಂದ ಎಫ್ ವಲಯಕ್ಕೆ ತಿಂಗಳಿಗೆ ಚ.ಅಡಿಗೆ ₹{a} ರಿಂದ ₹{f}, ಬಾಡಿಗೆಗೆ ಕೊಟ್ಟಿದ್ದರೆ ಎರಡರಷ್ಟು). ಜಿಬಿಎ ಜಾಲತಾಣದ ಬಿಲ್ ಬೇರೆಯಾಗಿರಬಹುದು: ಅದು 2016 ರ ಪರಿಷ್ಕರಣೆಯ ನಂತರದ ಏರಿಕೆಗೆ ಮಿತಿ ಹಾಕುತ್ತದೆ, ಕಸ (ಎಸ್‌ಡಬ್ಲ್ಯುಎಂ) ಶುಲ್ಕ ಸೇರಿಸುತ್ತದೆ ಮತ್ತು ಅಂಗಡಿ, ಕಚೇರಿ ಹಾಗೂ ಖಾಲಿ ಜಾಗಕ್ಕೆ ಬೇರೆ ದರ ವಿಧಿಸುತ್ತದೆ. ಕಳೆದ ವರ್ಷದ ರಸೀದಿ ಉತ್ತಮ ಮಾರ್ಗದರ್ಶಿ.',
};
