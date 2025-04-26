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

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleTab(bool isLogin) {
    setState(() {
      _isLogin = isLogin;
    });
  }

  Future<void> _login() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          String userType = userDoc['userType'];

          if (userType == 'patient') {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (userType == 'doctor') {
            Navigator.pushReplacementNamed(context, '/doctor-main');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Type d’utilisateur inconnu')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'Aucun utilisateur trouvé avec cet email.';
        } else if (e.code == 'wrong-password') {
          message = 'Mot de passe incorrect.';
        } else {
          message = 'Erreur de connexion : ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Center(
                    child: Text(
                      'REMEMBER Me',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _toggleTab(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isLogin
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        foregroundColor:
                            !_isLogin ? Colors.white : Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8.0),
                            bottomLeft: Radius.circular(8.0),
                          ),
                        ),
                      ),
                      child: const Text('Sign up'),
                    ),
                    ElevatedButton(
                      onPressed: () => _toggleTab(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLogin
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        foregroundColor:
                            _isLogin ? Colors.white : Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0),
                          ),
                        ),
                      ),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                _isLogin ? _buildLoginForm() : _buildUserTypeSelection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          CustomTextField(
            label: 'Password',
            controller: _passwordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          CustomButton(
            text: 'SE connecter',
            onPressed: _login,
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Column(
      children: [
        CustomButton(
          text: 'Doctor',
          onPressed: () {
            Navigator.pushNamed(context, '/doctor-register');
          },
        ),
        const SizedBox(height: 16.0),
        CustomButton(
          text: 'Patient',
          onPressed: () {
            Navigator.pushNamed(context, '/patient-register');
          },
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}