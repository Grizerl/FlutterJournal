import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_journal/widgets/sign_in_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAdQTb1o3iyZ_ZpHvwhrvD2P-97xk-t0tE",
        authDomain: "flutterdiary-b41ad.firebaseapp.com",
        projectId: "flutterdiary-b41ad",
        storageBucket: "flutterdiary-b41ad.firebaseapp.com",
        messagingSenderId: "619956224411",
        appId: "1:619956224411:web:4b53894f47d8b2b571613e",
      ),
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Journal',
      home: SignInScreen(),
    );
  }
}
