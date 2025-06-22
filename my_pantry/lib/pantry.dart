import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});
  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _ghostController = TextEditingController();
  final FocusNode _ghostFocusNode = FocusNode();

  List<Map<String, dynamic>> Pantrys = [];
  String? selectedListId;
  List<Map<String, dynamic>> items = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    fetchPantrys();
    print('Fetching pantries on initState'); // Debugging log
  }

  Future<void> createPantry(String name, List<String> userIds) async {
    try {
      print('Creating pantry with name: $name'); // Debugging log
      await _firestore.collection('Pantrys').add({
        'name': name,
        'sharedWith': userIds,
      });
      print('Pantry created successfully'); // Debugging log
      fetchPantrys();
    } catch (e) {
      print('Error creating pantry: $e'); // Debugging log
    }
  }

  Future<void> addUserToList(String listId, String userId) async {
    print("This is a test");
    await _firestore.collection('Pantrys').doc(listId).update({
      'sharedWith': FieldValue.arrayUnion([userId]),
    });
    fetchPantrys();
  }

  Future<void> fetchPantrys() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      print('Fetching pantries for user: $userId'); // Debugging log
      final snapshot = await _firestore
          .collection('Pantrys')
          .where('sharedWith', arrayContains: userId)
          .get();
      setState(() {
        Pantrys = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        print('Fetched pantries: $Pantrys'); // Debugging log
        if (Pantrys.isNotEmpty && selectedListId == null) {
          selectedListId = Pantrys.first['id'];
          listenToItems(selectedListId!);
        }
      });
    } catch (e) {
      print('Error fetching pantries: $e'); // Debugging log
    }
  }

  void listenToItems(String listId) {
    _firestore
        .collection('Pantrys')
        .doc(listId)
        .collection('items')
        .orderBy('order')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        items = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        controllers = items
            .map((item) => TextEditingController(text: item['item']))
            .toList();
      });
    });
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
  if (newIndex > oldIndex) newIndex -= 1;

  final item = items.removeAt(oldIndex);
  final controller = controllers.removeAt(oldIndex);
  items.insert(newIndex, item);
  controllers.insert(newIndex, controller);

  // Update order field in Firestore
  final batch = _firestore.batch();
  for (int i = 0; i < items.length; i++) {
    final docRef = _firestore
        .collection('Pantrys')
        .doc(selectedListId)
        .collection('items')
        .doc(items[i]['id']);
    batch.update(docRef, {'order': i});
  }

  await batch.commit();
  setState(() {});
}


  Future<void> addItemToList(String listId, String itemName) async {
  await _firestore
      .collection('Pantrys')
      .doc(listId)
      .collection('items')
      .add({
    'item': itemName,
    'checked': false,
    'order': items.length, // add to the end
  });
  listenToItems(listId);
  }


  Future<void> updateItem(String listId, int index, String newText) async {
    final id = items[index]['id'];
    await _firestore
        .collection('Pantrys')
        .doc(listId)
        .collection('items')
        .doc(id)
        .update({'item': newText});
    setState(() {
      items[index]['item'] = newText;
    });
  }

  Future<void> toggleCheck(String listId, int index) async {
    final id = items[index]['id'];
    final newCheckedValue = !items[index]['checked'];
    await _firestore
        .collection('Pantrys')
        .doc(listId)
        .collection('items')
        .doc(id)
        .update({'checked': newCheckedValue});
    setState(() {
      items[index]['checked'] = newCheckedValue;
    });
  }

  Future<void> removeItem(String listId, int index) async {
    final id = items[index]['id'];
    await _firestore
        .collection('Pantrys')
        .doc(listId)
        .collection('items')
        .doc(id)
        .delete();
    setState(() {
      items.removeAt(index);
      controllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _ghostController.dispose();
    _ghostFocusNode.dispose();
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget buildItem(int index, {required Key key}) {
    final item = items[index];
    final controller = controllers[index];

    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (selectedListId != null) removeItem(selectedListId!, index);
      },
      child: ListTile(
        leading: Checkbox(
          value: item['checked'],
          onChanged: (_) {
            if (selectedListId != null) toggleCheck(selectedListId!, index);
          },
        ),
        title: TextField(
          controller: controller,
          decoration: InputDecoration(border: InputBorder.none),
          onChanged: (value) {
            if (selectedListId != null) updateItem(selectedListId!, index, value);
          },
        ),
        trailing: Icon(Icons.drag_handle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Lists'),
      ),
      // this is the drawer next to the appbar
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.yellow),
              child: Text('Drawer Header'),
            ),

            ListTile(
              title: const Text('Pantry'),
              onTap: () {
                Navigator.pushNamed(context, '/pantry');
              },
            ),

            ListTile(
              title: const Text('Shopping List'),
              onTap: (){
                Navigator.pushNamed(context, '/shopping');
              },
            ),

            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),

            ListTile(
              title: const Text('Sign out'),
              onTap: () {
                Navigator.pushNamed(context, '/sign_in');
              },
            ),

          ],
        )
      ),

      // body
      body: Column(
        children: [
          // List selector
          if (Pantrys.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedListId,
                hint: Text('Select a pantry'),
                items: Pantrys.map((list) {
                  return DropdownMenuItem<String>(
                    value: list['id'],
                    child: Text(list['name'] ?? 'Unnamed List'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedListId = value;
                  });
                  if (value != null) listenToItems(value);
                },
              ),
            ),
          // Create new list
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                final controller = TextEditingController();
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Create Pantry'),
                    content: TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: 'Pantry name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            createPantry(controller.text.trim(), [userId]);
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Create'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Create New Pantry'),
            ),
          ),
          // Add user to list
          if (selectedListId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Share Pantry'),
                      content: TextField(
                        controller: controller,
                        decoration: InputDecoration(hintText: 'User UID to share with'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final uid = controller.text.trim();
                            if (uid.isNotEmpty) {
                              try {
                                await addUserToList(selectedListId!, uid);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('List shared with UID $uid')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error sharing: $e')),
                                );
                              }
                            }
                          },
                          child: Text('Share'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Share This Pantry'),
              ),
            ),
          Divider(),
          // Items
          if (selectedListId != null)
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) => reorderItems(oldIndex, newIndex),
                children: [
                  for (int index = 0; index < items.length; index++)
                    buildItem(index, key: ValueKey(items[index]['id']))
                ],
              ),
            ),
          if (selectedListId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _ghostController,
                focusNode: _ghostFocusNode,
                decoration: InputDecoration(
                  hintText: 'Add item...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (selectedListId != null && value.trim().isNotEmpty) {
                    addItemToList(selectedListId!, value.trim());
                    _ghostController.clear();
                  }
                  FocusScope.of(context).requestFocus(_ghostFocusNode);
                },
              ),
            ),

            // this is the Bottom Navigation bar
            
        ],
      ),
    );
  }
}