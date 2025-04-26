import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Utilisateur';
  String _age = 'N/A';
  String _educationLevel = 'N/A';
  String _email = 'N/A';
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _educationController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      print('Fetching user details for UID: ${user.uid}');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        print('Document does not exist for UID: ${user.uid}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      print('User data: $userData');

      if (mounted) {
        setState(() {
          _username = userData['username'] ?? 'Utilisateur';
          _age = userData['age'] ?? 'N/A';
          _educationLevel = userData['educationLevel'] ?? 'N/A';
          _email = userData['email'] ?? user.email ?? 'N/A';
          _usernameController.text = _username;
          _ageController.text = _age;
          _educationController.text = _educationLevel;
          _emailController.text = _email;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des détails : $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }

        // Update email in Firebase Authentication if it has changed
        if (_emailController.text.trim() != user.email) {
          await user.updateEmail(_emailController.text.trim());
          print('Email updated in Firebase Authentication');
        }

        // Update user details in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _usernameController.text.trim(),
          'age': _ageController.text.trim(),
          'educationLevel': _educationController.text.trim(),
          'email': _emailController.text.trim(),
        });

        // Refresh the user to ensure the email update is reflected
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (mounted) {
          setState(() {
            _username = _usernameController.text.trim();
            _age = _ageController.text.trim();
            _educationLevel = _educationController.text.trim();
            _email = user?.email ?? _emailController.text.trim();
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informations mises à jour avec succès')),
          );
        }
      } catch (e) {
        print('Erreur lors de la mise à jour des informations : $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _educationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          if (user != null) ...[
            if (_isEditing) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom d\'utilisateur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Âge'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre âge';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(labelText: 'Niveau d\'éducation'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre niveau d\'éducation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _updateUserDetails,
                          child: const Text('Enregistrer'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _usernameController.text = _username;
                              _ageController.text = _age;
                              _educationController.text = _educationLevel;
                              _emailController.text = _email;
                            });
                          },
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text('Nom d\'utilisateur: $_username'),
              const SizedBox(height: 8.0),
              Text('Âge: $_age'),
              const SizedBox(height: 8.0),
              Text('Niveau d\'éducation: $_educationLevel'),
              const SizedBox(height: 8.0),
              Text('Email: $_email'),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    child: const Text('Modifier'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                      }
                    },
                    child: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ],
          ] else
            const Text('Utilisateur non connecté'),
        ],
      ),
    );
  }
}