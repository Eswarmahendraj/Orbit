import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'models/orbit_state.dart';
import 'services/spotify_service.dart';
import 'services/apple_music_service.dart';
import 'services/social_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/aura_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/privacy/app_disguise_screen.dart';
import 'widgets/web_scaffold.dart';

/// Global theme notifier — toggled from SettingsScreen.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

/// Global font scale notifier — adjusted from SettingsScreen (0.8–1.4).
final fontScaleNotifier = ValueNotifier<double>(1.0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await OrbitState().load();
  await SpotifyService().load(); // restore saved Spotify tokens
  await AppleMusicService().load(); // check saved Apple Music auth (iOS only)
  SocialService().upsertProfile(); // publish profile to Firestore (fire & forget)
  OrbitState().checkStreak();
  await NotificationService().init(); // FCM push notifications

  // Always dark-first; respect user override from settings
  AuraTheme.isDark = true;
  themeNotifier.value = ThemeMode.dark;

  // Restore saved font scale
  final prefs = await SharedPreferences.getInstance();
  fontScaleNotifier.value = prefs.getDouble('fontScale') ?? 1.0;
  // Restore app theme
  await ThemeService().load();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const OrbitApp());
}

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    final disguise = OrbitState().appDisguiseEnabled;
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (_, __) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) => ValueListenableBuilder<double>(
          valueListenable: fontScaleNotifier,
          builder: (_, scale, __) => MaterialApp(
            title: disguise ? 'Calculator' : 'Orbit',
            debugShowCheckedModeBanner: false,
            theme: ThemeService().themeData,
            darkTheme: ThemeService().themeData,
            themeMode: ThemeMode.dark,
            navigatorKey: navigatorKey,
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: disguise ? const AppDisguiseScreen() : const OrbitRoot(),
          ),
        ),
      ),
    );
  }
}

class OrbitRoot extends StatefulWidget {
  const OrbitRoot({super.key});
  @override
  State<OrbitRoot> createState() => _OrbitRootState();
}

class _OrbitRootState extends State<OrbitRoot> {
  bool _onboarded = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _onboarded = OrbitState().hasOnboarded;
    // Stay logged in if Firebase already has a current user OR user has onboarded
    _loggedIn = _onboarded || FirebaseAuth.instance.currentUser != null;
  }

  void _completeOnboarding() => setState(() => _onboarded = true);
  void _completeLogin() => setState(() => _loggedIn = true);

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return LoginScreen(onLoggedIn: _completeLogin);
    }
    if (!_onboarded) {
      return OnboardingScreen(onDone: _completeOnboarding);
    }
    return const ResponsiveRoot();
  }
}
