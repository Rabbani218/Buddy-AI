import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthbuddy_ai/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/storage_keys.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'services/isar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isar = kIsWeb ? null : await initIsar();
  final savedLocaleCode = prefs.getString(localeStorageKey);
  final savedThemeMode = prefs.getString(themeModeStorageKey);
  Locale? initialLocale;
  if (savedLocaleCode != null && savedLocaleCode.isNotEmpty) {
    final parts = savedLocaleCode.split('_');
    final languageCode = parts.first;
    final countryCode = parts.length > 1 ? parts[1] : null;
    initialLocale = Locale(languageCode, countryCode);
  }
  final ThemeMode initialThemeMode = _themeModeFromString(savedThemeMode);

  final overrides = <Override>[
    localeProvider.overrideWith((ref) => initialLocale),
    themeProvider.overrideWith((ref) => initialThemeMode),
  ];

  if (!kIsWeb && isar != null) {
    overrides.add(
      isarProvider.overrideWith((ref) {
        ref.onDispose(() => isar.close());
        return isar;
      }),
    );
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightTheme = _buildLightTheme();
    final darkTheme = _buildDarkTheme();
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthBuddy AI',
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.tealAccent,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF080A0E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF080A0E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF12161C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.white70),
      ),
    );
  }
}

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}
