import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: "AIzaSyDmR6KrX8_InPUeiOBzgkgdbUcem7Ydk9c",
      authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
      projectId: "mypantryproject",
      storageBucket: "YOUR_PROJECT_ID.appspot.com",
      messagingSenderId: "YOUR_SENDER_ID",
      appId: "YOUR_APP_ID",
      measurementId: "YOUR_MEASUREMENT_ID",
    );
  }
}