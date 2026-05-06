import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game_loader.dart';
import 'game_painter.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: GameScreen()),
);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  WebSocketChannel? channel;
  WorldData? _worldData;
  StateUpdate? _stateUpdate;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _openQR() async {
    final url = Uri.parse('https://piko4.ieti.site/descarga');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("No se pudo abrir la URL");
    }
  }

  void _connect() {
    // Conexión al servidor
    channel = WebSocketChannel.connect(Uri.parse('wss://pico4.ieti.site:443'));

    channel!.stream.listen((raw) {
      try {
        final msg = jsonDecode(raw);
        final data = msg['data'];

        switch (msg['type']) {
          case 'WORLD_INIT':
            Loader.loadWorldFromServer(data).then((w) {
              setState(() => _worldData = w);
            });
            break;
          case 'STATE_UPDATE':
            if (_worldData != null) {
              Loader.loadStateUpdate(data).then((s) {
                setState(() => _stateUpdate = s);
              });
            }
            break;
          case 'CHANGE_LEVEL':
            // Limpiamos el mundo actual para forzar el redibujado del nuevo
            setState(() => _worldData = null);
            Loader.loadWorldFromServer(data['world']).then((w) {
              setState(() {
                _worldData = w;
                _stateUpdate = null;
              });
            });
            break;
          case 'GAME_OVER':
            _showEndDialog(data['message'] ?? "¡HAS ESCAPADO!");
            break;
        }
      } catch (e) {
        print("Error procesando mensaje: $e");
      }
    }, onError: (err) => print("Connection error: $err"));

    // Notificar al servidor que somos un visor
    Future.delayed(const Duration(milliseconds: 500), () {
      channel!.sink.add(jsonEncode({'type': 'JOIN_VIEWER'}));
    });
  }

  // --- FUNCIÓN QUE FALTABA ---
  void _showEndDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("FIN PARTIDA", style: TextStyle(color: Colors.white)),
        content: Text(text, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Opcional: podrías reiniciar la conexión aquí
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo negro para que no haya bordes blancos si la pantalla es muy ancha
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: _openQR,
        child: const Icon(Icons.qr_code),
      ),
      body: _worldData == null
          ? const Center(child: CircularProgressIndicator())
          : SizedBox.expand(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    // Enviamos el tamaño real de la ventana de Linux/Web al Painter
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: GamePainter(_worldData, _stateUpdate),
                  );
                },
              ),
            ),
    );
  }
}
