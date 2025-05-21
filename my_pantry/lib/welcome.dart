import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('welcome to Shelf Together!')),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
              Navigator.pushNamed(context, '/sign in');
              },
                child: const Text('Sign in'),
            ),
            ElevatedButton(
              
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/pantry');
              },
              child: const Text('pantry page')
            ),
            ElevatedButton(
              
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/shopping');
              },
              child: const Text('shoppingList page')
            ),
          ]
        )
      ),
    );
  }
}