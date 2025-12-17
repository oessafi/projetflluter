Future<void> _signUp() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // Créer un utilisateur avec Firebase Authentication
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _pwdCtrl.text.trim(),
    );

    if (!mounted) return;

    // Afficher le message de succès avant la navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compte créé avec succès')),
    );

    // Naviguer vers la page principale
    Navigator.pushReplacementNamed(context, '/home');
  } on FirebaseAuthException catch (e) {
    String message = 'Une erreur est survenue';
    if (e.code == 'email-already-in-use') {
      message = 'Cet email est déjà utilisé';
    } else if (e.code == 'weak-password') {
      message = 'Le mot de passe est trop faible';
    } else if (e.code == 'invalid-email') {
      message = 'Email invalide';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur inattendue : $e')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}