import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        User? user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'location': _locationController.text.trim(),
            'matricule': _matriculeController.text.trim(),
            'userType': 'doctor',
            'patients': [],
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Inscription réussie ! Vous êtes maintenant connecté en tant que médecin.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushReplacementNamed(context, '/doctor-main');
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Cet email est déjà utilisé par un autre compte.';
            break;
          case 'invalid-email':
            errorMessage = 'L\'adresse email est invalide.';
            break;
          case 'weak-password':
            errorMessage = 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
            break;
          default:
            errorMessage = 'Une erreur est survenue lors de l\'inscription. Veuillez réessayer.';
        }
        if (mounted) {
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
          String errorMessage = 'Une erreur inattendue est survenue lors de l\'inscription. Veuillez réessayer.';
          if (e.toString().contains('network')) {
            errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
          } else if (e.toString().contains('permission-denied')) {
            errorMessage = 'Vous n\'avez pas la permission d\'effectuer cette action.';
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: MediaQuery.of(context).size.height, // S’assure que le conteneur prend toute la hauteur
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/illustration.png',
                    height: 200,
                  ),
                  const SizedBox(height: 40.0),
                  Text(
                    'REMEMBER ME',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 40.0),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Nom d’utilisateur',
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        CustomTextField(
                          label: 'Email',
                          controller: _emailController,
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
                        CustomTextField(
                          label: 'Location',
                          controller: _locationController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre localisation';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        CustomTextField(
                          label: 'Matricule médical',
                          controller: _matriculeController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre matricule médical';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        CustomTextField(
                          label: 'Mot de passe',
                          controller: _passwordController,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),
                        _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : CustomButton(
                                text: 'ENREGISTRER',
                                onPressed: _registerDoctor,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}