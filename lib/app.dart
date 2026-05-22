import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/core/constants/app_router.dart';
import 'package:dari_app/providers/theme_provider.dart';

class DariApp extends ConsumerWidget {
  const DariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'Dari.tn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
