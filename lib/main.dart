import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';

// Packages Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importation de tes nouvelles pages
import 'signin.dart';
import 'signup.dart';
import 'home.dart';
import 'stock.dart';
import 'vocal.dart';
import 'image_classification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB_UCi1YSX_f3cu32Q3QgTM906rPRTqGu8",
        authDomain: "projet-cfa53.firebaseapp.com",
        projectId: "projet-cfa53",
        storageBucket: "projet-cfa53.firebasestorage.app",
        messagingSenderId: "685095271302",
        appId: "1:685095271302:android:a6fa0e602abc866a5a0a07",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.deepPurple;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chouchou App',
      themeMode: ThemeMode.system,
      
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),

      // Redirection selon la connexion
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/signin' : '/home',

      // Définition des routes avec les fichiers séparés
      routes: {
        '/signin': (_) => const SignInPage(),
        '/signup': (_) => const SignUpPage(),
        '/home': (_) => const HomePage(),
        '/stock': (_) => const StockPage(),
        '/vocal': (_) => const VocalPage(),
        '/image': (_) => const ImageClassificationPage(),
      },

      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const SignInPage(),
      ),
    );
  }
}