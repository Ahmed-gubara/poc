import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:poc/components/fixed_radar_layer.dart';
import 'package:poc/components/rotating_radar_layer.dart';
import 'package:poc/const.dart';
import 'package:poc/entities/entity.dart';
import 'package:poc/entities/fixed_radar.dart';
import 'package:poc/entities/radar.dart';
import 'package:poc/entities/rotating_radar.dart';
import 'package:poc/entities/vehicle.dart';
import 'package:poc/providers/is_running_provider.dart';
import 'package:poc/providers/label_show_provider.dart';
import 'package:poc/providers/radars_provider.dart';
import 'package:poc/providers/sound_mode_provider.dart';
import 'package:poc/providers/vehicles_provider.dart';
import 'package:poc/screens/fixed_radar_add_screen.dart';
import 'package:poc/screens/rotating_radar_add_screen.dart';
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
  List<LatLng>? _pendingWaypoints;
  bool runOnce = false;
  @override
  void initState() {
    super.initState();
    player.setPlayerMode(PlayerMode.lowLatency);
    player.setSourceAsset("mixkit-system-beep-buzzer-fail-2964.wav");
    Duration prevElapsed = Duration.zero;

    // start the simulation
    _ticker = createTicker((elapsed) {
      if (prevElapsed != Duration.zero) {
        var timeDelta = elapsed - prevElapsed; // time since last update
        proceed(timeDelta);
      }
      prevElapsed = elapsed;
    });
    _ticker.start();
  }

  void proceed(Duration timeDelta) {
    if (ref.read(isRunningProvider) == false && runOnce == false) return;
    if (runOnce) runOnce = false;
    final vehiclesProvider = context.read<VehiclesProvider>();
    final radarsProvider = context.read<RadarsProvider>();
    vehiclesProvider.proceed(timeDelta);
    var detectedVehicles = radarsProvider.check(timeDelta, vehiclesProvider.values);
    if (detectedVehicles.isNotEmpty && ref.read(soundModeProvider)) {
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
    final fixedRadars = context.watch<RadarsProvider>().values.whereType<FixedRadar>();
    final rotatingRadars = context.watch<RadarsProvider>().values.whereType<RotatingRadar>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, title: _pendingWaypoints == null ? null : const Text("Select End Location for vehicle!"), actions: [
        SafeArea(
          child: Container(
            color: Colors.grey.shade200,
            child: Row(
              children: [
                if (_pendingWaypoints != null) ...[
                  TextButton(onPressed: () => setState(() => _pendingWaypoints = null), child: const Text("Cancel")),
                  TextButton(
                      onPressed: () {
                        var pendingWaypoints = _pendingWaypoints;
                        setState(() => _pendingWaypoints = null);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => VehicleAddScreen(
                            waypoints: pendingWaypoints!,
                          ),
                        ));
                      },
                      child: const Text("Add Vehicle")),
                ],
                TextButton(
                  onPressed: () => ref.read(labelShowProvider.notifier).update((state) => !state),
                  child: const Icon(Icons.abc),
                ),
                TextButton(
                    onPressed: () => ref.read(isRunningProvider.notifier).update((state) => !state),
                    child: ref.watch(isRunningProvider) ? const Icon(Icons.pause) : const Icon(Icons.play_arrow)),
                TextButton(onPressed: () => runOnce = true, child: const Icon(Icons.skip_next)),
                TextButton(
                    onPressed: () => ref.read(soundModeProvider.notifier).update((state) => !state),
                    child: ref.watch(soundModeProvider) ? const Icon(Icons.volume_up) : const Icon(Icons.volume_off)),
              ],
            ),
          ),
        )
      ]),
      body: MouseRegion(
        cursor: _pendingWaypoints == null ? MouseCursor.defer : SystemMouseCursors.precise,
        child: FlutterMap(
          options: MapOptions(
            onTap: (tapPosition, point) {
              if (_pendingWaypoints == null) return;
              setState(() => _pendingWaypoints!.add(point));
            },
            onLongPress: (tapPosition, point) {
              if (_pendingWaypoints != null) return;
              lastTapPosition = point;
              _createMenuItem(context, getClosest(point))
                ..position = tapPosition.global
                ..show(context);
            },
            onSecondaryTap: (tapPosition, point) {
              if (_pendingWaypoints != null) return;
              lastTapPosition = point;
              _createMenuItem(context, getClosest(point))
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
            FixedRadarLayer(
              radars: fixedRadars.toList(),
              showLabel: ref.watch(labelShowProvider),
            ),
            RotatingRadarLayer(
              radars: rotatingRadars.toList(),
              showLabel: ref.watch(labelShowProvider),
            ),
            _createVehiclePath(context),
            _createVehicleLayer(context),
            if (_pendingWaypoints != null) _createVehicleWaypoint(context, _pendingWaypoints!)
          ],
        ),
      ),
    );
  }

  Widget _createVehicleWaypoint(BuildContext context, List<LatLng> waypoints) {
    final markerLayer = MarkerLayer(
      markers: [
        ...waypoints.asMap().entries.map((p) => Marker(
              point: p.value,
              child: Text((p.key + 1).toString()),
            )),
      ],
    );
    final polylineLayer = PolylineLayer(polylines: [Polyline(points: waypoints, strokeWidth: 2, color: Colors.blue)]);
    return Stack(
      children: [polylineLayer, markerLayer],
    );
  }

  ContextMenu _createMenuItem(BuildContext context, [Entity? deletable]) {
    var radarProvider = context.read<RadarsProvider>();
    var vehicleProvider = context.read<VehiclesProvider>();
    var menuItemsRemoveVehicles = [
      ...vehicleProvider.values.map((e) => MenuItem(
            label: e.displayName,
            onSelected: () => vehicleProvider.remove(e),
          ))
    ];
    var menuItemsRemoveRadar = [
      ...radarProvider.values.map((e) => MenuItem(
            label: e.displayName,
            onSelected: () => radarProvider.remove(e),
          ))
    ];
    final hasRemoveOption = menuItemsRemoveRadar.isNotEmpty || menuItemsRemoveVehicles.isNotEmpty;
    final entries = <ContextMenuEntry>[
      if (deletable != null)
        MenuItem(
          label: "Delete ${deletable.runtimeType} [${deletable.displayName}]",
          onSelected: () {
            if (deletable is Radar) {
              context.read<RadarsProvider>().remove(deletable);
            } else if (deletable is Vehicle) {
              context.read<VehiclesProvider>().remove(deletable);
            }
          },
        ),
      MenuItem.submenu(
        label: 'Add',
        icon: Icons.add,
        items: [
          MenuItem(
            label: 'Vehicle',
            icon: Icons.car_crash,
            onSelected: () => setState(() => _pendingWaypoints = []),
          ),
          MenuItem(
            label: 'Fixed Radar',
            icon: Icons.radar,
            onSelected: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FixedRadarAddScreen(location: lastTapPosition!),
              ));
            },
          ),
          MenuItem(
            label: 'Rotating Radar',
            icon: Icons.radar,
            onSelected: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RotatingRadarAddScreen(location: lastTapPosition!),
              ));
            },
          ),
        ],
      ),
      if (hasRemoveOption) const MenuDivider(),
      if (hasRemoveOption)
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
            if (menuItemsRemoveVehicles.isNotEmpty)
              MenuItem.submenu(
                label: "Vehicles",
                icon: Icons.car_crash,
                items: menuItemsRemoveVehicles,
              ),
            if (menuItemsRemoveRadar.isNotEmpty)
              MenuItem.submenu(
                label: "Radars",
                icon: Icons.radar,
                items: menuItemsRemoveRadar,
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
          point: vehicle.location,
          child: Transform.rotate(
            angle: vehicle.direction * math.pi / 180,
            // child: const Icon(Icons.arrow_upward, color: Colors.black),
            child: const Image(image: AssetImage("assets/Suv.png")),
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
                      rotate: true,
                      point: e.location,
                      width: 100,
                      child: Transform.translate(offset: const Offset(0, 10), child: Center(child: Text(e.displayName)))))
                  .toList())
      ],
    );
  }

  Widget _createVehiclePath(BuildContext context) {
    final vehicles = context.watch<VehiclesProvider>();
    var list = vehicles.values
        .map((e) => Polyline(
              points: [...e.waypoints, e.location],
              isDotted: true,
              color: Colors.black,
              strokeWidth: 2,
            ))
        .toList();
    return PolylineLayer(polylines: list);
  }

  Entity? getClosest(LatLng point) {
    final entities = <Entity>[];
    var radarProvider = context.read<RadarsProvider>();
    entities.addAll(radarProvider.values);
    var vehicleProvider = context.read<VehiclesProvider>();
    entities.addAll(vehicleProvider.values);
    Entity? entity;
    double minDis = double.maxFinite;
    for (final element in entities) {
      var dis = distance.distance(point, element.location);
      if (dis < minDis) {
        minDis = dis;
        entity = element;
      }
    }
    // todo: check if distance on screen is not far.
    return entity;
  }
}
