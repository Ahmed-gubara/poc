import 'package:latlong2/latlong.dart';
import 'package:poc/entities/entity.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:uuid/uuid_value.dart';

abstract class Radar extends Entity {
  @override
  UuidValue get id;
  @override
  String get displayName;
  @override
  LatLng get location;

  bool get hasVehicles;
  List<Vehicle> check(Duration timeDelta, List<Vehicle> vehicles);
}
