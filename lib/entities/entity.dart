import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

abstract class Entity {
  UuidValue get id;
  String get displayName;
  LatLng get location;
}
