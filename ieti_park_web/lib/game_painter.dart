
import 'package:flutter/material.dart';
import 'game_loader.dart';

class GamePainter extends CustomPainter {
  final GameLevelData gameData;
  final dynamic serverData;
  late WorldInit worldInitData;
  late StateUpdate stateUpdateData;

  GamePainter(this.gameData, this.serverData);

  @override
  void paint(Canvas canvas, Size size) async {
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

    // Handle server messages
    if (serverData != null && serverData is Map) {
      if (serverData['type'] == 'WORLD_INIT') {
        worldInitData = await Loader.loadWorldInit(serverData['data']);
        _drawDoor(canvas, size, null);
      } else if (serverData['type'] == 'STATE_UPDATE') {
        stateUpdateData = await Loader.loadStateUpdate(serverData['data']);
        _drawPlayers(canvas, size, null, null);
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
    final spriteHeight = door.spriteHeight;

    // draw the door closed (first sprite)
    if (animationFrame == null) {
      canvas.drawImageRect(
        doorImage,
        Rect.fromLTWH(0, 0, spriteWidth, spriteHeight),
        Rect.fromLTWH(x*scale, y*scale, width*scale, height*scale),
        Paint()
      );
    } else {
      // TODO animar
    }
  }
  void _drawPlayers(Canvas canvas, Size canvasSize, int? animation, int? animationFrame) {
    final scale = canvasSize.width / worldInitData.width;

    for (PlayerState player in stateUpdateData.players) {
      final x = player.x; final y = player.y;
      final nickname = player.nickname;
      final spriteWidth = player.spriteWidth;
      final spriteHeight = player.spriteHeight;
      final image = player.image!;

      // draw player standing
      if (animation == null) {
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, spriteWidth, spriteHeight),
          Rect.fromLTWH(x*scale, y*scale, spriteWidth*scale, spriteHeight*scale),
          Paint()
        );
      } else {
        // TODO animar
      }
    }
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    return oldDelegate.serverData != serverData;
  }
}
