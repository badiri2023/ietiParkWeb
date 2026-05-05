
import 'package:flutter/material.dart';
import 'game_loader.dart';

class GamePainter extends CustomPainter {
  final GameLevelData gameData;
  WorldInit? worldInitData;
  StateUpdate? stateUpdateData;
  late double scale;

  GamePainter(this.gameData, this.worldInitData, this.stateUpdateData);

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

    // Handle server messages - only draw if data is initialized
    if (worldInitData != null) {
      _drawDoor(canvas, size, null);
      _drawKey(canvas, size, worldInitData!);
    }
    if (stateUpdateData != null) {
      _drawPlayers(canvas, size, null, null);
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
    scale = canvasSize.width / worldInitData!.width;
    int offsetX = 40;
    int offsetY = 155;
    double doorScaleX = 0.6;
    double doorScaleY = 0.75; 
    DoorData door = worldInitData!.door;

    // draw the door closed (first sprite)
    if (animationFrame == null) {
      canvas.drawImageRect(
        door.image!,
        Rect.fromLTWH(0, 0, door.width.toDouble(), door.height.toDouble()),
        Rect.fromLTWH(
          door.x*scale + offsetX, door.y*scale + offsetY, 
          door.width*scale*doorScaleX, door.height*scale*doorScaleY
        ),
        Paint()
      );
    } else {
      // TODO animar
    }
  }
  
  void _drawPlayers(Canvas canvas, Size canvasSize, int? animation, int? animationFrame) {
    scale = canvasSize.width / worldInitData!.width;
    
    for (PlayerState player in stateUpdateData!.players) {
      // draw player standing
      if (animation == null) {
        canvas.drawImageRect(
          player.image!,
          Rect.fromLTWH(0, 0, player.width.toDouble(), player.height.toDouble() ),
          Rect.fromLTWH(
            player.x*scale, player.y*scale, 
            player.width*scale, player.height*scale
          ),
          Paint()
        );
      } else {
        // TODO animar
      }
    }
  }

  void _drawKey(Canvas canvas, Size canvasSize, dynamic data) {
    scale = canvasSize.width / worldInitData!.width;
    KeyData key = data.key;
    
    canvas.drawImageRect(
      key.image!,
      Rect.fromLTWH(0, 0, key.width.toDouble(), key.height.toDouble()),
      Rect.fromLTWH(
        key.x*scale, key.y*scale,
        key.width*scale, key.height*scale
      ),
      Paint()
    );
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    // Repaint if data has been initialized or changed
    return oldDelegate.worldInitData != worldInitData || 
           oldDelegate.stateUpdateData != stateUpdateData;
  }
}
