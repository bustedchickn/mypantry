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
  List<Map<String, dynamic>> shoppingList = [];
  final FocusNode _ghostFocusNode = FocusNode();
  final TextEditingController _ghostController = TextEditingController();
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    fetchShoppingList();
  }

  Future<void> fetchShoppingList() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await _firestore
        .collection('shoppingList')
        .where('userId', isEqualTo: userId) // Filter by userId
        .get();
    setState(() {
      shoppingList = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      controllers = shoppingList
          .map((item) => TextEditingController(text: item['item']))
          .toList();
    });
  }

  Future<void> addItem(String itemName) async {
    if (itemName.trim().isEmpty) return;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = await _firestore.collection('shoppingList').add({
      'item': itemName.trim(),
      'checked': false,
      'userId': userId, // Add userId field
    });
    setState(() {
      shoppingList.add({'id': docRef.id, 'item': itemName.trim(), 'checked': false, 'userId': userId});
      controllers.add(TextEditingController(text: itemName.trim()));
      _ghostController.clear();
    });
  }

  Future<void> updateItem(int index, String newText) async {
    final id = shoppingList[index]['id'];
    await _firestore.collection('shoppingList').doc(id).update({'item': newText});
    setState(() {
      shoppingList[index]['item'] = newText;
    });
  }

  Future<void> toggleCheck(int index) async {
    final id = shoppingList[index]['id'];
    final newCheckedValue = !shoppingList[index]['checked'];
    await _firestore.collection('shoppingList').doc(id).update({'checked': newCheckedValue});
    setState(() {
      shoppingList[index]['checked'] = newCheckedValue;
    });
  }

  Future<void> removeItem(int index) async {
    final id = shoppingList[index]['id'];
    await _firestore.collection('shoppingList').doc(id).delete();
    setState(() {
      shoppingList.removeAt(index);
      controllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _ghostController.dispose();
    _ghostFocusNode.dispose();
    super.dispose();
  }

  Widget buildItem(int index) {
    final item = shoppingList[index];
    final controller = controllers[index];

    return Dismissible(
      key: Key(item['item'] + index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        removeItem(index);
      },
      child: ListTile(
        leading: Checkbox(
          value: item['checked'],
          onChanged: (_) => toggleCheck(index),
        ),
        title: TextField(
          controller: controller,
          decoration: InputDecoration(border: InputBorder.none),
          onChanged: (value) => updateItem(index, value),
        ),
        trailing: Icon(Icons.drag_handle), // or leave empty
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shopping List')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: shoppingList.length,
              itemBuilder: (context, index) => buildItem(index),
            ),
          ),
          Divider(),
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
                addItem(value);
                // Refocus to keep adding
                FocusScope.of(context).requestFocus(_ghostFocusNode);
              },
            ),
          ),
          Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
            FilledButton.tonalIcon(
              
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              icon: Icon(Icons.home, color: Colors.red),
              label: const Text('welcome page')
            ),
            FilledButton.icon(
              
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/shopping');
              },
              icon: Icon(Icons.shopping_bag, color: Colors.green),
              label: const Text('shopping page'),
            ),
            FilledButton.tonalIcon(
              
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/pantry');
              },
              icon: Icon(Icons.shelves, color: Colors.blue),
              label: const Text('pantry page')
            ),]
          )),
        ],
      ),
    );
  }
}