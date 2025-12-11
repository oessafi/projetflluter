// lib/im.dart
import 'package:flutter/material.dart';

class Mymenu extends StatefulWidget {
  const Mymenu({super.key});

  @override
  State<Mymenu> createState() => _MymenuState();
}

class _MymenuState extends State<Mymenu> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- HEADER ---
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35.0,
                  backgroundImage: AssetImage(
                    'assets/image/OIP.jpg',
                  ),
                ),
                SizedBox(width: 15),
                Flexible(
                  child: Text(
                    'chouchou',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // --- MENU DÉROULANT (MODELS) ---
          const ExpansionTile(
            childrenPadding: EdgeInsets.only(left: 25.0),
            leading: Icon(Icons.image),
            title: Text("Image Classification Models"),
            subtitle: Text("Choose a model"),
            children: [
              ListTile(
                title: Text("ANN model"),
              ),
              ListTile(
                title: Text("CNN model"),
              ),
            ],
          ),

          const Divider(color: Colors.grey, height: 1),

          // --- AUTRES FONCTIONNALITÉS ---
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Stock price prediction'),
            onTap: () {
              // TODO: Logique ou navigation si tu veux
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('vocal assistant'),
            onTap: () {
              // TODO
            },
          ),

          const Divider(color: Colors.grey, height: 1),

          // --- NAVIGATION SIGN UP & AUTRES PAGES ---
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('S\'inscrire (Sign Up)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/signup');
            },
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Stock'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/stock');
            },
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Assistant Vocal'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/vocal');
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text("Classification d'image"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/image');
            },
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil utilisateur'),
      ),
      drawer: const Mymenu(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenue sur votre profil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/signin');
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
