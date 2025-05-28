import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to Shelf Together!')),
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