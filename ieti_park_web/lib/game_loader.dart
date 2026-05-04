import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

class GameLayer {
  final String name;
  final String tilesSheetFile;
  final String tileMapFile;
  final int tilesWidth;
  final int tilesHeight;
  final int x;
  final int y;
  final bool visible;
  late List<List<int>> tileMap;
  ui.Image? tileSheetImage;

  GameLayer({
    required this.name,
    required this.tilesSheetFile,
    required this.tileMapFile,
    required this.tilesWidth,
    required this.tilesHeight,
    required this.x,
    required this.y,
    required this.visible,
  });
}
class GameLevelData {
  final String name;
  final List<GameLayer> layers;
  final int viewportWidth;
  final int viewportHeight;
  final String backgroundColorHex;

  GameLevelData({
    required this.name,
    required this.layers,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.backgroundColorHex,
  });
}

class DoorData {
  double x; double y;
  String imageFile;
  double width; double height;
  ui.Image? image;
  
  DoorData(dynamic doorData)
  : x = doorData['x'],
    y = doorData['y'],
    imageFile = "media/door.png",
    width = 267,
    height = 335;
}
class KeyData {
  double x; double y; 
  bool collected;
  String? holderId;
  String imageFile;
  double width; double height;
  ui.Image? image;

  KeyData(dynamic keyData)
  : x = keyData['x'],
    y = keyData['y'],
    collected = keyData['collected'],
    holderId = keyData['holderId'],
    imageFile = "media/skeleton_key.png",
    width = 32,
    height = 32;
}
class WorldInit {
  double width;
  double height;
  DoorData door;
  KeyData key;

  WorldInit(dynamic worldInit)
  : width = worldInit['width'],
    height = worldInit['height'],
    door = DoorData(worldInit['door']),
    key = KeyData(worldInit['key']);
}

class PlayerState {
  String id;
  double x; double y;
  String nickname;
  String color;
  late String imageFile;
  double width; double height;
  ui.Image? image;

  PlayerState(dynamic playerState)
  : id = playerState['id'],
    x = playerState['x'],
    y = playerState['y'],
    nickname = playerState['nickname'],
    color = playerState['color'],
    width = 112,
    height = 186 {
      for (int i = 0; i < colors.length; i++) {
        if (color == colors[i]) {
          imageFile = "media/skeleton_color${i+1}.png";
        }
      }
    }
}
class StateUpdate {
  List<PlayerState> players;
  KeyData key;

  StateUpdate(dynamic stateUpdate)
  : players = [
      for (dynamic playerState in stateUpdate['players'])
        PlayerState(playerState)
    ],
    key = KeyData(stateUpdate['key']);
}


class Loader {
  static Future<GameLevelData> loadLevel(String levelName) async {
    // Load game data JSON
    final gameDataJson = await rootBundle.loadString('assets/game_data.json');
    final gameData = jsonDecode(gameDataJson);

    // Get the first level (you can add logic to select specific levels)
    final levelData = gameData['levels'][0];

    // Load layers
    final layers = <GameLayer>[];
    for (final layerData in levelData['layers']) {
      final layer = GameLayer(
        name: layerData['name'],
        tilesSheetFile: layerData['tilesSheetFile'],
        tileMapFile: layerData['tileMapFile'],
        tilesWidth: layerData['tilesWidth'],
        tilesHeight: layerData['tilesHeight'],
        x: layerData['x'],
        y: layerData['y'],
        visible: layerData['visible'],
      );

      // Load tilemap JSON
      final tileMapJson =
          await rootBundle.loadString('assets/${layer.tileMapFile}');
      final tileMapData = jsonDecode(tileMapJson);
      layer.tileMap = List<List<int>>.from(
        tileMapData['tileMap'].map((row) => List<int>.from(row)),
      );

      // Load tileset image
      layer.tileSheetImage = await _loadImage('assets/${layer.tilesSheetFile}');

      layers.add(layer);
    }

    return GameLevelData(
      name: levelData['name'],
      layers: layers,
      viewportWidth: levelData['viewportWidth'],
      viewportHeight: levelData['viewportHeight'],
      backgroundColorHex: levelData['backgroundColorHex'],
    );
  }

  static Future<WorldInit> loadWorldInit(dynamic data) async {
    WorldInit worldInit = WorldInit(data);
    worldInit.door.image = await _loadImage("assets/${worldInit.door.imageFile}");
    worldInit.key.image = await _loadImage("assets/${worldInit.key.imageFile}");
    return worldInit;
  }

  static Future<StateUpdate> loadStateUpdate(dynamic data) async {
    StateUpdate stateUpdate = StateUpdate(data);
    for (PlayerState player in stateUpdate.players) {
      player.image = await _loadImage("assets/${player.imageFile}");
    }
    stateUpdate.key.image = await _loadImage("assets/${stateUpdate.key.imageFile}");
    return stateUpdate;
  }

  static Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

