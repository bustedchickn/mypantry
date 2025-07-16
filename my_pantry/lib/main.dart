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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase already initialized: $e");
  }

  runApp(const MyPantryApp());
}

class MyPantryApp extends StatefulWidget {
  const MyPantryApp({super.key});

  @override
  State<MyPantryApp> createState() => _MyPantryAppState();
}

class _MyPantryAppState extends State<MyPantryApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: Color.fromARGB(255, 255, 151, 151),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        
        primaryColor: Color.fromARGB(255, 128, 17, 17),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      
      
      
      themeMode: _themeMode, // uses the state!
      title: 'My Pantry',
      home: const AuthWrapper(),
      routes: {
        '/friends': (context) => const FriendsPage(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/pantry': (context) => const PantryPage(),
        '/shopping': (context) => const ShoppingListPage(),
        '/settings': (context) => SettingsPage(toggleTheme: toggleTheme), // ✅ passes toggleTheme
        '/account': (context) => const AccountPage(),
        '/ai': (context) => const RecipeListScreen(),
        '/qr': (context) => const QRScannerPage(),
        '/homepager': (context) => const HomePager(),
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
          return const HomePager();
        } else {
          return const SignInPage();
        }
      },
    );
  }
}
