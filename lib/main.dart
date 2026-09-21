import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() => runApp(const HistorialApp());

class HistorialApp extends StatelessWidget {
  const HistorialApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mi historial',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F8C)),
      scaffoldBackgroundColor: const Color(0xFFF4F7FA),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF4F7FA)),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    home: const WelcomeScreen(),
  );
}
