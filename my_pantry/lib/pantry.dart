import 'package:flutter/material.dart';

class PantryNav extends StatefulWidget {
  const PantryNav({super.key});

  @override
  State<PantryNav> createState() => _PantryNavState();
}

class _PantryNavState extends State<PantryNav> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.deepPurpleAccent,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.shop_sharp)),
            label: 'Shopping List',
          ),
          NavigationDestination(
            icon: Badge(label: Text('2'), child: Icon(Icons.food_bank_sharp)),
            label: 'Pantry',
          ),
        ],
      ),
      body:
          <Widget>[
            /// Home page
              Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/Sign in');
                    },
                    child: const Text('Sign in')
                  )
                ),
              ),
            

            /// Shopping List page
            const Padding(
              padding: EdgeInsets.all(8.0),
              
            ),

            /// Pantry page
            const Padding(
              padding: EdgeInsets.all(8.0),
              
            ),
          ][currentPageIndex],
    );
  }
}