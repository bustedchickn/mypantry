import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        title: const Text('Settings'),
        automaticallyImplyLeading: true,
      ),
      
      // nav drawer
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


      body: ListView(
        children: [
          
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            onTap: () {
              Navigator.pushNamed(context, '/account');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Appearance'),
            onTap: () {
              // Navigate to appearance settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              // Navigate to about page
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/sign_in', (route) => false);
              
            },
          ),
        ],
      ),
    );
  }
}