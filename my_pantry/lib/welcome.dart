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
                Navigator.pushNamed(context, '/pantrynav');
              },
              child: const Text('Go to App'))
          ]
        )
      ),
    );
  }
}