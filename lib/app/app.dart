import 'package:flutter/material.dart';
import 'package:omnidl/app/routing/router.dart';
import 'package:omnidl/app/theme/theme.dart';

class OmniDLApp extends StatelessWidget {
  const OmniDLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OmniDL',
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
