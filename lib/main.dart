import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://celldfiaorxajhqsxlgg.supabase.co',
    anonKey: 'sb_publishable_OvWZrsH1VOPIr8AQ_8fuxQ__Q3TGLiW',
  );

  runApp(const MyApp());
}

/// Convenience getter — use `supabase.from(...)` anywhere in the app
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryColor       = Color(0xFFBB243C); // Maroon Flush
  static const Color scaffoldBackground = Color(0xFFF2F0FA); // White Lilac

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bangladesh Tourist App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: scaffoldBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: scaffoldBackground,
        ),
        textTheme: const TextTheme(
          bodyLarge:  TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}