import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'game_loader.dart';

class GamePainter extends CustomPainter {
  final WorldData? worldData;
  final StateUpdate? stateUpdate;

  GamePainter(this.worldData, this.stateUpdate);

  @override
  void paint(Canvas canvas, Size size) {
    if (worldData == null) return;

    // 1. ESCALA: Un valor entre 1.5 y 2.0 suele ser el ideal para que se vea grande
    // pero que no se coma demasiado contenido.
    final double scale = (size.width / worldData!.width) * 1.5;

    // 2. CÁMARA DINÁMICA:
    // worldHeightScaled es la altura total del mapa con zoom.
    double worldHeightScaled = worldData!.height * scale;

    // yOffset:
    // Si usamos (size.height - worldHeightScaled), pegamos el suelo abajo.
    // Si usamos 0, pegamos el techo arriba.
    // Para que se vea "centrado" verticalmente y no se pierda tanto arriba:
    //double yOffset = (size.height - worldHeightScaled) / 2;

    // OPCIONAL: Si el esqueleto está muy abajo, puedes sumar un ajuste manual
    double yOffset = 20;

    canvas.save();

    // Movemos el lienzo.
    // Si ves que desaparece lo de arriba, es que este yOffset es muy bajo.
    canvas.translate(0, yOffset);

    // 3. FONDO (Asegúrate de que cubra todo el mundo escalado)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, worldData!.width * scale, worldData!.height * scale),
      Paint()..color = _hexToColor(worldData!.backgroundColorHex),
    );

    // ... resto de capas ...

    // ... (Aquí siguen las capas de tiles usando la variable 'scale')
    // 2. CAPAS DE TILES (Suelo y Paredes)
    for (var layer in worldData!.layers) {
      if (layer.tileSheetImage != null) {
        _drawServerLayer(canvas, layer, scale);
      }
    }

    // 3. OBJETOS DINÁMICOS (Plataformas/Palancas solo si existen en el nivel actual)
    _drawWorldObjects(canvas, scale);

    // 4. PUERTA Y LLAVE
    _drawDoor(canvas, worldData!.door, scale);
    _drawKey(canvas, stateUpdate?.key ?? worldData!.key, scale);

    // 5. JUGADORES
    if (stateUpdate != null) {
      for (var player in stateUpdate!.players) {
        _drawPlayer(canvas, player, scale);
      }
    }

    canvas.restore();
  }

  // --- MÉTODOS DE DIBUJO ---

  void _drawServerLayer(Canvas canvas, GameLayer layer, double scale) {
    final double tw = layer.tilesWidth.toDouble();
    final double th = layer.tilesHeight.toDouble();
    final int tpr = layer.tileSheetImage!.width ~/ layer.tilesWidth;
    final paint = Paint()..isAntiAlias = false;

    // 1. ELIMINAMOS el 3.5.
    // Para que no queden líneas blancas entre tiles (micro-separaciones),
    // usamos un valor casi imperceptible como 1.01.
    double adjustment = 4.01;

    for (int r = 0; r < layer.tileMap.length; r++) {
      for (int c = 0; c < layer.tileMap[r].length; c++) {
        int tileIndex = layer.tileMap[r][c];
        if (tileIndex < 0) continue;

        double srcX = (tileIndex % tpr) * tw;
        double srcY = (tileIndex ~/ tpr) * th;

        // 2. DIBUJO SIN SOLAPAMIENTO AGRESIVO
        canvas.drawImageRect(
          layer.tileSheetImage!,
          Rect.fromLTWH(srcX, srcY, tw, th),
          Rect.fromLTWH(
            c * tw * scale, // Posición exacta en la rejilla
            r * th * scale, // Posición exacta en la rejilla
            tw * scale * adjustment, // Tamaño exacto (más un mínimo solape)
            th * scale * adjustment, // Tamaño exacto (más un mínimo solape)
          ),
          paint,
        );
      }
    }
  }

  void _drawWorldObjects(Canvas canvas, double scale) {
    // Plataforma (Si existe en este mundo)
    if (worldData!.platform != null) {
      final plat = worldData!.platform!;
      canvas.drawRect(
        Rect.fromLTWH(
          plat['x'] * scale,
          plat['y'] * scale,
          plat['width'] * scale,
          plat['height'] * scale,
        ),
        Paint()..color = const Color(0xFF455A64),
      );
    }

    // Palanca (Si existe en este mundo)
    if (worldData!.palanca != null) {
      final p = worldData!.palanca!;
      bool isActivated =
          stateUpdate?.palancaUpdate?['activated'] ?? p['activated'] ?? false;
      canvas.drawRect(
        Rect.fromLTWH(
          p['x'] * scale,
          p['y'] * scale,
          p['width'] * scale,
          p['height'] * scale,
        ),
        Paint()..color = isActivated ? Colors.green : Colors.red,
      );
    }
  }

  void _drawDoor(Canvas canvas, DoorData d, double scale) {
    if (d.image == null) return;
    canvas.drawImageRect(
      d.image!,
      Rect.fromLTWH(0, 0, d.width.toDouble(), d.height.toDouble()),
      // Aplicamos el tamaño que manda el servidor multiplicado por la escala de pantalla
      Rect.fromLTWH(
        d.x * scale,
        d.y * scale,
        d.width * scale * 0.6,
        d.height * scale * 0.75,
      ),
      Paint(),
    );
  }

  void _drawKey(Canvas canvas, KeyData k, double scale) {
    if (k.image == null || k.collected) return;
    canvas.drawImageRect(
      k.image!,
      Rect.fromLTWH(0, 0, k.width.toDouble(), k.height.toDouble()),
      Rect.fromLTWH(
        k.x * scale,
        k.y * scale,
        k.width * scale,
        k.height * scale,
      ),
      Paint(),
    );
  }

  void _drawPlayer(Canvas canvas, PlayerState p, double scale) {
    if (p.image == null) return;
    canvas.drawImageRect(
      p.image!,
      Rect.fromLTWH(0, 0, p.width.toDouble(), p.height.toDouble()),
      Rect.fromLTWH(
        p.x * scale,
        p.y * scale,
        p.width * scale,
        p.height * scale,
      ),
      Paint(),
    );
    _drawNickname(canvas, p, scale);
  }

  void _drawNickname(Canvas canvas, PlayerState p, double scale) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: p.nickname,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 * scale,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (p.x * scale) + (p.width * scale / 2) - (textPainter.width / 2),
        (p.y * scale) - (20 * scale),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'ff' + hex;
    return Color(int.parse(hex, radix: 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
