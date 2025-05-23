
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:my_pantry/pantry.dart';
import 'package:my_pantry/sign_in.dart';
import 'package:my_pantry/welcome.dart';
import 'package:my_pantry/shopping.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

try {
    // Hard-coded email and password
    const String hardCodedEmail = "test@email.com";
    const String hardCodedPassword = "password123";

    // Sign in with email and password
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: hardCodedEmail,
      password: hardCodedPassword,
    );

    print("Signed in as: ${userCredential.user?.uid}");
  } catch (e) {
    print("Error signing in: $e");
  }
  
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
      // on the SignInPage widget.
      initialRoute: '/',
      routes: {
        '/': (context) => const Welcome(),
        '/sign in': (context) => const SignInPage(),
        '/pantry': (context) => const PantryPage(),
        '/shopping': (context) => const ShoppingListPage(),
      },
    );
  }
}
