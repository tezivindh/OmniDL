import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:omnidl/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MediaKit for cross-platform playback
  MediaKit.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: OmniDLApp(),
    ),
  );
}
