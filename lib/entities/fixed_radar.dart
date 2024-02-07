import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/radar.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:uuid/uuid.dart';

class FixedRadar extends Radar {
  @override
  final UuidValue id;
  @override
  String displayName;
  @override
  LatLng location;

  // in degrees
  double startAngle;

  // in degrees
  double endAngle;

  /// in km
  double radiusDistance;
  final Set<UuidValue> _detectedVehicles = {};
  @override
  bool get hasVehicles => _detectedVehicles.isNotEmpty;

  FixedRadar({
    required this.id,
    required this.displayName,
    required this.location,
    required this.startAngle,
    required this.endAngle,
    required this.radiusDistance,
  });

  @override
  List<Vehicle> check(Duration timeDelta, List<Vehicle> vehicles) {
    final detected = <Vehicle>[];
    for (var vehicle in vehicles) {
      if (_isVehicleInRange(vehicle)) {
        if (_detectedVehicles.add(vehicle.id)) {
          // detectedVehicles.add(): returns true if it is a new detected vehicle
          detected.add(vehicle);
        }
      } else {
        _detectedVehicles.remove(vehicle.id);
      }
    }
    return detected;
  }

  bool _isVehicleInRange(Vehicle vehicle) {
    final distanceToVehicle = distance.distance(location, vehicle.location); // in meters
    if (distanceToVehicle > (radiusDistance * 1000)) {
      return false;
    }
    // if (startAngle % 360 == endAngle % 360) return true;
    var bearing = distance.bearing(location, vehicle.location);
    while (bearing < startAngle) {
      bearing += 360;
    }
    while (bearing > endAngle) {
      bearing -= 360;
    }

    if (bearing > startAngle && bearing < endAngle) return true;
    return false;
  }
}
