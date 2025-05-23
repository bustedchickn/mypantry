import 'package:flutter/material.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign in")),
      body: Center(
        child: Column(
          children: [
            Text("This is the Sign in Page"),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/sign up');
              }
              , child: Text('Sign up'))
          ]
        )
      )
    );
  }
}