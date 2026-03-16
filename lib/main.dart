import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'presentation/theme/app_theme.dart';
import 'presentation/screens/feed_screen.dart';
import 'presentation/screens/customization_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/match_screen.dart';
import 'presentation/providers/auth_state.dart';
import 'package:rive/rive.dart' as rive;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();

  await Supabase.initialize(
    url: 'https://jyvcvvuwvwtpkyfxokxo.supabase.co',
    anonKey: 'sb_publishable_cAd9XUyMBecXzq0b6IZUcA_EpZhQ07J',
  );

  // Handle deep links for OAuth callbacks (e.g. Google Sign-In on Android/iOS)
  final appLinks = AppLinks();

  // Handle the initial link if the app was launched via a deep link
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
  }

  // Listen to subsequent links while the app is running
  appLinks.uriLinkStream.listen((uri) {
    Supabase.instance.client.auth.getSessionFromUrl(uri);
  });

  runApp(const ProviderScope(child: PatataCalienteApp()));
}

class PatataCalienteApp extends ConsumerWidget {
  const PatataCalienteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Patata Caliente',
      theme: AppTheme.playfulTheme,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainNavigationWrapper();
          }
          return const LoginScreen();
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) =>
            Scaffold(body: Center(child: Text('Error: $error'))),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const MatchScreen(), // Removed matchId parameter as it's not supported by MatchScreen
    const CustomizationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dynamic_feed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Play'),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom),
              label: 'Wardrobe',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
