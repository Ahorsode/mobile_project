import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/playground_screen.dart';
import 'screens/academy_screen.dart';
import 'providers/academy_provider.dart';

void main() {
  runApp(const PyQuestApp());
}

class PyQuestApp extends StatelessWidget {
  const PyQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AcademyProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PyQuest',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
          fontFamily: 'Inter',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/editor': (context) => const PlaygroundScreen(),
          '/academy': (context) => const AcademyScreen(),
        },
      ),
    );
  }
}
