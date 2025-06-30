import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});
  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _ghostController = TextEditingController();
  final FocusNode _ghostFocusNode = FocusNode();
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  List<Map<String, dynamic>> Pantrys = [];
  String? selectedListId;
  List<Map<String, dynamic>> items = [];
  Map<String, TextEditingController> controllerMap = {};

  @override
  void initState() {
    super.initState();
    fetchPantrys();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  Future<void> createPantry(String name, List<String> userIds) async {
    try {
      await _firestore.collection('Pantrys').add({
        'name': name,
        'sharedWith': userIds,
      });

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
      final snapshot =
          await _firestore
              .collection('Pantrys')
              .where('sharedWith', arrayContains: userId)
              .get();
      setState(() {
        Pantrys =
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
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
            items =
                snapshot.docs
                    .map((doc) => {'id': doc.id, ...doc.data()})
                    .toList();

            for (var item in items) {
              final id = item['id'];
              final existing = controllerMap[id];

              if (existing == null) {
                controllerMap[id] = TextEditingController(text: item['item']);
              } else if (existing.text != item['item'] &&
                  controllerMap[id]!.selection.isCollapsed) {
                // Only update if not editing (cursor not active)
                if (existing.text != item['item'] &&
                    existing.selection.baseOffset ==
                        existing.selection.extentOffset) {
                  final oldSelection = existing.selection;
                  existing.text = item['item'];
                  existing.selection = oldSelection;
                }
              }
            }

            // Clean up unused controllers
            controllerMap.removeWhere(
              (id, _) => !items.any((item) => item['id'] == id),
            );
          });
        });
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final item = items[oldIndex];

    // Temporarily reorder the list to compute new orders
    final reordered = [...items];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final batch = _firestore.batch();
    for (int i = 0; i < reordered.length; i++) {
      final docRef = _firestore
          .collection('Pantrys')
          .doc(selectedListId)
          .collection('items')
          .doc(reordered[i]['id']);
      batch.update(docRef, {'order': i});
    }

    await batch.commit();
  }

  Future<void> addItemToList(String listId, String itemName) async {
    await _firestore.collection('Pantrys').doc(listId).collection('items').add({
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

  Future<void> removeItemById(String listId, String itemId) async {
    await _firestore
        .collection('Pantrys')
        .doc(listId)
        .collection('items')
        .doc(itemId)
        .delete();

    setState(() {
      final index = items.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        items.removeAt(index);
        controllerMap.remove(itemId)?.dispose();
      }
    });
  }

  // adding delete function
  Future<void> removePantry(String pantryId) async {
    try {
      // Delete all subcollection items first
      final itemsSnapshot =
          await _firestore
              .collection('Pantrys')
              .doc(pantryId)
              .collection('items')
              .get();

      for (var doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the pantry itself
      await _firestore.collection('Pantrys').doc(pantryId).delete();

      // If the deleted pantry was selected, reset selection
      if (selectedListId == pantryId) {
        selectedListId = null;
        items.clear();
      }

      fetchPantrys(); // Refresh pantry list
    } catch (e) {
      print('Error deleting pantry: $e');
    }
  }

  @override
  void dispose() {
    _ghostController.dispose();
    _ghostFocusNode.dispose();
    for (final controller in controllerMap.values) {
      controller.dispose();
    }
    super.dispose();

    _rotationController
        .dispose(); // for removing the animation of the  trash can
  }

  Widget buildItem(int index, {required Key key}) {
    final item = items[index];
    final controller = controllerMap[item['id']]!;

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
        if (selectedListId != null) removeItemById(selectedListId!, item['id']);
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
            if (selectedListId != null)
              updateItem(selectedListId!, index, value);
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
      appBar: AppBar(title: const Text('Pantry')),
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
              onTap: () {
                Navigator.pushNamed(context, '/shopping');
              },
            ),

            ListTile(
              title: const Text('Recipe'),
              onTap: () {
                Navigator.pushNamed(context, '/ai');
              },
            ),
            ListTile(
              title: const Text('Friends'),
              onTap: () {
                Navigator.pushNamed(context, '/friends');
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
        ),
      ),

      // body
      body: Column(
        children: [
          // List selector
          if (Pantrys.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedListId,
                      hint: Text('Select a pantry'),
                      items:
                          Pantrys.map((list) {
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
                  if (selectedListId != null)
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: child,
                        );
                      },
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Pantry',
                        onPressed: () async {
                          _rotationController.forward(from: 0); // Start wiggle

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Delete Pantry'),
                                  content: Text(
                                    'Are you sure you want to delete this pantry?',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                    ),
                                    TextButton(
                                      child: Text('Delete'),
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true && selectedListId != null) {
                            await removePantry(selectedListId!);
                          }
                        },
                      ),
                    ),
                ],
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
                  builder:
                      (context) => AlertDialog(
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
                    builder:
                        (context) => AlertDialog(
                          title: Text('Share Pantry'),
                          content: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'User UID to share with',
                            ),
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
                                      SnackBar(
                                        content: Text(
                                          'List shared with UID $uid',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error sharing: $e'),
                                      ),
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
                onReorder:
                    (oldIndex, newIndex) => reorderItems(oldIndex, newIndex),
                children: [
                  for (int index = 0; index < items.length; index++)
                    buildItem(index, key: ValueKey(items[index]['id'])),
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
