import 'package:flutter/material.dart';
import 'package:dashsweeper/dash_sweeper.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DashSweeper(
        rows: 10,
        columns: 20,
      ),
    );
  }
}
