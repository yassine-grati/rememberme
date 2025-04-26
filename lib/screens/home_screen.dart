import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cognitive_test_screen.dart';
import '../widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _userName = 'Utilisateur';
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic>? _latestTestResult;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    _fetchUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user name
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userName = userData['name'] ?? 'Utilisateur';
            });
          }
        }

        // Fetch latest test result
        QuerySnapshot resultSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cognitive_results')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (resultSnapshot.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              _latestTestResult = resultSnapshot.docs.first.data() as Map<String, dynamic>;
            });
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données : $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GradientBackground(
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Accueil'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salut, $_userName',
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
                        const SizedBox(height: 8.0),
                        const Text(
                          'Explorez votre cerveau',
                          style: TextStyle(fontSize: 18.0, color: Colors.white70),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CognitiveTestScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Passer un test',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        height: 150,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10.0,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: _latestTestResult != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dernier test :',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Date : ${(_latestTestResult!['timestamp'] as Timestamp?)?.toDate().toLocal().toString() ?? 'N/A'}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Complété : ${_latestTestResult!['completed'] == true ? 'Oui' : 'Non'}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 16.0),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Text(
                                  'Aucun test récent. Essayez un test maintenant !',
                                  style: TextStyle(color: Colors.white70, fontSize: 16.0),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10.0,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CognitiveTestScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF6F35A5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              elevation: 5,
                            ),
                            child: const Text('Passer un test cognitif'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}