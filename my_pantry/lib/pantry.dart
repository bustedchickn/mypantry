import 'package:flutter/material.dart';

class PantryPage extends StatelessWidget {
  const PantryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pantry")),
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
                Navigator.pushReplacementNamed(context, '/pantry');
              },
            ),

            ListTile(
              title: const Text('Settings'),
              onTap: () {

              },
            ),

            ListTile(
              title: const Text('Sign out'),
              onTap: () {

              },
            ),

          ],
        )
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text('pantry page'),
            
            // this is the Bottom Navigation bar
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
                        child: const Text('new page(does not do anything right now)')
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
                ]
              ),
            )
          ]
        )
      )
    );
  }
}