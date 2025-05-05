import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/widgets/custom_text_field.dart';
import '../shared/widgets/custom_button.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _educationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _physicalActivityController = TextEditingController();
  final _sleepQualityController = TextEditingController();
  String _gender = 'Homme'; // Valeur par défaut
  bool _familyHistoryAlzheimers = false;
  bool _diabetes = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _educationController.dispose();
    _passwordController.dispose();
    _physicalActivityController.dispose();
    _sleepQualityController.dispose();
    super.dispose();
  }

  Future<void> _registerPatient() async {
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
          // Map family history to integer: false (Non) -> 0, true (Oui) -> 1
          int familyHistoryCode = _familyHistoryAlzheimers ? 1 : 0;
          // Map diabetes to integer: false (Non) -> 0, true (Oui) -> 1
          int diabetesCode = _diabetes ? 1 : 0;

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'education_years': int.tryParse(_educationController.text.trim()) ?? 0,
            'gender': _gender, // Store gender as string
            'physical_activity_hours_per_week': double.tryParse(_physicalActivityController.text.trim()) ?? 0.0,
            'sleep_quality_hours_per_night': double.tryParse(_sleepQualityController.text.trim()) ?? 0.0,
            'family_history_alzheimers_code': familyHistoryCode,
            'diabetes_code': diabetesCode,
            'userType': 'patient',
          });
          Navigator.pushReplacementNamed(context, '/main');
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Une erreur inattendue est survenue lors de l\'inscription. Veuillez réessayer.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
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
                          label: 'Âge',
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre âge';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Veuillez entrer un âge valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: InputDecoration(
                            labelText: 'Genre',
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
                          ),
                          dropdownColor: Colors.black87,
                          style: const TextStyle(color: Colors.white),
                          items: ['Homme', 'Femme', 'Autre']
                              .map((gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _gender = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner votre genre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        CustomTextField(
                          label: 'Années d\'études',
                          controller: _educationController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nombre d\'années d\'études';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        CustomTextField(
                          label: 'Activité physique (heures/semaine)',
                          controller: _physicalActivityController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer vos heures d\'activité physique';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        CustomTextField(
                          label: 'Qualité du sommeil (heures/nuit)',
                          controller: _sleepQualityController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer vos heures de sommeil par nuit';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        SwitchListTile(
                          title: const Text(
                            'Antécédents familiaux d\'Alzheimer',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: _familyHistoryAlzheimers,
                          onChanged: (value) {
                            setState(() {
                              _familyHistoryAlzheimers = value;
                            });
                          },
                          activeColor: Colors.white,
                          inactiveTrackColor: Colors.white54,
                        ),
                        const SizedBox(height: 16.0),
                        SwitchListTile(
                          title: const Text(
                            'Diabète',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: _diabetes,
                          onChanged: (value) {
                            setState(() {
                              _diabetes = value;
                            });
                          },
                          activeColor: Colors.white,
                          inactiveTrackColor: Colors.white54,
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
                                onPressed: _registerPatient,
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