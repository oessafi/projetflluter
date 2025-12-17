import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Mymenu extends StatefulWidget {
  const Mymenu({super.key});

  @override
  State<Mymenu> createState() => _MymenuState();
}

class _MymenuState extends State<Mymenu> {
  // Fonction de déconnexion
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // Retour à la page de connexion et suppression de l'historique
    Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- EN-TÊTE DU MENU (HEADER) ---
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35.0,
                  // Assure-toi que cette image existe ou utilise une icône
                  backgroundImage: AssetImage('assets/image/OIP.jpg'),
                  // child: Icon(Icons.person, size: 40), // Alternative si pas d'image
                ),
                SizedBox(width: 15),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chouchou',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Utilisateur',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- SECTION MODÈLES IA ---
          const ExpansionTile(
            leading: Icon(Icons.psychology),
            title: Text("Modèles IA"),
            childrenPadding: EdgeInsets.only(left: 20),
            children: [
              ListTile(
                leading: Icon(Icons.grid_view, size: 20),
                title: Text("Classification d'image"),
                onTap: null, 
              ),
            ],
          ),

          const Divider(),

          // --- NAVIGATION ---
          
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('Bourse (Stock)'),
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
            leading: const Icon(Icons.image_search),
            title: const Text("Classification d'image"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/image');
            },
          ),

          const Divider(),

          // --- DÉCONNEXION ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              _signOut();
            },
          ),
        ],
      ),
    );
  }
}