// Basic Flutter widget test for Bay Navigator app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:baynavigator/providers/programs_provider.dart';
import 'package:baynavigator/providers/theme_provider.dart';
import 'package:baynavigator/providers/settings_provider.dart';
import 'package:baynavigator/providers/user_prefs_provider.dart';
import 'package:baynavigator/config/theme.dart';

void main() {
  testWidgets('App smoke test - renders navigation', (WidgetTester tester) async {
    // Build a minimal app with required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProgramsProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => UserPrefsProvider()),
        ],
        child: MaterialApp(
          title: 'Bay Navigator',
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const Center(child: Text('For You')),
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'For You'),
                NavigationDestination(icon: Icon(Icons.apps), label: 'Directory'),
                NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify navigation bar is present with 4 tabs
    expect(find.text('For You'), findsWidgets);
    expect(find.text('Directory'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Providers are accessible in widget tree', (WidgetTester tester) async {
    late ProgramsProvider programsProvider;
    late ThemeProvider themeProvider;
    late UserPrefsProvider userPrefsProvider;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProgramsProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => UserPrefsProvider()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              programsProvider = context.read<ProgramsProvider>();
              themeProvider = context.read<ThemeProvider>();
              userPrefsProvider = context.read<UserPrefsProvider>();
              return const Scaffold(body: Text('Test'));
            },
          ),
        ),
      ),
    );

    expect(programsProvider, isNotNull);
    expect(themeProvider, isNotNull);
    expect(userPrefsProvider, isNotNull);
    expect(programsProvider.programs, isEmpty);
  });
}
