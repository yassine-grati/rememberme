import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Délai pour afficher l'écran de démarrage

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String userType = userData['userType'] ?? 'patient'; // Par défaut, considérer comme patient
          if (mounted) {
            if (userType == 'doctor') {
              Navigator.pushReplacementNamed(context, '/doctor-main');
            } else {
              Navigator.pushReplacementNamed(context, '/main');
            }
          }
        } else {
          // Si aucune donnée utilisateur n'est trouvée, rediriger vers l'écran de connexion
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/welcome');
          }
        }
      } else {
        // Aucun utilisateur connecté, rediriger vers l'écran de bienvenue
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } catch (e) {
      // Gestion des erreurs (par exemple, Firestore inaccessible)
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Text(
            'REMEMBER Me',
            style: TextStyle(
              fontSize: 36.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}