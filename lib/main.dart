import 'package:flutter/material.dart';

import 'core/settings/settings_controller.dart';
import 'data/repositories/local_data_repository.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const Cs2SimulatorApp());
}

class Cs2SimulatorApp extends StatefulWidget {
  const Cs2SimulatorApp({super.key});

  @override
  State<Cs2SimulatorApp> createState() => _Cs2SimulatorAppState();
}

class _Cs2SimulatorAppState extends State<Cs2SimulatorApp> {
  late final SettingsController _settingsController;
  late final Future<void> _initFuture;
  late final LocalDataRepository _repository;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController();
    _repository = LocalDataRepository();
    _initFuture = _settingsController.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'CS2 Simulator',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: HomeScreen(
            repository: _repository,
            settingsController: _settingsController,
          ),
        );
      },
    );
  }
}