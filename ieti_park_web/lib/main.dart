import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IETI Park',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'IETI Park'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 600,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Llista de jugadors connectats (falta)
                ]
              ),
            ),
            Container(
              width: 900,
              height: 600,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
              child: CustomPaint(),
            ),
          ],
        ),
      ),
    );
  }
}
