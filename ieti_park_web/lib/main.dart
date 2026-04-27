import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'game_loader.dart';

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
    _gameDataFuture = GameDataLoader.loadLevel('level_000');
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

class GamePainter extends CustomPainter {
  final GameLevelData gameData;
  final dynamic serverData;
  late WorldInit worldInitData;
  late StateUpdate stateUpdateData;

  GamePainter(this.gameData, this.serverData);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background color
    final backgroundColor = _hexToColor(gameData.backgroundColorHex);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // Draw each layer
    for (final layer in gameData.layers) {
      if (layer.visible && layer.tileSheetImage != null) {
        _drawLayer(canvas, layer, size);
      }
    }

    // Handle different message types
    if (serverData != null && serverData is Map) {
      if (serverData['type'] == 'WORLD_INIT') {
        worldInitData = WorldInit(serverData['data']);
        _drawDoor(canvas, size, null);
      } else if (serverData['type'] == 'STATE_UPDATE') {
        stateUpdateData = StateUpdate(serverData['data']);
        _drawPlayers(canvas, size);
      }
    }

  }

  void _drawLayer(Canvas canvas, GameLayer layer, Size canvasSize) {
    if (layer.tileSheetImage == null) return;

    final tileSheetImage = layer.tileSheetImage!;
    final tileWidth = layer.tilesWidth;
    final tileHeight = layer.tilesHeight;
    final scale = canvasSize.width / (layer.tileMap[0].length * tileWidth);

    // Draw all tiles in the tilemap
    for (int row = 0; row < layer.tileMap.length; row++) {
      for (int col = 0; col < layer.tileMap[row].length; col++) {
        final tileIndex = layer.tileMap[row][col];

        if (tileIndex >= 0) {
          // Calculate source position in tileset
          final tilesPerRow = tileSheetImage.width ~/ tileWidth;
          final srcX = (tileIndex % tilesPerRow) * tileWidth;
          final srcY = (tileIndex ~/ tilesPerRow) * tileHeight;

          // Calculate destination position
          final dstX = (layer.x + col * tileWidth) * scale;
          final dstY = (layer.y + row * tileHeight) * scale;

          // Draw tile
          canvas.drawImageRect(
            tileSheetImage,
            Rect.fromLTWH(srcX.toDouble(), srcY.toDouble(),
                tileWidth.toDouble(), tileHeight.toDouble()),
            Rect.fromLTWH(dstX, dstY, tileWidth * scale, tileHeight * scale),
            Paint(),
          );
        }
      }
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff'); // Add alpha channel
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _drawDoor(Canvas canvas, Size canvasSize, int? animationFrame) {
    final scale = canvasSize.width / worldInitData.width;

    DoorData door = worldInitData.door;
    final x = door.x; final y = door.y;
    final width = door.width;
    final height = door.height;
    final doorImage = door.doorSpritesheetImage!;
    final spriteWidth = door.spriteWidth;

    // draw the door closed (first sprite)
    if (animationFrame == null) {
      canvas.drawImageRect(
        doorImage,
        Rect.zero,
        Rect.fromLTWH(x*scale, y*scale, width*scale, height*scale),
        Paint()
      );
    }
  }
  void _drawPlayers(Canvas canvas, Size canvasSize) {
    final scale = canvasSize.width / worldInitData.width;
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    return oldDelegate.serverData != serverData;
  }
}
