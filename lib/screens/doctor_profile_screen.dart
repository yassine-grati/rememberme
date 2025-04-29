import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_button.dart';
import '../widgets/gradient_background.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  String _username = 'Médecin';
  String _location = 'N/A';
  String _matriculeMedical = 'N/A';
  String _email = 'N/A';
  String _userType = 'doctor';
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _username = 'Médecin non connecté';
            _isLoading = false;
          });
        }
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Délai d\'attente dépassé pour la récupération des données');
      });

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) {
          setState(() {
            _username = 'Données non disponibles';
            _email = user.email ?? 'N/A';
            _isLoading = false;
          });
        }
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _userType = userData['userType']?.toString().toLowerCase() ?? 'doctor';
          if (_userType != 'doctor') {
            _username = 'Cet écran est réservé aux médecins';
            _isLoading = false;
            return;
          }
          _username = userData['name']?.toString() ?? 'Médecin';
          _location = userData['location']?.toString() ?? 'N/A';
          _matriculeMedical = userData['matricule']?.toString() ?? 'N/A';
          _email = userData['email']?.toString() ?? user.email ?? 'N/A';
          _usernameController.text = _username;
          _locationController.text = _location;
          _matriculeController.text = _matriculeMedical;
          _emailController.text = _email;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _username = 'Erreur lors du chargement';
          _email = 'N/A';
        });
        String errorMessage = 'Échec du chargement des données de profil. Veuillez réessayer.';
        if (e.toString().contains('network')) {
          errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Vous n\'avez pas la permission d\'accéder à ces données.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateDoctorDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Médecin non connecté');
        }

        if (_emailController.text.trim() != user.email) {
          await user.updateEmail(_emailController.text.trim());
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _usernameController.text.trim(),
          'location': _locationController.text.trim(),
          'matricule': _matriculeController.text.trim(),
          'email': _emailController.text.trim(),
        });

        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (mounted) {
          setState(() {
            _username = _usernameController.text.trim();
            _location = _locationController.text.trim();
            _matriculeMedical = _matriculeController.text.trim();
            _email = user?.email ?? _emailController.text.trim();
            _isEditing = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profil mis à jour avec succès !',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Cet email est déjà utilisé par un autre compte.';
            break;
          case 'requires-recent-login':
            errorMessage = 'Veuillez vous reconnecter pour mettre à jour votre email.';
            break;
          default:
            errorMessage = 'Échec de la mise à jour du profil. Veuillez réessayer.';
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          String errorMessage = 'Échec de la mise à jour du profil. Veuillez réessayer.';
          if (e.toString().contains('network')) {
            errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
          } else if (e.toString().contains('permission-denied')) {
            errorMessage = 'Vous n\'avez pas la permission de mettre à jour ces données.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMessage = 'Échec de la déconnexion. Veuillez réessayer.';
        if (e.toString().contains('network')) {
          errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _locationController.dispose();
    _matriculeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil du médecin',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ) ?? const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24.0),
                    if (_userType == 'doctor') ...[
                      if (_isEditing) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Nom d\'utilisateur',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom d\'utilisateur';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                controller: _locationController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Localisation',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre localisation';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                controller: _matriculeController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Matricule médical',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre matricule médical';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.redAccent),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
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
                              const SizedBox(height: 24.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: _updateDoctorDetails,
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                    ),
                                    child: const Text('Enregistrer'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = false;
                                        _usernameController.text = _username;
                                        _locationController.text = _location;
                                        _matriculeController.text = _matriculeMedical;
                                        _emailController.text = _email;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Annuler'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Nom d\'utilisateur: $_username',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Localisation: $_location',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Matricule médical: $_matriculeMedical',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Email: $_email',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                              ),
                              child: const Text('Modifier'),
                            ),
                            ElevatedButton(
                              onPressed: _signOut,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                              ),
                              child: const Text('Se déconnecter'),
                            ),
                          ],
                        ),
                      ],
                    ] else
                      Text(
                        _username,
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}