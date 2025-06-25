import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<String?> _getUsername(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['name'];
    }
    return null;
  }
  void _showChangeEmailDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Email"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "New Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Current Password"),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newEmail = emailController.text.trim();
                final password = passwordController.text;
                final user = FirebaseAuth.instance.currentUser;

                if (newEmail.isEmpty || password.isEmpty || user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required.")),
                  );
                  return;
                }

                try {
                  // Reauthenticate
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: password,
                  );
                  await user.reauthenticateWithCredential(cred);

                  // Update email
                  await user.updateEmail(newEmail);

                  // Optional: update in Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'email': newEmail});

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email updated successfully.')),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: FutureBuilder<String?>(
        future: _getUsername(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final username = snapshot.data ?? 'Not set';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: $username'),
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
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && user.email != null) {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset email sent.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to send reset email.')),
                      );
                    }
                  },
                  child: const Text('Change Password'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showChangeEmailDialog(context);
                  },
                  child: const Text("Change Email"),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
