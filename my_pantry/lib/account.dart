import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: user == null
          ? const Center(child: Text('No user signed in'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user.displayName ?? "Not set"}'),
                  const SizedBox(height: 10),
                  Text('Email: ${user.email ?? "Not set"}'),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/sign_in', (route) => false);
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }
}
