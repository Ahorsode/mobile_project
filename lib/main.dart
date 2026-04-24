import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/playground_screen.dart';
import 'screens/academy_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/world_map_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'providers/academy_provider.dart';
import 'providers/code_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/quest_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AcademyProvider()),
        ChangeNotifierProvider(create: (_) => CodeProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => QuestProvider()),
      ],
      child: const PyQuestApp(),
    ),
  );
}

class PyQuestApp extends StatelessWidget {
  const PyQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PyQuest',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/editor': (context) => const PlaygroundScreen(),
        '/academy': (context) => const AcademyScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/quest': (context) => const WorldMapScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}
