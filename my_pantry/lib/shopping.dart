import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});
  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _ghostController = TextEditingController();
  final FocusNode _ghostFocusNode = FocusNode();

  List<Map<String, dynamic>> shoppingLists = [];
  String? selectedListId;
  List<Map<String, dynamic>> items = [];
  Map<String, TextEditingController> controllerMap = {};


  @override
  void initState() {
    super.initState();
    fetchShoppingLists();
  }

  Future<void> createShoppingList(String name, List<String> userIds) async {
    await _firestore.collection('shoppingLists').add({
      'name': name,
      'sharedWith': userIds,
    });
    fetchShoppingLists();
  }

  Future<void> addUserToList(String listId, String userId) async {
    await _firestore.collection('shoppingLists').doc(listId).update({
      'sharedWith': FieldValue.arrayUnion([userId]),
    });
    fetchShoppingLists();
  }

  Future<void> fetchShoppingLists() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await _firestore
            .collection('shoppingLists')
            .where('sharedWith', arrayContains: userId)
            .get();
    setState(() {
      shoppingLists =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      // Select the first list by default
      if (shoppingLists.isNotEmpty && selectedListId == null) {
        selectedListId = shoppingLists.first['id'];
        listenToItems(selectedListId!);
      }
    });
  }

  void listenToItems(String listId) {
    _firestore
        .collection('shoppingLists')
        .doc(listId)
        .collection('items')
        .orderBy('order')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        items = snapshot.docs
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
              existing.selection.baseOffset == existing.selection.extentOffset) {
            final oldSelection = existing.selection;
            existing.text = item['item'];
            existing.selection = oldSelection;
          }

          }
        }

        // Clean up unused controllers
        controllerMap.removeWhere((id, _) => !items.any((item) => item['id'] == id));
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
          .collection('shoppingLists')
          .doc(selectedListId)
          .collection('items')
          .doc(reordered[i]['id']);
      batch.update(docRef, {'order': i});
    }

    await batch.commit();
  }

  Future<void> addItemToList(String listId, String itemName) async {
    await _firestore
        .collection('shoppingLists')
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
        .collection('shoppingLists')
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
        .collection('shoppingLists')
        .doc(listId)
        .collection('items')
        .doc(id)
        .update({'checked': newCheckedValue});
    setState(() {
      items[index]['checked'] = newCheckedValue;
    });
  }

  Future<void> moveCheckedItemsToPantry() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch all pantries shared with this user
    final pantrySnapshot = await _firestore
        .collection('Pantrys')
        .where('sharedWith', arrayContains: userId)
        .get();

    final pantryDocs = pantrySnapshot.docs;
    if (pantryDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pantries found.")),
      );
      return;
    }

    String? selectedPantryId;

    // Prompt the user to pick a pantry
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Select Pantry"),
            content: DropdownButton<String>(
              isExpanded: true,
              value: selectedPantryId,
              hint: const Text("Choose a pantry"),
              items: pantryDocs.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(doc['name'] ?? 'Unnamed Pantry'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPantryId = value;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: selectedPantryId != null
                    ? () => Navigator.of(context).pop()
                    : null,
                child: const Text("Move Items"),
              ),
            ],
          );
        });
      },
    );

    if (selectedPantryId == null) return;

    final batch = _firestore.batch();
    final checkedItems = items.where((item) => item['checked'] == true).toList();

      // 1. Get max order in pantry items first
  final pantryItemsSnapshot = await _firestore
      .collection('Pantrys')  // Note: spelling matches your collection
      .doc(selectedPantryId)
      .collection('items')
      .orderBy('order', descending: true)
      .limit(1)
      .get();

  int maxOrder = 0;
  if (pantryItemsSnapshot.docs.isNotEmpty) {
    maxOrder = pantryItemsSnapshot.docs.first.data()['order'] ?? 0;
  }

  int orderCounter = maxOrder + 1;

  for (var item in checkedItems) {
    final pantryItemRef = _firestore
        .collection('Pantrys')
        .doc(selectedPantryId)
        .collection('items')
        .doc();

    batch.set(pantryItemRef, {
      'item': item['item'],
      'checked': false,
      'order': orderCounter,
    });

    orderCounter++;  // increment for next item

    final shoppingItemRef = _firestore
        .collection('shoppingLists')
        .doc(selectedListId)
        .collection('items')
        .doc(item['id']);
    batch.delete(shoppingItemRef);
  }

  await batch.commit();


    

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Moved ${checkedItems.length} item(s) to pantry.")),
    );
  }



  Future<void> removeItemById(String listId, String itemId) async {
    await _firestore
        .collection('shoppingLists')
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

  @override
  void dispose() {
    _ghostController.dispose();
    _ghostFocusNode.dispose();
    for (final controller in controllerMap.values) {
      controller.dispose();
    }
    super.dispose();
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
            if (selectedListId != null){
                updateItem(selectedListId!, index, value);
              }
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
      appBar: AppBar(title: const Text('Shopping Lists')),
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

            ListTile(title: const Text('Settings'), onTap: () {
              Navigator.pushNamed(context, '/settings');
            }),

            ListTile(title: const Text('Sign out'), onTap: () {
              Navigator.pushNamed(context, '/sign_in');
            }),
          ],
        ),
      ),

      // body
      body: Column(
        children: [
          // List selector
          if (shoppingLists.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedListId,
                hint: Text('Select a list'),
                items:
                    shoppingLists.map((list) {
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
                  builder:
                      (context) => AlertDialog(
                        title: Text('Create Shopping List'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(hintText: 'List name'),
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
                                createShoppingList(controller.text.trim(), [
                                  userId,
                                ]);
                                Navigator.pop(context);
                              }
                            },
                            child: Text('Create'),
                          ),
                        ],
                      ),
                );
              },
              child: Text('Create New List'),
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
                          title: Text('Share List'),
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
                child: Text('Share This List'),
              ),
              
              
            ),
            if (selectedListId != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: moveCheckedItemsToPantry,
                  icon: const Icon(Icons.move_to_inbox),
                  label: const Text('Move Checked to Pantry'),
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
        ],
      ),
    );
  }
}
