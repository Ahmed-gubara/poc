import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/radar.dart';
import 'package:poc/providers/radars_provider.dart';
import 'package:provider/provider.dart';

class RadarAddScreen extends StatefulWidget {
  final LatLng location;
  const RadarAddScreen({super.key, required this.location});

  @override
  State<RadarAddScreen> createState() => _RadarAddScreenState();
}

class _RadarAddScreenState extends State<RadarAddScreen> {
  final _formKey = GlobalKey<FormState>();
  String displayName = "";
  double distance = 0.0;
  // RangeValues rangeValues = const RangeValues(-10, 10);
  double startAngle = -10;
  double endAngle = 10;
  static const gap = SizedBox(height: 8);
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
              ),
              gap,
              const Text("Distance, KM"),
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
                onSaved: (newValue) => distance = double.parse(newValue!),
              ),
              gap,
              const Text("Range, Degrees"),
              // FormField<RangeValues>(
              //   initialValue: rangeValues,
              //   builder: (field) {
              //     return RangeSlider(
              //       labels: RangeLabels(field.value?.start.toStringAsFixed(0) ?? "", field.value?.end.toStringAsFixed(0) ?? ""),
              //       min: field.value!.end - 360,
              //       max: field.value!.start + 360,
              //       values: field.value!,
              //       onChanged: (value) => field.didChange(value),
              //     );
              //   },
              //   validator: (value) => value == null ? "Error" : null,
              //   onSaved: (newValue) => rangeValues = newValue!,
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      decoration: const InputDecoration(label: Text("Start Angle")),
                      initialValue: startAngle.toStringAsFixed(2),
                      validator: (value) => value == null ? "Error" : null,
                      onSaved: (newValue) => startAngle = double.parse(newValue!),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(" - "),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      decoration: const InputDecoration(label: Text("End Angle")),
                      initialValue: endAngle.toStringAsFixed(2),
                      validator: (value) => value == null ? "Error" : null,
                      onSaved: (newValue) => endAngle = double.parse(newValue!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                  onPressed: () {
                    var currentState = _formKey.currentState;
                    if (currentState != null && currentState.validate() == true) {
                      currentState.save();
                      context.read<RadarsProvider>().update(Radar(
                            id: newUuid(),
                            displayName: displayName,
                            location: widget.location,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            radiusDistance: distance,
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
