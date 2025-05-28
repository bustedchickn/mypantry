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
  List<TextEditingController> controllers = [];

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
    print("This is a test");
    await _firestore.collection('shoppingLists').doc(listId).update({
      'sharedWith': FieldValue.arrayUnion([userId]),
    });
    fetchShoppingLists();
  }

  Future<void> fetchShoppingLists() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await _firestore
        .collection('shoppingLists')
        .where('sharedWith', arrayContains: userId)
        .get();
    setState(() {
      shoppingLists = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      // Select the first list by default
      if (shoppingLists.isNotEmpty && selectedListId == null) {
        selectedListId = shoppingLists.first['id'];
        fetchItemsForList(selectedListId!);
      }
    });
  }

  Future<void> fetchItemsForList(String listId) async {
    final snapshot = await _firestore
        .collection('shoppingLists')
        .doc(listId)
        .collection('items')
        .get();
    setState(() {
      items = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      controllers = items
          .map((item) => TextEditingController(text: item['item']))
          .toList();
    });
  }

  Future<void> addItemToList(String listId, String itemName) async {
    await _firestore
        .collection('shoppingLists')
        .doc(listId)
        .collection('items')
        .add({
      'item': itemName,
      'checked': false,
    });
    fetchItemsForList(listId);
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

  Future<void> removeItem(String listId, int index) async {
    final id = items[index]['id'];
    await _firestore
        .collection('shoppingLists')
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

  Widget buildItem(int index) {
    final item = items[index];
    final controller = controllers[index];

    return Dismissible(
      key: Key(item['id']),
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
      appBar: AppBar(title: Text('Shopping Lists')),
      body: Column(
        children: [
          // List selector
          if (shoppingLists.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedListId,
                hint: Text('Select a list'),
                items: shoppingLists.map((list) {
                  return DropdownMenuItem<String>(
                    value: list['id'],
                    child: Text(list['name'] ?? 'Unnamed List'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedListId = value;
                  });
                  if (value != null) fetchItemsForList(value);
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
                            createShoppingList(controller.text.trim(), [userId]);
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
                    builder: (context) => AlertDialog(
                      title: Text('Share List'),
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
                child: Text('Share This List'),
              ),
            ),
          Divider(),
          // Items
          if (selectedListId != null)
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => buildItem(index),
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