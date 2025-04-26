import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  String _username = 'Médecin';
  String _location = 'N/A';
  String _matriculeMedical = 'N/A';
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final _matriculeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Médecin non connecté');
      }

      print('Fetching doctor details for UID: ${user.uid}');
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
      print('Doctor data: $userData');

      if (mounted) {
        setState(() {
          _username = userData['username'] ?? 'Médecin';
          _location = userData['location'] ?? 'N/A';
          _matriculeMedical = userData['matriculeMedical'] ?? 'N/A';
          _usernameController.text = _username;
          _locationController.text = _location;
          _matriculeController.text = _matriculeMedical;
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

  Future<void> _updateDoctorDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Médecin non connecté');
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _usernameController.text.trim(),
          'location': _locationController.text.trim(),
          'matriculeMedical': _matriculeController.text.trim(),
        });

        if (mounted) {
          setState(() {
            _username = _usernameController.text.trim();
            _location = _locationController.text.trim();
            _matriculeMedical = _matriculeController.text.trim();
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
    _locationController.dispose();
    _matriculeController.dispose();
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
            'Profil du médecin',
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
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Localisation'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre localisation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _matriculeController,
                      decoration: const InputDecoration(labelText: 'Matricule médical'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre matricule médical';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _updateDoctorDetails,
                          child: const Text('Enregistrer'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _usernameController.text = _username;
                              _locationController.text = _location;
                              _matriculeController.text = _matriculeMedical;
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
              Text('Localisation: $_location'),
              const SizedBox(height: 8.0),
              Text('Matricule médical: $_matriculeMedical'),
              const SizedBox(height: 8.0),
              Text('Email: ${user.email ?? 'N/A'}'),
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
            const Text('Médecin non connecté'),
        ],
      ),
    );
  }
}