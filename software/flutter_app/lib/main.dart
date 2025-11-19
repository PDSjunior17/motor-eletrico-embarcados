import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- Importe o dotenv
import 'screens/entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carrega o arquivo de segredos
  await dotenv.load(fileName: ".env");

  // 2. Inicializa o Firebase usando as variáveis carregadas
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '', 
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '', 
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '', 
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motor Control IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        primaryColor: Colors.blueAccent,
        fontFamily: 'Roboto',
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF555555)),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ),
      home: const EntryScreen(),
    );
  }
}
