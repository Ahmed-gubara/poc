import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/radar.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:uuid/uuid.dart';

class RadarsProvider extends ChangeNotifier {
  RadarsProvider() {
    // addSample();
  }

  // ignore: unused_element
  void _addSample() {
    update(Radar(
      id: newUuid(),
      displayName: "Radar 1",
      location: kDohaLatLng,
      startAngle: -10,
      endAngle: 20,
      radiusDistance: 10,
    ));
    update(Radar(
      id: newUuid(),
      displayName: "Radar 2",
      location: const LatLng(25.2854, 51.3210),
      startAngle: -30,
      endAngle: 30,
      radiusDistance: 10,
    ));
  }

  final Map<UuidValue, Radar> _radars = {};
  List<Radar> get values => _radars.values.toList();
  void update(Radar radar) {
    _radars[radar.id] = radar;
    notifyListeners();
  }

  void remove(Radar radar) {
    _radars.removeWhere((key, value) => key == radar.id);
    notifyListeners();
  }

  void removeAll() {
    _radars.clear();
    notifyListeners();
  }

  List<VehicleDetected> check(Duration timeDelta, List<Vehicle> vehicles) {
    final newlyDetected = <VehicleDetected>[];
    for (final radar in _radars.values) {
      var detected = radar.check(timeDelta, vehicles);
      for (final vehicle in detected) {
        newlyDetected.add(VehicleDetected(vehicleId: vehicle.id, radarIs: radar.id));
      }
    }
    return newlyDetected;
  }
}

class VehicleDetected {
  final UuidValue vehicleId;
  final UuidValue radarIs;

  VehicleDetected({required this.vehicleId, required this.radarIs});
}
