import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:poc/entities/radar.dart';

final radarsNotifierProvider = NotifierProvider<RadarsNotifier, List<Radar>>(RadarsNotifier.new);

class RadarsNotifier extends Notifier<List<Radar>> {
  @override
  List<Radar> build() => [];

  void update(Radar radar) {
    final list = state.where((element) => element.id != radar.id).toList();
    list.add(radar);
    state = list;
  }

  void remove(Radar radar) {
    state = state.where((element) => element.id != radar.id).toList();
  }
}
