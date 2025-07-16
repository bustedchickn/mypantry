import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final PageController? pageController; // null means fallback to Navigator

  const AppDrawer({super.key, this.pageController});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text(''),
          ),
          ListTile(
  title: const Text('Pantry'),
  onTap: () {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/homepager',
      (route) => false,
      arguments: {'initialPage': 0},
    );
  },
),
ListTile(
  title: const Text('Shopping List'),
  onTap: () {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/homepager',
      (route) => false,
      arguments: {'initialPage': 1},
    );
  },
),

          ListTile(
            title: const Text('Recipe'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/ai');
            },
          ),
          ListTile(
            title: const Text('Friends'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/friends');
            },
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            title: const Text('Sign out'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/sign_in');
            },
          ),
        ],
      ),
    );
  }
}
