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
                  Column(
                    children: <Widget>[
                      Icon(Icons.home, color: Colors.red),
                      TextButton(
                        
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: const Text('welcome page')
                      ),
                    ]
                  ),
                
                  Column(
                    children: <Widget>[
                      Icon(Icons.shopping_bag, color: Colors.green),
                      TextButton(
                        
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/shopping');
                        },
                        child: const Text('shopping page')
                      ),
                    ]
                  ),

                  Column(
                    children: <Widget>[
                      Icon(Icons.shelves, color: Colors.blue),
                      FilledButton(
                        
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/pantry');
                        },
                        child: const Text('pantry page')
                      ),
                    ]
                  ),
                ]
              ),
            )
          ]
        )
      )
    );
  }
}