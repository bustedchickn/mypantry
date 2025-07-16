import 'package:qr_flutter/qr_flutter.dart';
import 'package:my_pantry/qrcode.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_pantry/widgets/appdrawer.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  void declineFriendRequest(String requesterId) {
  FirebaseFirestore.instance
      .collection('users')
      .doc(currentUid)
      .collection('friendRequests')
      .doc(requesterId)
      .delete();
}

  Future<void> removeFriend(String friendId) async {
    final batch = FirebaseFirestore.instance.batch();

    final myRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
    final theirRef = FirebaseFirestore.instance.collection('users').doc(friendId);

    batch.update(myRef, {
      'friends': FieldValue.arrayRemove([friendId])
    });
    batch.update(theirRef, {
      'friends': FieldValue.arrayRemove([currentUid])
    });

    await batch.commit();
  }


  final friendCodeController = TextEditingController();

  String? currentUid;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<String?> _getFriendName(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] ?? uid;
  }

  Future<void> sendFriendRequest(String friendCode) async {
    if (friendCode.trim().isEmpty || currentUid == null) return;

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
    if (friendId == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't friend yourself.")),
      );
      return;
    }

    final requestRef = FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .collection('friendRequests')
        .doc(currentUid);

    await requestRef.set({
      'from': currentUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Friend request sent!")),
    );

    friendCodeController.clear();
  }

  Future<void> acceptFriendRequest(String requesterId) async {
    if (currentUid == null) return;

    final batch = FirebaseFirestore.instance.batch();

    final myDoc = FirebaseFirestore.instance.collection('users').doc(currentUid);
    final friendDoc = FirebaseFirestore.instance.collection('users').doc(requesterId);
    final requestDoc = myDoc.collection('friendRequests').doc(requesterId);

    batch.update(myDoc, {
      'friends': FieldValue.arrayUnion([requesterId])
    });

    batch.update(friendDoc, {
      'friends': FieldValue.arrayUnion([currentUid])
    });

    batch.delete(requestDoc);

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends & Requests')),
      // nav drawer
      endDrawer: AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Friend Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUid)
                  .collection('friendRequests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final requests = snapshot.data!.docs;

                if (requests.isEmpty) return const Text('No friend requests');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    
                    final requesterId = requests[index].id;
                    return FutureBuilder<String?>(
                      future: _getFriendName(requesterId),
                      builder: (context, nameSnapshot) {
                        final name = nameSnapshot.data ?? requesterId;
                        return ListTile(
                          title: Text(name),
                          // subtitle: Text(requesterId),
                          trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () => acceptFriendRequest(requesterId),
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => declineFriendRequest(requesterId),
                              child: const Text('Decline'),
                            ),
                          ],
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final doc = snapshot.data!;
                final friendIds = List<String>.from(doc['friends'] ?? []);

                if (friendIds.isEmpty) return const Text('No friends yet');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friendIds.length,
                  itemBuilder: (context, index) {
                    final friendId = friendIds[index];
                    return FutureBuilder<String?>(
                      future: _getFriendName(friendId),
                      builder: (context, nameSnapshot) {
                        final name = nameSnapshot.data ?? friendId;
                        return ListTile(
                          title: Text(name),
                          // subtitle: Text(friendId),
                          trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => removeFriend(friendId),
                        ),

                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Send a Friend Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: friendCodeController,
                    decoration: const InputDecoration(labelText: 'Enter Friend Code'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => sendFriendRequest(friendCodeController.text),
                  child: const Text('Send'),
                ),
                
              ],
            ),
            
          ],
        ),
      ),
    );
  }
}
