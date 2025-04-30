import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_background.dart';

class PatientHistoryScreen extends StatelessWidget {
  final String patientUid;
  final String patientName;

  const PatientHistoryScreen({
    super.key,
    required this.patientUid,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Historique de $patientName'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(patientUid)
              .collection('cognitive_results')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Erreur lors du chargement de l\'historique',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun test effectué par ce patient',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp).toDate();
                final scores = data['scores'] as Map<String, dynamic>? ?? {};
                final completed = data['completed'] as bool? ?? true;
                final testType = data['testType']?.toString() ?? 'Inconnu';
                final testName = data['testName']?.toString() ?? '';
                final category = data['category']?.toString() ?? 'Inconnu';

                // Déterminer le titre en fonction du type de test
                String displayTitle;
                if (testType == 'Complet') {
                  displayTitle = 'Test Complet';
                } else if (testType == 'Catégorie') {
                  displayTitle = 'Test de $category';
                } else {
                  displayTitle = testName.isNotEmpty ? testName : 'Test Individuel';
                }

                return Card(
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Text(
                      displayTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${timestamp.toLocal()} | ${completed ? 'Complété' : 'Incomplet'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1976D2).withOpacity(0.9),
                          title: Text(
                            'Détails du test - $displayTitle',
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date : ${timestamp.toLocal()}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (testType != 'Individuel')
                                  Text(
                                    'Catégorie : $category',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                Text(
                                  'Statut : ${completed ? 'Complété' : 'Incomplet'}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Scores :',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...scores.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          entry.value.toString(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Fermer',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}