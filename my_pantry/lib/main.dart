import 'package:flutter/material.dart';
import 'package:my_pantry/pantry.dart';
import 'package:my_pantry/sign_in.dart';

void main() => runApp(const MyPantryApp());

class MyPantryApp extends StatelessWidget {
  const MyPantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      title: 'My Pantry',
      // Start the app with the "/" named route.
      // The app starts
      // on the SignInPage widget.
      initialRoute: '/',
      routes: {
        '/Sign in': (context) => const SignInPage(),
        '/': (context) => const PantryNav(),
      },
    );
  }
}
