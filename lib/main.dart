import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;
import 'package:poc/providers/radars_provider.dart';
import 'package:poc/providers/vehicles_provider.dart';
import 'package:poc/screens/radar_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => VehiclesProvider()),
        ChangeNotifierProvider(create: (context) => RadarsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Proof of concept',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          sliderTheme: SliderThemeData(
            showValueIndicator: ShowValueIndicator.always,
          ),
          useMaterial3: true,
        ),
        home: const RadarScreen(),
      ),
    );
  }
}
