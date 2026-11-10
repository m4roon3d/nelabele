import 'package:geolocator/geolocator.dart';

/// Where the phone (or browser) is, or a reason it couldn't tell.
class Here {
  const Here(this.lat, this.lon);
  final double lat;
  final double lon;
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<Here> currentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationException('Turn on location to see places near you.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const LocationException('NelaBele needs location permission to find places near you.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationException('Location is blocked for NelaBele. Allow it in your phone settings.');
  }
  try {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 20)),
    );
    return Here(p.latitude, p.longitude);
  } catch (_) {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return Here(last.latitude, last.longitude);
    throw const LocationException("Couldn't get your location. Try again outdoors or with Wi-Fi on.");
  }
}

/// Outside the area NelaBele covers?
bool outsideCoverage(Here h) => h.lat < 12.3 || h.lat > 13.6 || h.lon < 76.9 || h.lon > 78.1;
