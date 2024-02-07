import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:poc/providers/vehicles_provider.dart';
import 'package:provider/provider.dart';

class VehicleAddScreen extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  const VehicleAddScreen({super.key, required this.startLocation, required this.endLocation});

  @override
  State<VehicleAddScreen> createState() => _VehicleAddScreenState();
}

class _VehicleAddScreenState extends State<VehicleAddScreen> {
  static const gap = SizedBox(height: 8);
  final _formKey = GlobalKey<FormState>();
  String displayName = "";
  double speed = 0.0;
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
              const SizedBox(height: 32),
              ElevatedButton(
                  onPressed: () {
                    var currentState = _formKey.currentState;
                    if (currentState != null && currentState.validate() == true) {
                      currentState.save();
                      context.read<VehiclesProvider>().update(Vehicle(
                            id: newUuid(),
                            displayName: displayName,
                            currentLocation: widget.startLocation,
                            endLocation: widget.endLocation,
                            speed: speed,
                          ));
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Add Radar")),
            ],
          )),
    );
  }
}
