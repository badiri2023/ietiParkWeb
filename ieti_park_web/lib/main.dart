import 'package:web_socket_channel/web_socket_channel.dart';
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
  final WebSocketChannel channel = WebSocketChannel.connect(Uri.parse('ws://localhost:3000'));
  final double gameWidth = 1120;
  final double gameHeight = 630;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Center(
            child: Text(widget.title, 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
            ),
          ),
      ),
      body: Center(
        child: Container(
          width: gameWidth,
          height: gameHeight,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
          child: StreamBuilder(
            stream: channel.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data;
                // Debug
                print('===== Received data =====\n$data\n========================='); 
                return CustomPaint(
                  painter:
                      GamePainter(data),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return CircularProgressIndicator();
              }
            },
          ),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final dynamic data;

  GamePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the game elements based on the received data

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever new data is received
  }
}
