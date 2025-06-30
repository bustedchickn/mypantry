import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:my_pantry/qrcode.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<String?> _getUsername(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['name'];
    }
    return null;
  }
  
  Future<String?> _getFriendCode(String uid) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (doc.exists) {
    return doc.data()?['friendCode'];
  }
  return null;
}
  Future<void> sendFriendRequest(BuildContext context, String friendCode) async {
  final myId = FirebaseAuth.instance.currentUser!.uid;

  if (friendCode.trim().isEmpty) return;

  final result = await FirebaseFirestore.instance
      .collection('users')
      .where('friendCode', isEqualTo: friendCode.trim())
      .limit(1)
      .get();

  if (result.docs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Friend code not found.")),
    );
    return;
  }

  final friendId = result.docs.first.id;
  if (friendId == myId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You can't friend yourself.")),
    );
    return;
  }

  // Write friend request
  final requestRef = FirebaseFirestore.instance
      .collection('users')
      .doc(friendId)
      .collection('friendRequests')
      .doc(myId);

  await requestRef.set({
    'from': myId,
    'timestamp': FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Friend request sent!")),
  );
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
                  await user.verifyBeforeUpdateEmail(newEmail);

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
                FutureBuilder<String?>(
                  future: _getFriendCode(user.uid),
                  builder: (context, codeSnapshot) {
                    if (codeSnapshot.connectionState != ConnectionState.done) {
                      return const CircularProgressIndicator();
                    }
                    final friendCode = codeSnapshot.data ?? 'Unavailable';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Text('Your Friend Code:'),
                        SelectableText(friendCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: QrImageView(
                            data: friendCode,
                            version: QrVersions.auto,
                            size: 150.0,
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final scannedCode = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const QRScannerPage()),
                            );

                            if (scannedCode != null && scannedCode is String) {
                              await sendFriendRequest(context, scannedCode);
                            }
                          },
                          child: const Text("Scan Friend's QR Code"),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            final controller = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Enter Friend Code'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(labelText: 'Friend Code'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final inputCode = controller.text.trim();
                                        Navigator.pop(context); // Close the dialog before adding
                                        await sendFriendRequest(context, inputCode);
                                      },
                                      child: const Text("Add Friend"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text("Add Friend Manually"),
                        ),

                      ],
                    );
                  },
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
