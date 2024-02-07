import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

//25.2854° N, 51.5310° E
const LatLng kDohaLatLng = LatLng(25.2854, 51.5310);

const Uuid uuid = Uuid();
UuidValue newUuid() => uuid.v4obj();

const Distance distance = Distance();
