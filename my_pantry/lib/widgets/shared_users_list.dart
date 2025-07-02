import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharedUsersList extends StatelessWidget {
  final String listId;
  final String collection;

  const SharedUsersList({
    super.key,
    required this.listId,
    this.collection = 'shoppingLists',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(collection).doc(listId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null || !data.containsKey('sharedWith')) {
          return const Text('Not shared with anyone.');
        }

        final sharedUids = List<String>.from(data['sharedWith']);

        if (sharedUids.isEmpty) {
          return const Text('Not shared with anyone yet.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Shared With:', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            ...sharedUids.map((uid) => FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                  builder: (context, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading...'));
                    }

                    if (!userSnap.hasData || userSnap.data == null || !userSnap.data!.exists) {
                      return ListTile(
                        title: Text(uid),
                        subtitle: const Text('User not found'),
                      );
                    }

                    final name = userSnap.data!.get('name') ?? uid;

                    return ListTile(
                      dense: true,
                      title: Text(name),
                      // subtitle: Text(uid),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Access?'),
                              content: Text('Remove "$name" from shared list?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection(collection)
                                .doc(listId)
                                .update({
                              'sharedWith': FieldValue.arrayRemove([uid]),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$name removed from shared list.')),
                            );

                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    );
                  },
                )),
          ],
        );
      },
    );
  }
}
