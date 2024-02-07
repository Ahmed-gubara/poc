import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ConsumerWidget, ProviderScope, WidgetRef;
import 'package:poc/providers/radars_provider.dart';
import 'package:poc/providers/scale_provider.dart';
import 'package:poc/providers/vehicles_provider.dart';
import 'package:poc/screens/radar_screen.dart';
import 'package:provider/provider.dart';
import 'package:scaled_app/scaled_app.dart';

void main() {
  runAppScaled(
    const ProviderScope(child: ScaleShortcut(child: MyApp())),
    // scaleFactor: (deviceSize) {
    //   return deviceSize.width / widthOfDesign;
    // },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => VehiclesProvider()),
        ChangeNotifierProvider(create: (context) => RadarsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Proof of concept',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          sliderTheme: const SliderThemeData(
            showValueIndicator: ShowValueIndicator.always,
          ),
          useMaterial3: true,
        ),
        home: const RadarScreen(),
        // builder: (context, child) {
        //   var of = MediaQuery.of(context);
        //   var watch = ref.watch(scaleProvider);
        //   return MediaQuery(
        //     data: of.copyWith(devicePixelRatio: 20),
        //     child: child!,
        //   );
        // },
      ),
    );
  }
}

double widthOfDesign = 1080;

class ScaleShortcut extends ConsumerWidget {
  final Widget child;
  const ScaleShortcut({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.digit0, meta: true): () {
        widthOfDesign = 1080;
        ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
          return deviceSize.width / widthOfDesign;
        };
        // ref.read(scaleProvider.notifier).update((state) => 1);
      },
      const SingleActivator(LogicalKeyboardKey.equal, meta: true): () {
        widthOfDesign *= 1.1;
        ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
          return deviceSize.width / widthOfDesign;
        };
        // ref.read(scaleProvider.notifier).update((state) => state = state + 0.1);
      },
      const SingleActivator(LogicalKeyboardKey.minus, meta: true): () {
        widthOfDesign /= 1.1;
        ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
          return deviceSize.width / widthOfDesign;
        };
        // ref.read(scaleProvider.notifier).update((state) => state = state - 0.1);
      },
    }, child: child);
  }
}
