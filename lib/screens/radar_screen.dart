import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:poc/components/radar_layer.dart';
import 'package:poc/const.dart';
import 'package:poc/providers/is_running_provider.dart';
import 'package:poc/providers/label_show_provider.dart';
import 'package:poc/providers/radars_provider.dart';
import 'package:poc/providers/vehicles_provider.dart';
import 'package:poc/screens/radar_add_screen.dart';
import 'package:poc/screens/vehicle_add_screen.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class RadarScreen extends StatefulHookConsumerWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final player = AudioPlayer();
  LatLng? _pendingVehicleAdd;
  @override
  void initState() {
    super.initState();
    player.setPlayerMode(PlayerMode.lowLatency);
    player.setSourceAsset("mixkit-system-beep-buzzer-fail-2964.wav");
    Duration prevElapsed = Duration.zero;

    // start the simulation
    _ticker = createTicker((elapsed) {
      var timeDelta = elapsed - prevElapsed; // time since last update
      proceed(timeDelta);
      prevElapsed = elapsed;
    });
    _ticker.start();
  }

  void proceed(Duration timeDelta) {
    if (ref.read(isRunningProvider) == false) return;
    final vehiclesProvider = context.read<VehiclesProvider>();
    final radarsProvider = context.read<RadarsProvider>();
    vehiclesProvider.proceed(timeDelta);
    var detectedVehicles = radarsProvider.check(timeDelta, vehiclesProvider.values);
    if (detectedVehicles.isNotEmpty) {
      player.resume(); // play a beep
    }
  }

  @override
  void dispose() {
    super.dispose();
    _ticker.dispose();
    player.dispose();
  }

  LatLng? lastTapPosition;
  @override
  Widget build(BuildContext context) {
    ContextMenu contextMenu = _createMenuItem(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: _pendingVehicleAdd == null ? null : const Text("Select End Location for vehicle!"),
        actions: [
          if (_pendingVehicleAdd != null) TextButton(onPressed: () => setState(() => _pendingVehicleAdd = null), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              var stateController = ref.read(labelShowProvider.notifier);
              stateController.update((state) => !state);
            },
            child: const Icon(Icons.abc),
          ),
          TextButton(
              onPressed: () {
                ref.read(isRunningProvider.notifier).update((state) => !state);
              },
              child: ref.watch(isRunningProvider) ? const Icon(Icons.pause) : const Icon(Icons.play_arrow))
        ],
      ),
      body: MouseRegion(
        cursor: _pendingVehicleAdd == null ? MouseCursor.defer : SystemMouseCursors.precise,
        child: FlutterMap(
          options: MapOptions(
            onTap: (tapPosition, point) {
              if (_pendingVehicleAdd == null) return;
              var pendingVehicleAdd = _pendingVehicleAdd;
              setState(() => _pendingVehicleAdd = null);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => VehicleAddScreen(
                  startLocation: pendingVehicleAdd!,
                  endLocation: point,
                ),
              ));
            },
            onLongPress: (tapPosition, point) {
              if (_pendingVehicleAdd != null) return;
              lastTapPosition = point;
              contextMenu
                ..position = tapPosition.global
                ..show(context);
            },
            onSecondaryTap: (tapPosition, point) {
              if (_pendingVehicleAdd != null) return;
              lastTapPosition = point;
              contextMenu
                ..position = tapPosition.global
                ..show(context);
            },
            initialCenter: kDohaLatLng,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ahmed.poc_qa',
            ),
            RadarLayer(
              radars: context.watch<RadarsProvider>().values,
              showLabel: ref.watch(labelShowProvider),
            ),
            _createVehicleLayer(context),
            _createVehiclePath(context),
            if (_pendingVehicleAdd != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pendingVehicleAdd!,
                    child: const Icon(
                      Icons.flag,
                      color: Colors.green,
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  ContextMenu _createMenuItem(BuildContext context) {
    var radarProvider = context.watch<RadarsProvider>();
    var vehicleProvider = context.watch<VehiclesProvider>();
    final entries = <ContextMenuEntry>[
      MenuItem.submenu(
        label: 'Add',
        icon: Icons.add,
        items: [
          MenuItem(
            label: 'Vehicle',
            icon: Icons.car_crash,
            onSelected: () {
              setState(() => _pendingVehicleAdd = lastTapPosition);
              // todo : create screen to add vehicle
            },
          ),
          MenuItem(
            label: 'Radar',
            icon: Icons.radar,
            onSelected: () {
              // showDialog(
              //   context: context,
              //   builder: (context) => RadarAddScreen(location: lastTapPosition!),
              // );
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RadarAddScreen(location: lastTapPosition!),
              ));
            },
          ),
        ],
      ),
      if (radarProvider.values.isNotEmpty || vehicleProvider.values.isNotEmpty) const MenuDivider(),
      if (radarProvider.values.isNotEmpty || vehicleProvider.values.isNotEmpty)
        MenuItem.submenu(
          label: 'Delete',
          icon: Icons.delete,
          items: [
            MenuItem(
              label: "All",
              onSelected: () {
                vehicleProvider.removeAll();
                radarProvider.removeAll();
              },
            ),
            if (vehicleProvider.values.isNotEmpty)
              MenuItem.submenu(
                label: "Vehicles",
                icon: Icons.car_crash,
                items: vehicleProvider.values
                    .map((e) => MenuItem(
                          label: e.displayName,
                          onSelected: () => vehicleProvider.remove(e),
                        ))
                    .toList(),
              ),
            if (radarProvider.values.isNotEmpty)
              MenuItem.submenu(
                label: "Radars",
                icon: Icons.radar,
                items: radarProvider.values
                    .map((e) => MenuItem(
                          label: e.displayName,
                          onSelected: () => radarProvider.remove(e),
                        ))
                    .toList(),
              ),
          ],
        ),
    ];

    final contextMenu = ContextMenu(
      entries: entries,
      position: const Offset(300, 300),
      padding: const EdgeInsets.all(8.0),
    );
    return contextMenu;
  }

  Widget _createVehicleLayer(BuildContext context) {
    final vehicles = context.watch<VehiclesProvider>();
    final markers = <Marker>[];
    for (final vehicle in vehicles.values) {
      markers.add(Marker(
          point: vehicle.currentLocation,
          child: Transform.rotate(
            angle: vehicle.direction * math.pi / 180,
            child: const Icon(Icons.arrow_upward),
          )));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        MarkerLayer(markers: markers),
        if (ref.watch(labelShowProvider))
          MarkerLayer(
              markers: vehicles.values
                  .map((e) => Marker(
                      point: e.currentLocation, width: 100, child: Transform.translate(offset: const Offset(0, 10), child: Center(child: Text(e.displayName)))))
                  .toList())
      ],
    );
  }

  Widget _createVehiclePath(BuildContext context) {
    final vehicles = context.watch<VehiclesProvider>();
    var list = vehicles.values
        .map((e) => Polyline(
              points: [e.endLocation, e.currentLocation],
              isDotted: true,
              color: Colors.black,
              strokeWidth: 2,
            ))
        .toList();
    return PolylineLayer(polylines: list);
  }
}
