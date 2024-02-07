import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:uuid/uuid_value.dart';

class VehiclesProvider extends ChangeNotifier {
  VehiclesProvider() {
    // _addSample();
  }

  // ignore: unused_element
  void _addSample() {
    update(Vehicle(
      id: newUuid(),
      displayName: "Vehicle 1",
      currentLocation: const LatLng(25.2924, 51.3240),
      speed: 8200,
      endLocation: const LatLng(25.2924, 51.5490),
    ));

    update(Vehicle(
      id: newUuid(),
      displayName: "Vehicle 2",
      currentLocation: const LatLng(25.3124, 51.3000),
      speed: 8200,
      endLocation: const LatLng(25.3124, 51.5490),
    ));

    update(Vehicle(
      id: newUuid(),
      displayName: "Vehicle 3",
      currentLocation: const LatLng(25.3324, 51.2700),
      speed: 8200,
      endLocation: const LatLng(25.3324, 51.5490),
    ));
  }

  final Map<UuidValue, Vehicle> _vehicles = {};
  List<Vehicle> get values => _vehicles.values.toList();
  void update(Vehicle vehicle) {
    _vehicles[vehicle.id] = vehicle;
    notifyListeners();
  }

  void remove(Vehicle vehicle) {
    _vehicles.removeWhere((key, value) => key == vehicle.id);
    notifyListeners();
  }

  void removeAll() {
    _vehicles.clear();
    notifyListeners();
  }

  void proceed(Duration timeDelta) {
    for (var vehicle in _vehicles.values) {
      vehicle.proceed(timeDelta);
    }
    notifyListeners();
  }
}
