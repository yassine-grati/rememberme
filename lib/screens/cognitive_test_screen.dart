import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CognitiveTestScreen extends StatefulWidget {
  const CognitiveTestScreen({super.key});

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  String statusMessage = "Prêt à commencer";
  String? resultJson;
  Map<String, int>? scores;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  RPOrderedTask get cognitionTask => RPOrderedTask(
        identifier: "cognition_task",
        steps: [
          RPFlankerActivity(
            identifier: "flanker_test",
            lengthOfTest: 30,
            numberOfCards: 10,
          ),
          RPTappingActivity(
            identifier: "tapping_test",
            lengthOfTest: 10,
          ),
        ],
      );

  Future<Map<String, int>> saveResultsToFirestore(RPTaskResult result) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      print("=== RAW RESULTS STRUCTURE ===");
      result.results.forEach((key, value) => print("$key: ${value?.toString()}"));

      int flankerScore = 0;
      int tappingScore = 0;

      for (var entry in result.results.entries) {
        if (entry.value is RPStepResult) {
          final stepResult = entry.value as RPStepResult;

          print("\n=== STEP ${stepResult.identifier} RESULTS ===");
          stepResult.results.forEach((key, value) => print("$key: $value (${value.runtimeType})"));

          if (stepResult.identifier == "flanker_test") {
            final resultMap = stepResult.results['result'] as Map<dynamic, dynamic>?;
            if (resultMap != null) {
              print("Flanker result map: $resultMap");
              resultMap.forEach((key, value) => print("FLANKER KEY: $key, VALUE: $value (${value.runtimeType})"));
              var rightSwipes = resultMap['right swipes'];
              print("Raw right swipes value: $rightSwipes (${rightSwipes?.runtimeType})");
              flankerScore = rightSwipes != null
                  ? (rightSwipes is num
                      ? rightSwipes.toInt()
                      : rightSwipes is String
                          ? int.tryParse(rightSwipes) ?? 0
                          : 0)
                  : 0;
              print("Flanker score après assignation: $flankerScore");
            } else {
              print("No 'result' map found for Flanker test");
            }
          } else if (stepResult.identifier == "tapping_test") {
            final resultMap = stepResult.results['result'] as Map<dynamic, dynamic>?;
            if (resultMap != null) {
              print("Tapping result map: $resultMap");
              resultMap.forEach((key, value) => print("TAPPING KEY: $key, VALUE: $value (${value.runtimeType})"));
              var totalTaps = resultMap['Total taps'];
              print("Raw Total taps value: $totalTaps (${totalTaps?.runtimeType})");
              tappingScore = totalTaps != null
                  ? (totalTaps is num
                      ? totalTaps.toInt()
                      : totalTaps is String
                          ? int.tryParse(totalTaps) ?? 0
                          : 0)
                  : 0;
              print("Tapping score après assignation: $tappingScore");
            } else {
              print("No 'result' map found for Tapping test");
            }
          }
        }
      }

      print("\n=== FINAL SCORES ===");
      print("Flanker: $flankerScore");
      print("Tapping: $tappingScore");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cognitive_results')
          .add({
        'timestamp': Timestamp.now(),
        'flanker_score': flankerScore,
        'tapping_score': tappingScore,
      });

      print("Results successfully saved to Firestore");
      return {
        'flanker_score': flankerScore,
        'tapping_score': tappingScore,
      };
    } catch (e) {
      print('Erreur lors de la sauvegarde des résultats : $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building CognitiveTestScreen, status: $statusMessage');
    return Scaffold(
      body: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Test Cognitif',
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    statusMessage,
                    style: const TextStyle(fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () async {
                      try {
                        print('Starting cognitive test...');
                        setState(() {
                          statusMessage = "Test en cours...";
                          resultJson = null;
                          scores = null;
                        });

                        final result = await Navigator.of(context).push<RPTaskResult?>(
                          MaterialPageRoute(
                            builder: (context) {
                              print('Pushing RPUITask route');
                              return SafeArea(
                                child: RPUITask(
                                  task: cognitionTask,
                                  onSubmit: (result) {
                                    print('onSubmit called with result: ${result.toJson()}');
                                    Navigator.pop(context, result);
                                  },
                                  onCancel: (result) {
                                    print('onCancel called with result: $result');
                                    Navigator.pop(context, null);
                                  },
                                ),
                              );
                            },
                          ),
                        );

                        print('Result returned from Navigator.push: $result');

                        if (!mounted) {
                          print('State not mounted, skipping UI update');
                          return;
                        }

                        await Future.delayed(const Duration(milliseconds: 100)); // Let UI settle

                        if (result != null) {
                          try {
                            print('Processing results...');
                            final resultScores = await saveResultsToFirestore(result);
                            setState(() {
                              statusMessage = "Test terminé !";
                              resultJson = const JsonEncoder.withIndent('  ').convert(result.toJson());
                              scores = resultScores;
                            });
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Résultats enregistrés ! Flanker: ${resultScores['flanker_score']}, Tapping: ${resultScores['tapping_score']}',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } catch (e) {
                            print('Error during result processing: $e');
                            setState(() {
                              statusMessage = "Erreur lors de l'enregistrement";
                            });
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text('Erreur d\'enregistrement: ${e.toString()}'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } else {
                          print('Test cancelled');
                          setState(() {
                            statusMessage = "Test annulé";
                          });
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Test annulé'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Erreur lors de l\'exécution du test : $e');
                        if (mounted) {
                          setState(() {
                            statusMessage = "Erreur lors du test";
                          });
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors du test. Veuillez réessayer.'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Commencer le Test'),
                  ),
                  if (resultJson != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Résultat Brut:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        resultJson!,
                        style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                  if (scores != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Scores:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Flanker: ${scores!['flanker_score']}\nTapping: ${scores!['tapping_score']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String resultJson;
  final Map<String, int> scores;

  const ResultScreen({
    super.key,
    required this.resultJson,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    print('ResultScreen built with scores: $scores');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats du Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Résultat Brut:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  resultJson,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scores:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Flanker: ${scores['flanker_score']}\nTapping: ${scores['tapping_score']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      print('Retour button pressed');
                      Navigator.pop(context);
                    },
                    child: const Text('Retour'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('Réessayer button pressed');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CognitiveTestScreen(),
                        ),
                      );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}