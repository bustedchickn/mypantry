import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:my_pantry/qrcode.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  Future<String?> _getFriendName(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] ?? uid;
  }

  Future<void> acceptFriendRequest(String requesterId) async {
    final myId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(myId).update({
      'friends': FieldValue.arrayUnion([requesterId])
    });

    await FirebaseFirestore.instance.collection('users').doc(requesterId).update({
      'friends': FieldValue.arrayUnion([myId])
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(myId)
        .collection('friendRequests')
        .doc(requesterId)
        .delete();
  }

  Future<List<String>> _getFriendIds(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || data['friends'] == null) return [];
    return List<String>.from(data['friends']);
  }

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Friends & Requests')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Friend Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(myId)
                  .collection('friendRequests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final requests = snapshot.data!.docs;

                if (requests.isEmpty) return const Text('No friend requests');

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final requesterId = requests[index].id;
                    return FutureBuilder<String?>(
                      future: _getFriendName(requesterId),
                      builder: (context, nameSnapshot) {
                        final name = nameSnapshot.data ?? requesterId;
                        return ListTile(
                          title: Text(name),
                          subtitle: Text(requesterId),
                          trailing: ElevatedButton(
                            onPressed: () => acceptFriendRequest(requesterId),
                            child: const Text('Accept'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Your Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _getFriendIds(myId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final friendIds = snapshot.data!;

                if (friendIds.isEmpty) return const Text('No friends yet');

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: friendIds.length,
                  itemBuilder: (context, index) {
                    final friendId = friendIds[index];
                    return FutureBuilder<String?>(
                      future: _getFriendName(friendId),
                      builder: (context, nameSnapshot) {
                        final name = nameSnapshot.data ?? friendId;
                        return ListTile(
                          title: Text(name),
                          subtitle: Text(friendId),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
