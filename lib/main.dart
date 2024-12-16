import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:smart_gallery/pages/home_page.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';

dynamic rawEmbeddingHive;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.instance.init();

  runApp(const MyApp());
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
          appBarElevation: 2,
          useMaterial3: useMaterial3,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.green,
            accentColor: Colors.greenAccent,
            cardColor: Colors.white,
            backgroundColor: Colors.white,
            errorColor: Colors.red[900],
            brightness: Brightness.light,
          ),
          appBarStyle: FlexAppBarStyle.primary,
        ),
        darkTheme: FlexThemeData.dark(
          scheme: usedScheme,
          appBarElevation: 2,
          useMaterial3: useMaterial3,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
            accentColor: Colors.blueAccent,
            cardColor: Colors.black,
            backgroundColor: Colors.black,
            errorColor: Colors.red[900],
            brightness: Brightness.dark,
          ),
          appBarStyle: FlexAppBarStyle.primary,
        ),
        home: const HomePage());
  }
}
