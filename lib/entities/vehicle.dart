import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:uuid/uuid.dart';

const double _kmh2MeterMs = 1000.0 / (60.0 * 60.0 * 1000);

class Vehicle {
  final UuidValue id;
  String displayName;
  LatLng currentLocation;
  double direction = 0;
  double speed; // km/h
  LatLng endLocation;

  Vehicle({
    required this.id,
    required this.displayName,
    required this.currentLocation,
    //  this.direction,
    required this.speed,
    required this.endLocation,
  });

  /// move into the end location
  void proceed(Duration timeDelta) {
    if (currentLocation == endLocation) return;
    direction = distance.bearing(currentLocation, endLocation);
    final meterPerMs = speed * _kmh2MeterMs;
    final maxDistanceToMove = meterPerMs * timeDelta.inMilliseconds;
    var remainingDistance = distance.as(LengthUnit.Meter, currentLocation, endLocation);
    if (remainingDistance < maxDistanceToMove) {
      currentLocation = endLocation;
      return;
    }

    final bearing = distance.bearing(currentLocation, endLocation);
    final newLocation = distance.offset(currentLocation, maxDistanceToMove, bearing);
    currentLocation = newLocation;
  }
}
