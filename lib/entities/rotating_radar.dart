import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/radar.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:uuid/uuid_value.dart';

// convert rotation per minute, to degree per millisecond
const _factor = 360.0 / (60.0 * 1000.0);

class RotatingRadar extends Radar {
  @override
  final UuidValue id;
  @override
  String displayName;
  @override
  LatLng location;
  double heading;
  double _prevHeading = 0;
  double get prevHeading => _prevHeading;
  double rotationPerMinute;

  /// in km
  double radiusDistance;

  final List<LatLng> _detectedVehicles = [];
  @override
  bool get hasVehicles => _detectedVehicles.isNotEmpty;
  List<LatLng> get detectedLocation => _detectedVehicles.toList();

  RotatingRadar({
    required this.id,
    required this.displayName,
    required this.location,
    required this.radiusDistance,
    required this.rotationPerMinute,
    this.heading = 0,
  });

  @override
  List<Vehicle> check(Duration timeDelta, List<Vehicle> vehicles) {
    final prevHeading = heading;
    _prevHeading = heading;
    heading = heading + (timeDelta.totalMs * rotationPerMinute * _factor);
    final currentHeading = heading;
    heading = heading % 360;

    // first: clear previous detected in range
    _detectedVehicles.removeWhere((element) => _isInRange(element, prevHeading, currentHeading));

    // second: add detected vehicles
    final detected = <Vehicle>[];
    for (var vehicle in vehicles) {
      if (_isInRange(vehicle.location, prevHeading, currentHeading)) {
        _detectedVehicles.add(vehicle.location);
        detected.add(vehicle);
      }
    }
    return detected;
  }

  bool _isInRange(LatLng latlng, double prevHeading, double currentHeading) {
    final distanceToVehicle = distance.distance(location, latlng); // in meters
    if (distanceToVehicle > (radiusDistance * 1000)) {
      return false;
    }
    // if (startAngle % 360 == endAngle % 360) return true;
    var bearing = distance.bearing(location, latlng);
    while (bearing < prevHeading) {
      bearing += 360;
    }
    while (bearing > currentHeading) {
      bearing -= 360;
    }

    if (bearing >= prevHeading && bearing <= currentHeading) return true;
    return false;
  }
}
