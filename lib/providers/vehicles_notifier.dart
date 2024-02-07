import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:poc/entities/vehicle.dart';

final vehiclesNotifierProvider = NotifierProvider<VehiclesNotifier, List<Vehicle>>(VehiclesNotifier.new);

class VehiclesNotifier extends Notifier<List<Vehicle>> {
  @override
  List<Vehicle> build() => [];

  void update(Vehicle vehicle) {
    final list = state.where((element) => element.id != vehicle.id).toList();
    list.add(vehicle);
    state = list;
  }

  void remove(Vehicle vehicle) {
    state = state.where((element) => element.id != vehicle.id).toList();
  }
}
