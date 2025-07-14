import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_pantry/screens/recipe_list_screen.dart';
import 'package:my_pantry/settings.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:my_pantry/pantry.dart';
import 'package:my_pantry/shopping.dart';
import 'package:my_pantry/sign_in.dart';
import 'package:my_pantry/sign_up.dart';
import 'package:my_pantry/account.dart';
import 'package:my_pantry/qrcode.dart';
import 'package:my_pantry/friend.dart';
import 'package:my_pantry/homepage.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase already initialized: $e");
  }

  runApp(MyPantryApp());
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
        '/friends': (context) => const FriendsPage(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/pantry': (context) => const PantryPage(),
        '/shopping': (context) => const ShoppingListPage(),
        '/settings':(context) => const SettingsPage(),
        '/account': (context) => const AccountPage(),
        '/ai':(context) => const RecipeListScreen(),
        '/qr':(context) => const QRScannerPage(),
        '/homepager':(context) => const HomePager(),
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
          return const HomePager(); // Signed in
        } else {
          return const SignInPage(); // Not signed in
        }
      },
    );
  }
}
