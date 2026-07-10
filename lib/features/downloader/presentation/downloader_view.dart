import 'package:flutter/material.dart';

class DownloaderView extends StatelessWidget {
  const DownloaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_for_offline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active downloads',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Go to Home and paste a URL to start downloading.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
