import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_pantry/widgets/shared_users_list.dart';


class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});
  @override
  State<ShoppingListPage> createState() => ShoppingListPageState();
  
}

class ShoppingListPageState extends State<ShoppingListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _ghostController = TextEditingController();
  final FocusNode _ghostFocusNode = FocusNode();

  List<Map<String, dynamic>> shoppingLists = [];
  String? selectedListId;
  List<Map<String, dynamic>> items = [];
  Map<String, TextEditingController> controllerMap = {};

  String? get selectedListName => selectedListId != null
    ? shoppingLists.firstWhere((p) => p['id'] == selectedListId, orElse: () => {'name': ''})['name']
    : null;


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
        .collection('Pantries')
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
      .collection('Pantries')  // Note: spelling matches your collection
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
        .collection('Pantries')
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


  Future<void> showFriendShareDialog(BuildContext context, String listId) async {
  final currentUid = FirebaseAuth.instance.currentUser!.uid;
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
  final friendIds = List<String>.from(userDoc.data()?['friends'] ?? []);

  Map<String, String> friendNames = {};

  // Fetch friend names
  for (var id in friendIds) {
    final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
    final name = doc.data()?['name'] ?? id;
    friendNames[id] = name;
  }

  final selected = <String>{};

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Share List With Friends'),
      content: SingleChildScrollView(
        child: Column(
          children: friendIds.map((id) {
            return CheckboxListTile(
              value: selected.contains(id),
              title: Text(friendNames[id]!),
              onChanged: (bool? value) {
                if (value == true) {
                  selected.add(id);
                } else {
                  selected.remove(id);
                }
                // Needed to refresh dialog UI
                (context as Element).markNeedsBuild();
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              for (var uid in selected) {
                await addUserToList(listId, uid);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('List shared with ${selected.length} friend(s).')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error sharing: $e')),
              );
            }
          },
          child: const Text('Share'),
        ),
      ],
    ),
  );
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

  final shouldShowSendButton = false;
  Widget buildItem(int index, {required Key key}) {
  final item = items[index];
  final controller = controllerMap[item['id']]!;

  return Dismissible(
    key: key,
    direction: DismissDirection.endToStart,
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    onDismissed: (direction) {
      if (selectedListId != null) removeItemById(selectedListId!, item['id']);
    },

    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9), // ✅ frosted patch for each item
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3), // 💡 white glow
            blurRadius: 12, // strength of blur
            spreadRadius: 1, // how far it spreads
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: item['checked'],
          onChanged: (_) {
            if (selectedListId != null) toggleCheck(selectedListId!, index);
          },
        ),
        title: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Item',
          ),
          onChanged: (value) {
            if (selectedListId != null) {
              updateItem(selectedListId!, index, value);
            }
          },
        ),
        trailing: const Icon(Icons.drag_handle),
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';




  return Column(
    children: [
      // 🧰 Shopping list management section
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Card(
          elevation: 2,
          // color: Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            // color: Color.fromARGB(255, 255, 255, 255),
            child: ExpansionTile(
            title: const Text('Manage Shopping List'),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (shoppingLists.isNotEmpty)
                      DropdownButton<String>(
                        value: selectedListId,
                        hint: const Text('Select a list'),
                        isExpanded: true,
                        items: shoppingLists.map((list) {
                          return DropdownMenuItem<String>(
                            value: list['id'],
                            child: Text(list['name'] ?? 'Unnamed List'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedListId = value);
                          if (value != null) listenToItems(value);
                        },
                      ),
                    const SizedBox(height: 8),

                    // Create new shopping list
                    ElevatedButton(
                      onPressed: () async {
                        final controller = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Create Shopping List'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(hintText: 'List name'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (controller.text.trim().isNotEmpty) {
                                    createShoppingList(controller.text.trim(), [userId]);
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Create'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Create New List'),
                    ),
                    const SizedBox(height: 8),

                    if (selectedListId != null) ...[
                      ElevatedButton(
                        onPressed: () => showFriendShareDialog(context, selectedListId!),
                        child: const Text('Share This List'),
                      ),
                      const SizedBox(height: 8),
                      SharedUsersList(listId: selectedListId!),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        
          ),
          
        ),
      ),

      if (selectedListId != null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0),
    child: ElevatedButton.icon(
      onPressed: () async {
        final checkedItems = items.where((item) => item['checked'] == true).toList();

        if (checkedItems.isEmpty) {
          await showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text('Nothing selected'),
              content: Text('Please check items to add to the pantry.'),
            ),
          );
          return;
        }

        moveCheckedItemsToPantry();
      },
      icon: const Icon(Icons.move_to_inbox),
      label: const Text('Add Checked Items to Pantry'),
    ),
  ),

      const Divider(),

      // 📝 Shopping list items
      if (selectedListId != null)
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) => reorderItems(oldIndex, newIndex),
            children: [
              for (int index = 0; index < items.length; index++)
                buildItem(index, key: ValueKey(items[index]['id'])),
            ],
          ),
        ),

      // ➕ Add item field
      
        if (selectedListId != null)
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ghostController,
          focusNode: _ghostFocusNode,
          decoration: const InputDecoration(
            hintText: 'Add item...',
            border: OutlineInputBorder(),
            filled: true,

          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              addItemToList(selectedListId!, value.trim());
              _ghostController.clear();
            }
            FocusScope.of(context).requestFocus(_ghostFocusNode);
          },
        ),

        const SizedBox(height: 8),

        if (shouldShowSendButton)
          ElevatedButton(
            onPressed: () async {
              final selectedIngredients = items
                  .where((item) => item['checked'] == true)
                  .map<String>((item) => item['item'].toString())
                  .toList();

              if (selectedIngredients.isEmpty) {
                await showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('Nothing selected'),
                    content: Text('Please check ingredients to send.'),
                  ),
                );
                return;
              }

              Navigator.pushNamed(
                context,
                '/ai',
                arguments: selectedIngredients,
              );
            },
            child: const Text('Send Selected Ingredients'),
          )
        else
          // 👇 Reserve same height as the button so layout stays consistent
          const SizedBox(height: 48), // match button height
      ],
    ),
  ),

    ],
  );
}
}
