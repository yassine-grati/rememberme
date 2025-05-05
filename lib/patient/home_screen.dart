import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cognitive_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _userName = '';
  Map<String, dynamic>? _lastTestResult;
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _userName = 'Utilisateur non connecté';
            _isLoading = false;
          });
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) {
          setState(() {
            _userName = 'Données non disponibles';
            _isLoading = false;
          });
        }
        return;
      }

      final userData = userDoc.data()!;
      final userType = userData['userType']?.toString().toLowerCase() ?? 'patient';
      if (userType != 'patient') {
        if (mounted) {
          setState(() {
            _userName = 'Cet écran est réservé aux patients';
            _isLoading = false;
          });
        }
        return;
      }

      final testResultsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cognitive_results')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _userName = userData['name']?.toString() ?? 'Utilisateur';
          _lastTestResult = testResultsSnapshot.docs.isNotEmpty
              ? testResultsSnapshot.docs.first.data()
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Erreur lors du chargement';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du chargement des données : $e',
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salut, $_userName !',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24.0),
                    if (_lastTestResult != null) ...[
                      Text(
                        'Votre dernier test (${_lastTestResult!['category'] ?? 'Inconnu'}) :',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Date : ${(_lastTestResult!['timestamp'] as Timestamp).toDate().toLocal()}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        'Statut : ${_lastTestResult!['completed'] == true ? 'Complété' : 'Incomplet'}',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ] else ...[
                      const Text(
                        'Aucun test effectué pour le moment.',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                    const SizedBox(height: 40.0),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Passer un test cognitif complet',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CognitiveTestScreen(
                                    isCompleteTest: true,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                            ),
                            child: const Text('Démarrer le Test Complet'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    const Text(
                      'Ou choisissez une catégorie :',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16.0),
                    _buildCategorySection('Enregistrement'),
                    _buildCategorySection('Attention & Calcul'),
                    _buildCategorySection('Rappel'),
                    _buildCategorySection('Langage'),
                    _buildCategorySection('Perception'),
                    _buildCategorySection('Localisation'),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: ListTile(
          title: Text(
            category,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CognitiveTestScreen(
                  category: category,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}