import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

final Map<String, ui.Image> _imageCache = {};

class Loader {
  static Future<ui.Image> _getOrLoadImage(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) return _imageCache[assetPath]!;
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _imageCache[assetPath] = frame.image;
      return frame.image;
    } catch (e) {
      print("❌ Error cargando imagen en assets: $assetPath");
      rethrow;
    }
  }

  static Future<WorldData> loadWorldFromServer(dynamic data) async {
    WorldData world = WorldData(data);

    if (data['zonesFile'] != null) {
      try {
        final String zonesString = await rootBundle.loadString(
          "assets/${data['zonesFile']}",
        );
        final Map<String, dynamic> zonesData = json.decode(zonesString);
        world.addZonesFromLocalFile(zonesData);
      } catch (e) {
        print("⚠️ No se pudo cargar zonesFile: ${data['zonesFile']}");
      }
    }

    if (data['layers'] != null && data['layers'] is List) {
      for (var ld in data['layers']) {
        if (ld != null) {
          final layer = GameLayer(ld);
          layer.tileSheetImage = await _getOrLoadImage(
            'assets/${layer.tilesSheetFile}',
          );
          await layer.loadTileMapJson();
          world.layers.add(layer);
        }
      }
    }

    world.door.image = await _getOrLoadImage("assets/${world.door.imageFile}");
    world.key.image = await _getOrLoadImage("assets/${world.key.imageFile}");

    return world;
  }

  static Future<StateUpdate> loadStateUpdate(dynamic data) async {
    StateUpdate state = StateUpdate(data);
    for (var p in state.players) {
      p.image = await _getOrLoadImage("assets/${p.imageFile}");
    }
    state.key.image = await _getOrLoadImage("assets/media/skeleton_key.png");
    return state;
  }
}

// --- MODELOS DE DATOS ---

class WorldData {
  final String name;
  final int width, height;
  final String backgroundColorHex;
  late DoorData door;
  late KeyData key;

  // Listas de colisiones y física
  List<Rect> obstacles = [];
  List<Rect> platforms = [];
  List<Rect> hazards = [];
  List<Offset> spawns = [];

  Map<String, dynamic>? palanca;
  Map<String, dynamic>? platform;
  List<GameLayer> layers = [];

  WorldData(dynamic d)
    : name = d['name'] ?? "Nivel",
      width = d['width'] ?? 1500,
      height = d['height'] ?? 800,
      backgroundColorHex = d['backgroundColorHex'] ?? "#1a1a1a" {
    // Reinicio de listas
    layers = [];
    obstacles = [];
    platforms = [];
    hazards = [];
    spawns = [];

    door = DoorData(d['door']);
    key = KeyData(d['key']);

    palanca = d['palanca'] != null
        ? Map<String, dynamic>.from(d['palanca'])
        : null;
    platform = d['platform'] != null
        ? Map<String, dynamic>.from(d['platform'])
        : null;
  }

  /// ESTE MÉTODO DEBE ESTAR DENTRO DE WORLDDATA
  void addZonesFromLocalFile(Map<String, dynamic> zonesData) {
    if (zonesData['zones'] == null) return;
    for (var z in zonesData['zones']) {
      final rect = Rect.fromLTWH(
        (z['x'] as num).toDouble(),
        (z['y'] as num).toDouble(),
        (z['width'] as num).toDouble(),
        (z['height'] as num).toDouble(),
      );

      switch (z['type']) {
        case "Default":
          obstacles.add(rect);
          break;
        case "plataforma":
          platforms.add(rect);
          obstacles.add(rect);
          break;
        case "precipicio":
          hazards.add(rect);
          break;
        case "spawn":
          spawns.add(Offset(rect.left, rect.top));
          break;
      }
    }
  }
}

class GameLayer {
  final String tilesSheetFile;
  final String? tileMapFile;
  final int tilesWidth, tilesHeight;
  List<List<int>> tileMap = [];
  ui.Image? tileSheetImage;

  GameLayer(dynamic d)
    : tilesSheetFile = d['tilesSheetFile'] ?? "media/TileSetMap_Png.png",
      tileMapFile = d['tileMapFile'],
      tilesWidth = d['tilesWidth'] ?? 16,
      tilesHeight = d['tilesHeight'] ?? 16;

  Future<void> loadTileMapJson() async {
    if (tileMapFile == null) return;
    try {
      final String data = await rootBundle.loadString("assets/$tileMapFile");
      final Map<String, dynamic> jsonMap = json.decode(data);
      var rawMap = jsonMap['map'] ?? jsonMap['tileMap'];
      if (rawMap != null) {
        tileMap = (rawMap as List).map((row) => List<int>.from(row)).toList();
      }
    } catch (e) {
      print("❌ Error cargando tilemap local $tileMapFile: $e");
    }
  }
}

class DoorData {
  final double x, y;
  final int width, height;
  final String imageFile = "media/door.png";
  ui.Image? image;

  DoorData(dynamic d)
    : x = (d['x'] as num?)?.toDouble() ?? 0.0,
      y = (d['y'] as num?)?.toDouble() ?? 0.0,
      width = 267,
      height = 335;
}

class KeyData {
  final double x, y;
  final int width, height;
  final bool collected;
  final String imageFile = "media/skeleton_key.png";
  ui.Image? image;

  KeyData(dynamic d)
    : x = (d['x'] as num?)?.toDouble() ?? 0.0,
      y = (d['y'] as num?)?.toDouble() ?? 0.0,
      collected = d['collected'] ?? false,
      width = 32,
      height = 32;
}

class PlayerState {
  final String id, nickname, color;
  final double x, y;
  final int width = 112, height = 186;
  late String imageFile;
  ui.Image? image;

  PlayerState(dynamic p)
    : id = p['id'].toString(),
      x = (p['x'] as num).toDouble(),
      y = (p['y'] as num).toDouble(),
      nickname = p['nickname'] ?? "Player",
      color = p['color'] ?? "rojo" {
    final Map<String, String> skinMap = {
      'rojo': 'skeleton_color1.png',
      'azul': 'skeleton_color2.png',
      'verde': 'skeleton_color3.png',
      'amarillo': 'skeleton_color4.png',
      'rosa': 'skeleton_color5.png',
      'naranja': 'skeleton_color6.png',
      'morado': 'skeleton_color7.png',
      'cian': 'skeleton_color8.png',
    };
    String fileName = skinMap[color.toLowerCase()] ?? 'skeleton_color1.png';
    imageFile = "media/$fileName";
  }
}

class StateUpdate {
  final List<PlayerState> players;
  late KeyData key;
  Map<String, dynamic>? palancaUpdate;

  StateUpdate(dynamic d)
    : players = (d['players'] as List).map((p) => PlayerState(p)).toList() {
    key = KeyData(d['key']);
    if (d['palanca'] != null) {
      palancaUpdate = Map<String, dynamic>.from(d['palanca']);
    }
  }
}
