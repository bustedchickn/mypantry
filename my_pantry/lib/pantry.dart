import 'package:flutter/material.dart';

class PantryPage extends StatelessWidget {
  const PantryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pantry")),
      body: Center(
        child: Column(
        children: <Widget>[
          Text('pantry page'),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FilledButton.tonalIcon(
                  
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: Icon(Icons.home, color: Colors.red),
                  label: const Text('welcome page')
                ),
                FilledButton.tonalIcon(
                  
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/shopping');
                  },
                  icon: Icon(Icons.shopping_bag, color: Colors.green),
                  label: const Text('shopping page')
                ),
                FilledButton.icon(
                  
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/pantry');
                  },
                  icon: Icon(Icons.shelves, color: Colors.blue),
                  label: const Text('pantry page')
                ),
              ]
            ),
          )
        ])
      )
    );
  }
}