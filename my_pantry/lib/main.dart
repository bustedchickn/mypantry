import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:my_pantry/pantry.dart';
import 'package:my_pantry/sign_in.dart';


void main() async {
  
  //no Idea what this line does.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,// 
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
      // on the SignInPage widget.
      initialRoute: '/',
      routes: {
        '/Sign in': (context) => const SignInPage(),
        '/': (context) => const PantryNav(),
      },
    );
  }
}
