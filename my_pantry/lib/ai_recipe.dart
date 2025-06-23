import 'package:flutter/material.dart';

class RecipePage extends StatelessWidget {
  const RecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your AI Recipe Helper')),

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

            ListTile(title: const Text('Settings'), onTap: () {
              Navigator.pushNamed(context, '/settings');
            }),

            ListTile(title: const Text('Sign out'), onTap: () {
              Navigator.pushNamed(context, '/sign_in');
            }),
          ],
        ),
      ),

      body: Center(
        child: Column(
          children: <Widget>[
            Text('This is your personal pantry app that will... (description here: )'),
            ElevatedButton(
              onPressed: () {
              Navigator.pushNamed(context, '/sign_in');
              },
                child: const Text('Sign in'),
            ),
          ]
        )
      ),
    );
  }
}