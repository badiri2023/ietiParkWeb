
import 'package:flutter/material.dart';
import 'game_loader.dart';

class GamePainter extends CustomPainter {
  final GameLevelData gameData;
  WorldInit? worldInitData;
  StateUpdate? stateUpdateData;
  late double scale;
  int doorAnimationFrame = 0;

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
      _drawDoor(canvas, size, worldInitData!.door);
      _drawKey(canvas, size, worldInitData!);
    }
    if (stateUpdateData != null) {
      _drawPlayers(canvas, size, null, null);
      _drawDoor(canvas, size, stateUpdateData!.door);
      _drawKey(canvas, size, stateUpdateData!.key);
      if (stateUpdateData!.lever != null) {
        _drawLever(canvas, size, stateUpdateData!.lever!);
      }
      if (stateUpdateData!.platform != null) {
        _drawPlatform(canvas, size, stateUpdateData!.platform!);
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

  void _drawDoor(Canvas canvas, Size canvasSize, DoorData door) {
    final worldWidth = stateUpdateData?.worldWidth ?? worldInitData?.width ?? 800;
    scale = canvasSize.width / worldWidth;
    int offsetX = 575;
    int offsetY = 220;
    double doorScaleX = 0.8;
    double doorScaleY = 1; 

    // draw the door closed (first sprite)
    if (door.opened == false) {
      canvas.drawImageRect(
        door.image!,
        Rect.fromLTWH(0, 0, door.width.toDouble(), door.height.toDouble()),
        Rect.fromLTWH(
          (door.x + offsetX) * scale, (door.y + offsetY) * scale, 
          door.width*scale*doorScaleX, door.height*scale*doorScaleY
        ),
        Paint()
      );
    } else {
      if (doorAnimationFrame < 5) {
        doorAnimationFrame++;
      }
      canvas.drawImageRect(
        door.image!,
        Rect.fromLTWH(door.width.toDouble()*doorAnimationFrame, 0, door.width.toDouble(), door.height.toDouble()),
        Rect.fromLTWH(
          (door.x + offsetX) * scale, (door.y + offsetY) * scale, 
          door.width*scale*doorScaleX, door.height*scale*doorScaleY
        ),
        Paint()
      );
    }
  }
  
  void _drawPlayers(Canvas canvas, Size canvasSize, int? animation, int? animationFrame) {
    final worldWidth = stateUpdateData?.worldWidth ?? worldInitData?.width ?? 800;
    scale = canvasSize.width / worldWidth;
    
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
    final worldWidth = stateUpdateData?.worldWidth ?? worldInitData?.width ?? 800;
    scale = canvasSize.width / worldWidth;
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

  void _drawLever(Canvas canvas, Size canvasSize, LeverData lever) {
    final worldWidth = stateUpdateData?.worldWidth ?? worldInitData?.width ?? 800;
    scale = canvasSize.width / worldWidth;
    double width = lever.width.toDouble(); 
    double height = lever.height.toDouble();
    if (lever.activated == false) {
      canvas.drawImageRect(
        lever.image!,
        Rect.fromLTWH(width, height, width, height),
        Rect.fromLTWH(
          lever.x*scale, lever.y*scale,
          width*scale, height*scale
        ),
        Paint()
      );
    } else {           
      canvas.drawImageRect(
        lever.image!,
        Rect.fromLTWH(0, height, width, height),
        Rect.fromLTWH(
          lever.x*scale, lever.y*scale,
          width*scale, height*scale
        ),
        Paint()
      );
    }
  }

  void _drawPlatform(Canvas canvas, Size canvasSize, PlatformData platform) {
    final worldWidth = stateUpdateData?.worldWidth ?? worldInitData?.width ?? 800;
    scale = canvasSize.width / worldWidth;
    double width = platform.width.toDouble();
    double height = platform.height.toDouble();

    canvas.drawImageRect(
      platform.image!,
      Rect.fromLTWH(width, height*6, width, height),
      Rect.fromLTWH(
        platform.x*scale, platform.y*scale,
        platform.width*scale, platform.height*scale
      ),
      Paint()
    );
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    return true;
  }
}
