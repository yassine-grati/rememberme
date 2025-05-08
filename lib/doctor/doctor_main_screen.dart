import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_profile_screen.dart';
import 'patient_history_screen.dart';
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

  Future<void> _addPatientByEmail(BuildContext context, String doctorUid) async {
    final TextEditingController emailController = TextEditingController();
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1976D2).withOpacity(0.9),
              title: const Text(
                'Ajouter un patient',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail du patient',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      setState(() {
                        errorMessage = 'Veuillez entrer une adresse e-mail.';
                      });
                      return;
                    }

                    try {
                      final querySnapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: email)
                          .where('userType', isEqualTo: 'patient')
                          .get();

                      if (querySnapshot.docs.isEmpty) {
                        setState(() {
                          errorMessage = 'Aucun patient trouvé avec cet e-mail.';
                        });
                        return;
                      }

                      final patientDoc = querySnapshot.docs.first;
                      final patientUid = patientDoc.id;

                      final doctorDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(doctorUid)
                          .get();
                      final List<dynamic> patients = doctorDoc.data()?['patients'] ?? [];
                      if (patients.contains(patientUid)) {
                        setState(() {
                          errorMessage = 'Ce patient est déjà dans votre liste.';
                        });
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(doctorUid)
                          .update({
                        'patients': FieldValue.arrayUnion([patientUid]),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Patient ajouté avec succès à votre liste !',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.black,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      String errorText = 'Erreur inconnue';
                      if (e.toString().contains('permission-denied')) {
                        errorText = 'Vous n\'avez pas la permission d\'effectuer cette action.';
                      } else if (e.toString().contains('network')) {
                        errorText = 'Problème de connexion réseau. Veuillez réessayer.';
                      } else {
                        errorText = 'Une erreur est survenue lors de l\'ajout du patient.';
                      }
                      setState(() {
                        errorMessage = errorText;
                      });
                    }
                  },
                  child: const Text(
                    'Ajouter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Médecin non connecté',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord du médecin',
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
          const SizedBox(height: 20),
          Text(
            'Bienvenue, Dr. $doctorName',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Liste des patients',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ) ?? const TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      "Erreur ou document médecin introuvable.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> patientsRaw = data['patients'] ?? [];
                final List<String> patientUids = patientsRaw.map((e) => e.toString()).toList();

                if (patientUids.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun patient assigné',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    patientUids.map((uid) async {
                      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                      if (doc.exists && doc.data() != null) {
                        final patientData = doc.data() as Map<String, dynamic>;
                        return {
                          'uid': uid,
                          'name': patientData['name'] ?? 'Patient inconnu',
                          'email': patientData['email'] ?? 'Email non disponible',
                        };
                      }
                      return {
                        'uid': uid,
                        'name': 'Patient introuvable',
                        'email': 'N/A',
                      };
                    }),
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snap.hasError) {
                      return const Center(
                        child: Text(
                          'Erreur lors du chargement des patients.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final patients = snap.data ?? [];

                    return ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            title: Text(
                              patient['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Email: ${patient['email']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientHistoryScreen(
                                    patientUid: patient['uid'],
                                    patientName: patient['name'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}