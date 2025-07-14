import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_pantry/widgets/shared_users_list.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});
  @override
  State<PantryPage> createState() => PantryPageState();
}

class PantryPageState extends State<PantryPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _ghostController = TextEditingController();
  final FocusNode _ghostFocusNode = FocusNode();
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  List<Map<String, dynamic>> pantries = [];
  String? selectedListId;
  List<Map<String, dynamic>> shoppingLists = [];
  String? selectedShoppingListId;

  List<Map<String, dynamic>> items = [];
  Map<String, TextEditingController> controllerMap = {};

  @override
  void initState() {
    super.initState();
    fetchPantries();
    fetchShoppingLists();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }
  String? get selectedListName => selectedListId != null
    ? pantries.firstWhere((p) => p['id'] == selectedListId, orElse: () => {'name': ''})['name']
    : null;
    

  Future<void> createPantry(String name, List<String> userIds) async {
    try {
      await _firestore.collection('Pantries').add({
        'name': name,
        'sharedWith': userIds,
      });

      fetchPantries();
    } catch (e) {
      print('Error creating pantry: $e'); // Debugging log
    }
  }

  Future<void> addUserToList(String listId, String userId) async {
    print("This is a test");
    await _firestore.collection('Pantries').doc(listId).update({
      'sharedWith': FieldValue.arrayUnion([userId]),
    });
    fetchPantries();
  }
  Future<void> fetchShoppingLists() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final snapshot = await _firestore
      .collection('shoppingLists')
      .where('sharedWith', arrayContains: userId)
      .get();

  setState(() {
    shoppingLists =
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    if (shoppingLists.isNotEmpty && selectedShoppingListId == null) {
      selectedShoppingListId = shoppingLists.first['id'];
    }
  });
}


  Future<void> fetchPantries() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      print('Fetching pantries for user: $userId'); // Debugging log
      final snapshot =
          await _firestore
              .collection('Pantries')
              .where('sharedWith', arrayContains: userId)
              .get();
      setState(() {
        pantries =
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        print('Fetched pantries: $pantries'); // Debugging log
        if (pantries.isNotEmpty && selectedListId == null) {
          selectedListId = pantries.first['id'];
          listenToItems(selectedListId!);
        }
      });
    } catch (e) {
      print('Error fetching pantries: $e'); // Debugging log
    }
  }

  void listenToItems(String listId) {
    _firestore
        .collection('Pantries')
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
  void showCreatePantryDialog(String userId) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Create Pantry'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: 'Pantry name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
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
          .collection('Pantries')
          .doc(selectedListId)
          .collection('items')
          .doc(reordered[i]['id']);
      batch.update(docRef, {'order': i});
    }

    await batch.commit();
  }

  Future<void> addItemToList(String listId, String itemName) async {
    await _firestore.collection('Pantries').doc(listId).collection('items').add({
      'item': itemName,
      'checked': false,
      'order': items.length, // add to the end
    });
    listenToItems(listId);
  }

  Future<void> showMoveToShoppingListDialog() async {
  if (shoppingLists.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No shopping lists available!')),
    );
    return;
  }

  String? tempSelected = selectedShoppingListId ?? shoppingLists.first['id'];

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Shopping List'),
      content: DropdownButton<String>(
        value: tempSelected,
        isExpanded: true,
        items: shoppingLists.map((list) {
          return DropdownMenuItem<String>(
            value: list['id'],
            child: Text(list['name'] ?? 'Unnamed List'),
          );
        }).toList(),
        onChanged: (value) {
          tempSelected = value;
          (context as Element).markNeedsBuild(); // rebuild dialog
        },
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Move'),
          onPressed: () async {
            if (tempSelected != null) {
              setState(() {
                selectedShoppingListId = tempSelected;
              });
              Navigator.pop(context);
              await moveCheckedToShoppingList();
            }
          },
        ),
      ],
    ),
  );
}


  Future<void> moveCheckedToShoppingList() async {
  final pantryId = selectedListId;
  final shoppingListId = selectedShoppingListId;

  if (pantryId == null || shoppingListId == null) return;

  final checkedItems = items.where((item) => item['checked'] == true);

  final batch = _firestore.batch();

  for (final item in checkedItems) {
    final itemId = item['id'];
    final itemData = {
      'item': item['item'],
      'checked': false,
      'order': FieldValue.increment(1),
    };

    // Add to shopping list
    final shoppingItemRef = _firestore
        .collection('shoppingLists')
        .doc(shoppingListId)
        .collection('items')
        .doc();

    batch.set(shoppingItemRef, itemData);

    // Remove from pantry
    final pantryItemRef = _firestore
        .collection('Pantries')
        .doc(pantryId)
        .collection('items')
        .doc(itemId);

    batch.delete(pantryItemRef);
  }

  await batch.commit();
}


  Future<void> updateItem(String listId, int index, String newText) async {
    final id = items[index]['id'];
    await _firestore
        .collection('Pantries')
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
        .collection('Pantries')
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
        .collection('Pantries')
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

    // wiggle animation
    _rotationController.repeat(period: const Duration(milliseconds: 600));
    Future.delayed(const Duration(seconds: 1), () {
      _rotationController.stop();
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





  // adding delete function
  Future<void> removePantry(String pantryId) async {
    try {
      // Delete all subcollection items first
      final itemsSnapshot =
          await _firestore
              .collection('Pantries')
              .doc(pantryId)
              .collection('items')
              .get();

      for (var doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the pantry itself
      await _firestore.collection('Pantries').doc(pantryId).delete();

      // If the deleted pantry was selected, reset selection
      if (selectedListId == pantryId) {
        selectedListId = null;
        items.clear();
      }

      fetchPantries(); // Refresh pantry list
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

  return Column(
    children: [
      // 🧰 Pantry management section
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: const Text('Manage Pantry'),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown + Delete icon
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedListId,
                            hint: const Text('Select a pantry'),
                            isExpanded: true,
                            items: pantries.map((list) {
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
                        ),
                        if (selectedListId != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Pantry',
                            onPressed: () => removePantry(selectedListId!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => showCreatePantryDialog(userId),
                          child: const Text('Create New Pantry'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedListId != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => showFriendShareDialog(context, selectedListId!),
                            child: const Text('Share This List'),
                          ),
                        ),
                    ]),
                    if (selectedListId != null) ...[
                      const SizedBox(height: 8),
                      SharedUsersList(
                        listId: selectedListId!,
                        collection: 'Pantries',
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (selectedListId != null && selectedShoppingListId != null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0),
    child: ElevatedButton.icon(
      icon: const Icon(Icons.shopping_cart),
      label: const Text('Add Checked Items to Shopping List'),
      onPressed: () async {
        final checkedItems = items.where((item) => item['checked'] == true).toList();

        if (checkedItems.isEmpty) {
          await showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text('Nothing selected'),
              content: Text('Please check items to move to the shopping list.'),
            ),
          );
          return;
        }

        showMoveToShoppingListDialog();
      },
    ),
  ),


      const Divider(),

      // 📝 Pantry item list
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
          child: TextField(
            controller: _ghostController,
            focusNode: _ghostFocusNode,
            decoration: const InputDecoration(
              hintText: 'Add item...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                addItemToList(selectedListId!, value.trim());
                _ghostController.clear();
              }
              FocusScope.of(context).requestFocus(_ghostFocusNode);
            },
          ),
        ),

      // 🚚 Send ingredients button
      if (selectedListId != null)
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
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
          return; // <-- stop here!
        }

        Navigator.pushNamed(
          context,
          '/ai',
          arguments: selectedIngredients,
        );
      },
      child: const Text('Send Selected Ingredients'),
    ),
  ),


      
    ],
  );
}
    }