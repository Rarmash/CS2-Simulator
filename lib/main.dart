import 'package:flutter/material.dart';
import 'data/repositories/local_data_repository.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const Cs2SimulatorApp());
}

class Cs2SimulatorApp extends StatelessWidget {
  const Cs2SimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CS2 Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomeScreen(repository: LocalDataRepository()),
    );
  }
}