import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  
  //no Idea what this line does.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      home: ShoppingListPage(),
    );
  }
}

class ShoppingListPage extends StatefulWidget {
  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}


class _ShoppingListPageState extends State<ShoppingListPage> {
  List<Map<String, dynamic>> shoppingList = [];
  final FocusNode _ghostFocusNode = FocusNode();
  final TextEditingController _ghostController = TextEditingController();
  List<TextEditingController> controllers = [];

  void addItem(String itemName) {
    if (itemName.trim().isEmpty) return;
    setState(() {
      shoppingList.add({'item': itemName.trim(), 'checked': false});
      controllers.add(TextEditingController(text:itemName.trim()));
      _ghostController.clear();
    });
  }

  void updateItem(int index, String newText) {
    shoppingList[index]['item'] = newText;
    
  }

  void toggleCheck(int index) {
    setState(() {
      shoppingList[index]['checked'] = !shoppingList[index]['checked'];
    });
  }

  void removeItem(int index) {
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
        ],
      ),
    );
  }
}
