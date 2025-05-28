import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:my_pantry/pantry.dart';
import 'package:my_pantry/welcome.dart';
import 'package:my_pantry/shopping.dart';
import 'package:my_pantry/sign_in.dart';
import 'package:my_pantry/sign_up.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyPantryApp());
}

class MyPantryApp extends StatelessWidget {
  const MyPantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      title: 'My Pantry',
      // Start the app with the "/" named route.
      // The app starts
      // on the Welcome page.
      home: const AuthWrapper(),
      routes: {
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/pantry': (context) => const PantryPage(),
        '/shopping': (context) => const ShoppingListPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const PantryPage(); // Signed in
        } else {
          return const Welcome(); // Not signed in
        }
      },
    );
  }
}
