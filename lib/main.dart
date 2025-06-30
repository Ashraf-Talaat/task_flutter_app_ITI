import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDd4zjDT4iJAnJkjVEOlHLfziGqd_I8jMo",
        authDomain: "day6app-8a968.firebaseapp.com",
        projectId: "day6app-8a968",
        storageBucket: "day6app-8a968.appspot.com",
        messagingSenderId: "692758498288",
        appId: "1:692758498288:web:30e6bd629e69c008476b35",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  final user = FirebaseAuth.instance.currentUser;

  runApp(MyApp(startScreen: user != null ? HomeScreen() : SplashScreen()));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blog App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: startScreen,
    );
  }
}
