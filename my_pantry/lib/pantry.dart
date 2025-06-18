import 'package:flutter/material.dart';
import 'package:my_pantry/shopping.dart';

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
              title: const Text('Shopping List'),
              onTap: (){
                Navigator.pushReplacementNamed(context, '/shopping');
              },
            ),

            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/settings');
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
            // put body of page here
            
          ]
        )
      )
    );
  }
}