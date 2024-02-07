import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:poc/entities/radar.dart';
import 'package:latlong2/latlong.dart';

class RadarLayer extends StatelessWidget {
  final List<Radar> radars;
  final bool showLabel;
  const RadarLayer({super.key, required this.radars, required this.showLabel});

  @override
  Widget build(BuildContext context) {
    var circles = radars.map((e) => _PieMarker(
          point: e.location,
          radius: e.radiusDistance * 1000,
          useRadiusInMeter: true,
          color: e.hasVehicles ? Colors.red.shade500 : Colors.green.shade500,
          borderColor: Colors.blue,
          borderStrokeWidth: 50,
          startAngle: (e.startAngle - 90) * math.pi / 180.0,
          sweepAngle: (e.endAngle - e.startAngle) * math.pi / 180.0,
        ));
    return Stack(
      alignment: Alignment.center,
      children: [
        _PieLayer(circles: circles.toList()),
        if (showLabel) MarkerLayer(markers: radars.map((e) => Marker(point: e.location, width: 100, child: Center(child: Text(e.displayName)))).toList())
      ],
    );
  }
}

/// Immutable marker options for circle markers
@immutable
class _PieMarker {
  final Key? key;
  final LatLng point;
  final double radius;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool useRadiusInMeter;
  final double startAngle;
  final double sweepAngle;

  const _PieMarker({
    required this.point,
    required this.radius,
    this.key,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    required this.startAngle,
    required this.sweepAngle,
  });
}

@immutable
class _PieLayer extends StatelessWidget {
  final List<_PieMarker> circles;

  const _PieLayer({super.key, required this.circles});

  @override
  Widget build(BuildContext context) {
    final map = MapCamera.of(context);
    return MobileLayerTransformer(
      child: CustomPaint(
        painter: _PiePainter(circles, map),
        size: Size(map.size.x, map.size.y),
        isComplex: true,
      ),
    );
  }
}

@immutable
class _PiePainter extends CustomPainter {
  final List<_PieMarker> circles;
  final MapCamera map;

  const _PiePainter(this.circles, this.map);

  @override
  void paint(Canvas canvas, Size size) {
    const distance = Distance();
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    {
      final paint = Paint()
        ..isAntiAlias = false
        ..strokeCap = StrokeCap.round;
      for (final circle in circles) {
        final offset = map.getOffsetFromOrigin(circle.point);
        double radius = circle.radius;
        if (circle.useRadiusInMeter) {
          final r = distance.offset(circle.point, circle.radius, 180);
          final delta = offset - map.getOffsetFromOrigin(r);
          radius = delta.distance;
        }
        paint.color = circle.color;
        _paintCircle(canvas, offset, radius, paint, circle.startAngle, circle.sweepAngle);
      }
      return;
    }
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint, double startAngle, double sweepAngle) {
    final rect = Rect.fromPoints(offset - Offset(radius, radius), offset + Offset(radius, radius));
    const useCenter = true;
    paint.color = paint.color.withOpacity(0.7);
    canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint);

    paint.color = paint.color.withOpacity(0.2);
    canvas.drawCircle(offset, radius, paint);

    paint.color = paint.color.withOpacity(0.7);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(offset, radius, paint);
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 0;
  }

  @override
  bool shouldRepaint(_PiePainter oldDelegate) => circles != oldDelegate.circles || map != oldDelegate.map;
}
