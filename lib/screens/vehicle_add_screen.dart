import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:poc/providers/vehicles_provider.dart';
import 'package:provider/provider.dart';

class VehicleAddScreen extends StatefulWidget {
  final List<LatLng> waypoints;
  const VehicleAddScreen({super.key, required this.waypoints});

  @override
  State<VehicleAddScreen> createState() => _VehicleAddScreenState();
}

class _VehicleAddScreenState extends State<VehicleAddScreen> {
  static const gap = SizedBox(height: 8);
  final _formKey = GlobalKey<FormState>();
  String displayName = "";
  double speed = 0.0;
  bool useRoute = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Display name"),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                onSaved: (newValue) => displayName = newValue ?? "",
              ), // display name

              gap,
              const Text("Speed, KM/H"),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid number';
                  }
                  return null;
                },
                onSaved: (newValue) => speed = double.parse(newValue!),
              ),
              if (widget.waypoints.length == 2)
                Row(
                  children: [
                    Checkbox(
                      value: useRoute,
                      onChanged: (value) => setState(() => useRoute = value ?? false),
                    ),
                    const Text("use route"),
                  ],
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                  onPressed: () async {
                    var currentState = _formKey.currentState;
                    if (currentState != null && currentState.validate() == true) {
                      currentState.save();
                      var ww = widget.waypoints;
                      if (useRoute) {
                        final start = ww[0];
                        final end = ww[1];
                        var list = await ors.directionsRouteCoordsGet(
                            startCoordinate: ORSCoordinate(latitude: start.latitude, longitude: start.longitude),
                            endCoordinate: ORSCoordinate(latitude: end.latitude, longitude: end.longitude),
                            profileOverride: ORSProfile.drivingCar);
                        ww.clear();
                        for (final p in list) {
                          ww.add(LatLng(p.latitude, p.longitude));
                        }
                      }
                      final startLocation = ww.first;
                      final waypoints = ww.skip(1).toList().reversed.toList();
                      if (context.mounted) {
                        context.read<VehiclesProvider>().update(Vehicle(
                              id: newUuid(),
                              displayName: displayName,
                              location: startLocation,
                              waypoints: waypoints,
                              speed: speed,
                            ));
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text("Add Vehicle")),
            ],
          )),
    );
  }
}
