import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/rotating_radar.dart';

class RotatingRadarLayer extends StatelessWidget {
  final List<RotatingRadar> radars;
  final bool showLabel;
  const RotatingRadarLayer({super.key, required this.radars, required this.showLabel});

  @override
  Widget build(BuildContext context) {
    var circles = radars.map((e) {
      var color = e.hasVehicles ? const Color(0xFFFF0000) : const Color(0xFF00FF00);
      return CircleMarker(
        point: e.location,
        radius: e.radiusDistance * 1000, // convert from km to meters
        useRadiusInMeter: true,
        color: color.withOpacity(0.3),
        borderColor: color,
        borderStrokeWidth: 2,
      );
    });
    var radarLines = radars.map((e) {
      var color = e.hasVehicles ? Colors.red.shade700 : Colors.green.shade700;
      return Polyline(points: [
        distance.offset(e.location, e.radiusDistance * 1000, e.heading),
        e.location,
        // distance.offset(e.location, e.radiusDistance * 1000, e.prevHeading),
      ], color: color, strokeWidth: 2);
    });

    final detectedMarkers = radars.expand((element) => element.detectedLocation).map((e) => Marker(point: e, child: const Icon(Icons.close)));
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleLayer(circles: circles.toList()),
        PolylineLayer(polylines: radarLines.toList()),
        MarkerLayer(markers: detectedMarkers.toList()),
        if (showLabel)
          MarkerLayer(markers: radars.map((e) => Marker(rotate: true, point: e.location, width: 100, child: Center(child: Text(e.displayName)))).toList())
      ],
    );
  }
}
