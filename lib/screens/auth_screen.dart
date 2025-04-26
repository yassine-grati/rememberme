import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        User? user = userCredential.user;
        if (user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            String userType = userDoc['userType'];
            if (userType == 'doctor') {
              Navigator.pushReplacementNamed(context, '/doctor-main');
            } else {
              Navigator.pushReplacementNamed(context, '/main');
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Aucun utilisateur trouvé avec cet email.';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect. Veuillez réessayer.';
            break;
          case 'invalid-email':
            errorMessage = 'L\'adresse email est invalide.';
            break;
          default:
            errorMessage = 'Une erreur est survenue lors de la connexion. Veuillez réessayer.';
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
              'Une erreur inattendue est survenue lors de la connexion. Veuillez réessayer.',
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
        height: MediaQuery.of(context).size.height,
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
              child: FadeTransition(
                opacity: _fadeAnimation,
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
                            label: 'Mot de passe',
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24.0),
                          _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : CustomButton(
                                  text: 'SE connecter',
                                  onPressed: _signIn,
                                ),
                          const SizedBox(height: 24.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6F35A5),
                                        Color(0xFF1976D2),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10.0,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/doctor-register');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'S’inscrire en tant que médecin',
                                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6F35A5),
                                        Color(0xFF1976D2),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10.0,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/patient-register');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'S’inscrire en tant que patient',
                                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}