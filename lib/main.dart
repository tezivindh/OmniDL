import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:omnidl/app/app.dart';
import 'package:omnidl/core/storage/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MediaKit for cross-platform playback
  MediaKit.ensureInitialized();
  
  // Initialize local database storage
  await IsarService.instance.init();
  
  runApp(
    const ProviderScope(
      child: OmniDLApp(),
    ),
  );
}
