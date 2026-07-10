import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/orbit_state.dart';
import 'theme/aura_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/privacy/app_disguise_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const OrbitApp());
}

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final disguise = OrbitState().appDisguiseEnabled;
    return MaterialApp(
      title: disguise ? 'Calculator' : 'Orbit',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.dark,
      home: disguise ? const AppDisguiseScreen() : const HomeScreen(),
    );
  }
}
