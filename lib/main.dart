import 'dart:io';

import 'package:flutter/material.dart';
import 'package:daily_you/layouts/mobile_scaffold.dart';
import 'package:daily_you/layouts/responsive_layout.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:system_theme/system_theme.dart';
import 'config_manager.dart';
import 'package:provider/provider.dart';

void main() async {
  if (Platform.isLinux || Platform.isWindows) {
    // Initialize FFI
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();
  await SystemTheme.accentColor.load();
  SystemTheme.fallbackColor = const Color.fromARGB(255, 1, 211, 239);

  // Create the config file if it doesn't exist
  await ConfigManager.instance.init();
  final themeProvider = ThemeModeProvider();
  await themeProvider.initializeThemeFromConfig();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = Provider.of<ThemeModeProvider>(context);

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        title: 'Daily You',
        themeMode: themeModeProvider.themeMode,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: SystemTheme.accentColor.accent,
              brightness: Brightness.light),
        ),
        darkTheme: (ConfigManager.instance.getField('theme') == 'amoled')
            ? ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: SystemTheme.accentColor.accent,
                    brightness: Brightness.dark,
                    background: Colors.black,
                    surface: Colors.black,
                    onSurface: Colors.white,
                    surfaceTint: Colors.black),
              )
            : ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: SystemTheme.accentColor.accent,
                    brightness: Brightness.dark),
              ),
        home: const ResponsiveLayout(
          mobileScaffold: MobileScaffold(),
          tabletScaffold: MobileScaffold(),
          desktopScaffold: MobileScaffold(),
        ),
      ),
    );
  }
}
