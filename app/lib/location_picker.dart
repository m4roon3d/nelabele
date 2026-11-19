import 'package:maplibre_gl/maplibre_gl.dart';

import 'ui.dart';

/// Full-screen map with a fixed pin in the middle: move the map under the
/// pin, then confirm. Pops the chosen [LatLng], or null if cancelled.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, required this.title, this.initial});

  final String title;
  final LatLng? initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  MapLibreMapController? _map;

  void _confirm() {
    final target = _map?.cameraPosition?.target;
    if (target != null) Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MapLibreMap(
            styleString: Theme.of(context).brightness == Brightness.dark
                ? 'https://tiles.openfreemap.org/styles/dark'
                : 'https://tiles.openfreemap.org/styles/liberty',
            initialCameraPosition: CameraPosition(
              target: widget.initial ?? const LatLng(12.9716, 77.5946),
              zoom: widget.initial != null ? 14 : 10,
            ),
            trackCameraPosition: true,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            onMapCreated: (c) => _map = c,
          ),
          // the pin's tip sits on the map centre
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 44, color: scheme.primary),
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Move the map so the pin sits on the place.', textAlign: TextAlign.center),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.check),
              label: const Text('Use this location'),
            ),
          ),
        ],
      ),
    );
  }
}
