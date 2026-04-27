import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'game_loader.dart';
import 'game_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  late WebSocketChannel channel;
  late Future<GameLevelData> _gameDataFuture;
  final double gameWidth = 1120;
  final double gameHeight = 630;
  dynamic _worldData;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
    _gameDataFuture = Loader.loadLevel('level_000');
  }

  void _initializeConnection() {
    //channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000'));
    channel = WebSocketChannel.connect(Uri.parse('wss://pico4.ieti.site:443')); 
    
    // Listen to stream immediately
    channel.stream.listen(
      (data) {
        try {
          final message = jsonDecode(data);
          if (message['type'] == 'WORLD_INIT') {
            setState(() {
              _worldData = message;
            });
            print("✓ WORLD_INIT received: ${message['data']}");
          } else {
            print("📨 Server message type: ${message['type']} \n ${message['data']}");
            setState(() {
              _worldData = message;
            });
          }
        } catch (e) {
          print("❌ Error parsing server data: $e");
        }
      },
      onError: (error) {
        print("❌ WebSocket error: $error");
      },
      onDone: () {
        print("⚠️ WebSocket connection closed");
      },
    );
    
    // Send JOIN_VIEWER after a brief delay to ensure connection is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      channel.sink.add(jsonEncode({
        'type': 'JOIN_VIEWER',
      }));
      print("📤 Sent JOIN_VIEWER to server");
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Center(
          child: Text(widget.title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Center(
        child: Container(
          width: gameWidth,
          height: gameHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: FutureBuilder<GameLevelData>(
            future: _gameDataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final gameData = snapshot.data!;
                return CustomPaint(
                  painter: GamePainter(gameData, _worldData),
                  size: Size(gameWidth, gameHeight),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading game data: ${snapshot.error}'),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}
