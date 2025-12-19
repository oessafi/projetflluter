import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class Mymenu extends StatefulWidget {
  const Mymenu({super.key});

  @override
  State<Mymenu> createState() => _MymenuState();
}

class _MymenuState extends State<Mymenu> {
  // Récupération de l'utilisateur actuel
  User? user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  // Fonction pour choisir et uploader l'image
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    // 1. Choisir l'image depuis la galerie
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 2. Créer une référence dans Firebase Storage
      // Chemin : users_profiles/UID/profile.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users_profiles')
          .child('${user!.uid}.jpg');

      // 3. Uploader le fichier
      File file = File(image.path);
      await storageRef.putFile(file);

      // 4. Récupérer l'URL de téléchargement
      final String downloadUrl = await storageRef.getDownloadURL();

      // 5. Mettre à jour le profil Firebase Auth de l'utilisateur
      await user!.updatePhotoURL(downloadUrl);
      await user!.reload(); // Recharger les infos pour être sûr
      
      // Rafraîchir l'utilisateur localement
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (mounted) {
        setState(() {
          user = updatedUser; // Mettre à jour l'affichage avec la nouvelle URL
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour !')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

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
          // --- EN-TÊTE DU MENU (HEADER) AVEC COMPTE UTILISATEUR ---
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
            // Nom récupéré de Firebase (ou "Utilisateur" par défaut)
            accountName: Text(
              user?.displayName ?? 'Utilisateur',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            // Email récupéré de Firebase
            accountEmail: Text(user?.email ?? 'Pas d\'email'),
            // Photo de profil cliquable
            currentAccountPicture: GestureDetector(
              onTap: _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.white,
                    // Si user.photoURL existe, on l'utilise, sinon image par défaut
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : const AssetImage('assets/image/OIP.jpg') as ImageProvider,
                  ),
                  // Indicateur de chargement pendant l'upload
                  if (_isUploading)
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.deepPurple,
                    ),
                  // Petite icône caméra pour indiquer que c'est modifiable
                  if (!_isUploading)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.black54),
                      ),
                    ),
                ],
              ),
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
                onTap: null, // À relier si besoin
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