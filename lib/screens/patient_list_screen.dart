import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_history_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Médecin non connecté'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liste des patients',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Erreur lors du chargement du document du médecin : ${snapshot.error}');
                  return const Center(child: Text('Erreur lors du chargement des patients'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  print('Document du médecin introuvable pour UID : ${user.uid}');
                  return const Center(child: Text('Document du médecin introuvable'));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                List<dynamic> patientUidsDynamic = userData['patients'] ?? [];
                List<String> patientUids = patientUidsDynamic.map((uid) => uid.toString()).toList();

                print('Patient UIDs trouvés : $patientUids');

                if (patientUids.isEmpty) {
                  return const Center(child: Text('Aucun patient assigné'));
                }

                return ListView.builder(
                  itemCount: patientUids.length,
                  itemBuilder: (context, index) {
                    String patientUid = patientUids[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(patientUid)
                          .get(),
                      builder: (context, patientSnapshot) {
                        if (patientSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Chargement...'),
                          );
                        }
                        if (patientSnapshot.hasError) {
                          print('Erreur lors du chargement du patient $patientUid : ${patientSnapshot.error}');
                          return ListTile(
                            title: Text('Erreur pour le patient $patientUid'),
                          );
                        }
                        if (!patientSnapshot.hasData || !patientSnapshot.data!.exists) {
                          print('Patient introuvable pour UID : $patientUid');
                          return ListTile(
                            title: Text('Patient introuvable : $patientUid'),
                          );
                        }

                        var patientData = patientSnapshot.data!.data() as Map<String, dynamic>;
                        String patientName = patientData['name'] ?? 'Patient inconnu';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            title: Text(patientName),
                            subtitle: Text('UID: $patientUid'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientHistoryScreen(
                                    patientUid: patientUid,
                                    patientName: patientName,
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