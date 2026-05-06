import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRPage extends StatelessWidget {
  const QRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descargar Pico4')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Escanea para descargar la app',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            QrImageView(
              data: 'https://piko4.ieti.site/descarga',
              version: QrVersions.auto,
              size: 250.0,
            ),

            const SizedBox(height: 20),

            const Text(
              'https://piko4.ieti.site/descarga',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
