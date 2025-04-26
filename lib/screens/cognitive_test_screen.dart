import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import 'package:cognition_package/model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../widgets/gradient_background.dart';
import 'results_screen.dart';

// Classe pour encapsuler le résultat du test et son état
class TestResult {
  final RPTaskResult? result;
  final bool isCompleted;

  TestResult({this.result, required this.isCompleted});
}

class CognitiveTestScreen extends StatefulWidget {
  const CognitiveTestScreen({super.key});

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isTestRunning = false;

  RPOrderedTask get cognitionTask => RPOrderedTask(
        identifier: "cognition_task",
        steps: [
          RPInstructionStep(
            identifier: 'intro',
            title: 'Évaluation cognitive',
            text: 'Vous allez passer une série de tests cognitifs pour évaluer différents domaines de votre cognition. '
                'Cela peut prendre environ 20 à 30 minutes. Vous pouvez quitter à tout moment, et vos résultats partiels seront enregistrés.',
          ),
          RPFlankerActivity(
            identifier: "flanker_test",
            lengthOfTest: 30,
            numberOfCards: 10,
          ),
          RPTappingActivity(
            identifier: "tapping_test",
            lengthOfTest: 10,
          ),
          RPTrailMakingActivity(
            identifier: "trail_making_test",
            trailType: TrailType.B,
          ),
          RPPictureSequenceMemoryActivity(
            identifier: "picture_sequence_test",
            numberOfTests: 3,
            numberOfPics: 3,
            lengthOfTest: 90,
          ),
          RPWordRecallActivity(
            identifier: "word_recall_test",
            numberOfTests: 5,
            lengthOfTest: 90, 
          ),
          RPLetterTappingActivity(
            identifier: "letter_tapping_test",
          ),
          RPPairedAssociatesLearningActivity(
            identifier: "paired_associates_test",
            maxTestDuration: 100,
          ),
          RPReactionTimeActivity(
            identifier: "reaction_time_test",
            lengthOfTest: 30,
            switchInterval: 4,
          ),
          RPStroopEffectActivity(
            identifier: "stroop_test",
            lengthOfTest: 30,
            displayTime: 1000,
            delayTime: 750,
          ),
          RPCorsiBlockTappingActivity(
            identifier: "corsi_block_test",
          ),
          RPRapidVisualInfoProcessingActivity(
            identifier: "rapid_visual_test",
            lengthOfTest: 60,
            interval: 9,
          ),
          RPVisualArrayChangeActivity(
            identifier: "visual_array_test",
            numberOfTests: 5,
            lengthOfTest: 1000,
          ),
          RPContinuousVisualTrackingActivity(
            identifier: "visual_tracking_test",
            lengthOfTest: 60,
            amountOfTargets: 3, 
          ),
          RPDelayedRecallActivity(
            identifier: "delayed_recall_test",
            numberOfTests: 5,
            lengthOfTest: 300,
          ),
        ],
      );

  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> saveResultsToFirestore(RPTaskResult result, {bool completed = true}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      const Map<String, String> scoreKeys = {
        'flanker_test': 'score',
        'tapping_test': 'Total taps',
        'trail_making_test': 'score',
        'picture_sequence_test': 'score',
        'word_recall_test': 'score',
        'letter_tapping_test': 'score',
        'paired_associates_test': 'score',
        'reaction_time_test': 'reactionTime',
        'stroop_test': 'score',
        'corsi_block_test': 'score',
        'rapid_visual_test': 'score',
        'visual_array_test': 'score',
        'visual_tracking_test': 'score',
        'delayed_recall_test': 'score',
      };

      Map<String, dynamic> scores = {};

      for (final entry in result.results.entries) {
        if (entry.value is RPActivityResult) {
          final stepResult = entry.value as RPActivityResult;
          final identifier = stepResult.identifier;

          if (identifier == 'intro') continue;

          print('Résultats pour $identifier : ${stepResult.results}');
          final resultData = stepResult.results['result'];
          if (resultData != null) {
            if (resultData is Map<String, dynamic>) {
              String scoreKey = scoreKeys[identifier] ?? 'score';
              dynamic scoreValue = resultData[scoreKey] ?? resultData['score'] ?? 0;
              scores[identifier] = _parseToInt(scoreValue);
            } else if (resultData is int) {
              scores[identifier] = resultData;
            } else {
              print('Format inattendu pour $identifier : $resultData');
              scores[identifier] = 0;
            }
          } else {
            print('Aucun résultat trouvé pour $identifier');
          }
        }
      }

      if (scores.isNotEmpty) {
        print('Sauvegarde des scores dans Firestore : $scores');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cognitive_results')
            .add({
          'timestamp': Timestamp.now(),
          'scores': scores,
          'completed': completed,
        });
      } else {
        print('Aucun score à sauvegarder');
        throw Exception('Aucun score généré pour sauvegarde');
      }
    } catch (e, stackTrace) {
      print('Erreur lors de la sauvegarde dans Firestore : $e');
      print('Stack trace : $stackTrace');
      rethrow;
    }
  }

  Future<TestResult> runCognitiveTest(BuildContext context) async {
    final completer = Completer<TestResult>();

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WillPopScope(
            onWillPop: () async {
              if (!_isTestRunning) return true;
              completer.complete(TestResult(result: null, isCompleted: false));
              return true;
            },
            child: Theme(
              data: Theme.of(context).copyWith(
                scaffoldBackgroundColor: Colors.transparent,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                  iconTheme: IconThemeData(color: Colors.white),
                ),
                textTheme: const TextTheme(
                  bodyLarge: TextStyle(color: Colors.white),
                  bodyMedium: TextStyle(color: Colors.white),
                  labelLarge: TextStyle(color: Colors.white),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF6F35A5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    elevation: 5,
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              child: GradientBackground(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    title: const Text('Test en cours'),
                    leading: BackButton(
                      onPressed: () {
                        if (_isTestRunning) {
                          completer.complete(TestResult(result: null, isCompleted: false));
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  body: SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: RPUITask(
                        task: cognitionTask,
                        onSubmit: (res) {
                          print('Test soumis avec succès : $res');
                          completer.complete(TestResult(result: res, isCompleted: true));
                        },
                        onCancel: (res) {
                          print('Test annulé : $res');
                          completer.complete(TestResult(result: res, isCompleted: false));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('Erreur lors de l\'exécution de runCognitiveTest : $e');
      print('Stack trace : $stackTrace');
      completer.complete(TestResult(result: null, isCompleted: false));
    }

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('WillPopScope triggered, preventing pop while test is running: $_isTestRunning');
        return !_isTestRunning;
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Cognitive Test'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Take a Cognitive Test',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        setState(() {
                          _isTestRunning = true;
                        });

                        final testResult = await runCognitiveTest(context);
                        print('Résultat du test : isCompleted=${testResult.isCompleted}, result=${testResult.result}');

                        if (testResult.isCompleted && testResult.result != null) {
                          // Extraire les scores pour les passer à ResultsScreen
                          final scores = <String, dynamic>{};
                          try {
                            for (final entry in testResult.result!.results.entries) {
                              if (entry.value is RPActivityResult) {
                                final stepResult = entry.value as RPActivityResult;
                                final identifier = stepResult.identifier;
                                if (identifier == 'intro') continue;
                                final resultData = stepResult.results['result'];
                                if (resultData != null) {
                                  if (resultData is Map<String, dynamic>) {
                                    final score = resultData['score'] ?? resultData['Total taps'] ?? resultData['reactionTime'] ?? 0;
                                    scores[identifier] = _parseToInt(score);
                                  } else if (resultData is int) {
                                    scores[identifier] = resultData;
                                  } else {
                                    print('Format inattendu pour $identifier : $resultData');
                                    scores[identifier] = 0;
                                  }
                                } else {
                                  print('Aucun resultData pour $identifier');
                                }
                              }
                            }
                            print('Scores extraits : $scores');
                          } catch (e) {
                            print('Erreur lors de l\'extraction des scores : $e');
                            throw Exception('Erreur lors de l\'extraction des scores : $e');
                          }

                          // Naviguer vers ResultsScreen
                          try {
                            if (mounted) {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ResultsScreen(scores: scores),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Erreur lors de la navigation vers ResultsScreen : $e');
                            throw Exception('Erreur lors de la navigation : $e');
                          }

                          // Sauvegarder les résultats dans Firestore
                          try {
                            await saveResultsToFirestore(testResult.result!, completed: true);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Résultats enregistrés !',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.black,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Erreur lors de la sauvegarde des résultats : $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erreur lors de la sauvegarde : $e',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.black,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Test annulé.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.black,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Erreur générale dans le bloc principal : $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erreur lors du test : $e. Veuillez réessayer.',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.black,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } finally {
                        setState(() {
                          _isTestRunning = false;
                        });
                      }
                    },
                    child: const Text('Start Test'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}