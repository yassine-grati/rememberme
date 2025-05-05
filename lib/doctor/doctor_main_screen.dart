import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_profile_screen.dart';
import 'patient_list_screen.dart';
import '../shared/widgets/gradient_background.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;
  String _doctorName = 'Médecin';
  bool _isLoading = true;

  final List<Widget> _screens = [
    const PatientListScreen(),
    const DoctorProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctorName();
  }

  Future<void> _fetchDoctorName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Médecin non connecté');
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Délai d\'attente dépassé pour la récupération des données');
      });

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('Données non disponibles');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userType = userData['userType']?.toString().toLowerCase() ?? 'doctor';
      if (userType != 'doctor') {
        throw Exception('Cet écran est réservé aux médecins');
      }

      if (mounted) {
        setState(() {
          _doctorName = userData['name']?.toString() ?? 'Médecin';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _doctorName = 'Erreur lors du chargement';
          _isLoading = false;
        });
        String errorMessage = 'Échec du chargement des données du médecin. Veuillez réessayer.';
        if (e.toString().contains('network')) {
          errorMessage = 'Problème de connexion réseau. Veuillez vérifier votre connexion.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Vous n\'avez pas la permission d\'accéder à ces données.';
        } else if (e.toString().contains('Médecin non connecté')) {
          errorMessage = 'Vous devez être connecté en tant que médecin pour accéder à cet écran.';
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
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : IndexedStack(
                index: _currentIndex,
                children: [
                  DoctorHomeScreen(doctorName: _doctorName),
                  ..._screens,
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF6F35A5).withOpacity(0.9),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorHomeScreen extends StatelessWidget {
  final String doctorName;

  const DoctorHomeScreen({super.key, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tableau de bord du médecin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bienvenue, Dr. $doctorName',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sélectionnez "Patients" pour suivre leurs progrès.',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}