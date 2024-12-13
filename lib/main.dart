import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:smart_gallery/pages/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;
  bool useMaterial3 = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const FlexScheme usedScheme = FlexScheme.brandBlue;
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Main MaterialApp',
        theme: FlexThemeData.light(
          scheme: usedScheme,
          appBarElevation: 0.5,
          useMaterial3: useMaterial3,
        ),
        darkTheme: FlexThemeData.dark(
          scheme: usedScheme,
          appBarElevation: 2,
          useMaterial3: useMaterial3,
        ),
        themeMode: themeMode,
        home: const HomePage());
  }
}
