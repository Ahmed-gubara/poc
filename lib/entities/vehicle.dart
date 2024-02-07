import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/entity.dart';
import 'package:uuid/uuid.dart';

const double _kmh2MeterMs = 1000.0 / (60.0 * 60.0 * 1000);

class Vehicle extends Entity {
  @override
  final UuidValue id;
  @override
  String displayName;
  @override
  LatLng location;
  double direction = 0;
  double speed; // km/h
  List<LatLng> waypoints; //! this is reversed, the first way point is the last on the list
  //LatLng endLocation;

  Vehicle({
    required this.id,
    required this.displayName,
    required this.location,
    //  this.direction,
    required this.speed,
    required this.waypoints,
  });

  /// move into the end location
  // void proceed(Duration timeDelta) {
  //   if (currentLocation == endLocation) return;
  //   direction = distance.bearing(currentLocation, endLocation);
  //   final meterPerMs = speed * _kmh2MeterMs;
  //   final maxDistanceToMove = meterPerMs * timeDelta.inMilliseconds;
  //   var remainingDistance = distance.as(LengthUnit.Meter, currentLocation, endLocation);
  //   if (remainingDistance < maxDistanceToMove) {
  //     currentLocation = endLocation;
  //     return;
  //   }

  //   final bearing = distance.bearing(currentLocation, endLocation);
  //   final newLocation = distance.offset(currentLocation, maxDistanceToMove, bearing);
  //   currentLocation = newLocation;
  // }

  void proceed(Duration timeDelta) {
    if (waypoints.isEmpty) return;
    final nextWaypoint = waypoints.last;
    direction = distance.bearing(location, nextWaypoint);
    final meterPerMs = speed * _kmh2MeterMs;
    final maxDistanceToMove = meterPerMs * timeDelta.inMilliseconds;
    var remainingDistance = distance.as(LengthUnit.Meter, location, nextWaypoint);
    if (remainingDistance < maxDistanceToMove) {
      location = nextWaypoint;
      timeDelta = timeDelta - timeDelta * (remainingDistance / maxDistanceToMove);
      waypoints.removeLast();
      proceed(timeDelta);
      return;
    }

    final bearing = distance.bearing(location, nextWaypoint);
    final newLocation = distance.offset(location, maxDistanceToMove, bearing);
    location = newLocation;
  }
}


/*

1- A vehicle will move from point A to point B

2- A vehicle will move into way points 




*/