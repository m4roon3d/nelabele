// Sanity checks for the listing parser; run in CI with `dart run tool/check_listing.dart`.
import 'dart:io';

import '../lib/listing.dart';

var failures = 0;

void expect(String what, Object? got, Object? want) {
  final ok = got is double && want is num ? (got - want).abs() < 0.01 * want.abs() + 0.01 : got == want;
  if (!ok) {
    failures++;
    stderr.writeln('FAIL $what: got $got, want $want');
  }
}

void main() {
  var p = parseListing('3 BHK Flat for sale in Whitefield, Bangalore - ₹1.2 Cr, 1,650 sq.ft https://www.99acres.com/x');
  expect('flat type', p.type, 'apartment');
  expect('flat price', p.price, 1.2e7);
  expect('flat size', p.size, 1650);
  expect('flat unit', p.rateUnit, 'sqft');
  expect('flat rate', p.rate, 1.2e7 / 1650);
  expect('flat locality', p.locality, 'Whitefield');
  expect('flat url', p.url, 'https://www.99acres.com/x');

  p = parseListing('Residential Plot 1200 sqft for sale in Devanahalli. Price: Rs 45 Lac (₹3,750/sq.ft)');
  expect('plot type', p.type, 'plot');
  expect('plot rate', p.rate, 3750);
  expect('plot rate unit', p.rateUnit, 'sqft');
  expect('plot size', p.size, 1200);
  expect('plot price', p.price, 45e5);
  expect('plot locality', p.locality, 'Devanahalli');

  p = parseListing('2 acres agricultural land at Kanakapura Road for ₹1.6 Crore');
  expect('farm type', p.type, 'agricultural_land');
  expect('farm unit', p.rateUnit, 'acre');
  expect('farm rate', p.rate, 8e6);
  expect('farm locality', p.locality, 'Kanakapura Road');

  p = parseListing('30x40 site in Hosahalli, 62 L');
  expect('dim size', p.size, 1200);
  expect('dim price', p.price, 62e5);

  expect('money L', parseMoney('85 L'), 85e5);
  expect('money cr', parseMoney('1.2 cr'), 1.2e7);
  expect('money plain', parseMoney('45,00,000'), 45e5);
  expect('money bad', parseMoney('abc'), null);
  expect('unit sq.ft', unitCode('sq.ft'), 'sqft');
  expect('unit sq yd', unitCode('sq yards'), 'sqyd');
  expect('unit sqm', unitCode('sq.m'), 'sqm');
  expect('unit guntha', unitCode('gunthas'), 'guntha');

  if (failures > 0) {
    stderr.writeln('$failures listing check(s) failed');
    exit(1);
  }
  stdout.writeln('Listing parser checks passed');
}
