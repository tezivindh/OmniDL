import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omnidl/core/widgets/app_layout.dart';
import 'package:omnidl/features/downloader/presentation/downloader_view.dart';
import 'package:omnidl/features/home/presentation/home_view.dart';
import 'package:omnidl/features/library/presentation/library_view.dart';
import 'package:omnidl/features/settings/presentation/settings_view.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeView(),
        ),
        GoRoute(
          path: '/downloader',
          builder: (context, state) => const DownloaderView(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryView(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsView(),
        ),
      ],
    ),
  ],
);
