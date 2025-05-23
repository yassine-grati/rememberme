import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../shared/widgets/gradient_background.dart';
import 'results_screen.dart';
import '../tests/logic/cognitive_tests.dart';
import 'package:rememberme/tests/logic/quiz_activity.dart';
import '../shared/tools/snackbar_tools.dart'; // Importation du fichier de snackbar

// Classe pour encapsuler le résultat du test et son état
class TestResult {
  final RPTaskResult? result;
  final bool isCompleted;

  TestResult({this.result, required this.isCompleted});
}

class CognitiveTestScreen extends StatefulWidget {
  final String category;
  final bool isCompleteTest;

  const CognitiveTestScreen({
    super.key,
    this.category = '',
    this.isCompleteTest = false,
  });

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  bool _isTestRunning = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  RPOrderedTask _buildTask(
    String identifier,
    String title,
    String introText,
    List<RPStep> steps,
  ) {
    print(
      "Building task $identifier with steps: ${steps.map((s) => s.identifier).toList()}",
    );
    return RPOrderedTask(
      identifier: identifier,
      steps: [
        RPInstructionStep(
          identifier: 'intro_$identifier',
          title: title,
          text: introText,
        ),
        ...steps,
        RPCompletionStep(
          identifier: 'completion_$identifier',
          title: 'Test Terminé',
          text:
              'Merci d\'avoir complété le test ! Vos résultats ont été enregistrés.',
        ),
      ],
    );
  }

  RPOrderedTask _buildCompleteCognitionTask() {
    final List<String> orderedCategories = [
      'Enregistrement',
      'Attention et Calcul',
      'Rappel',
      'Langage',
    ];

    final List<RPStep> orderedTests = [];
    final Set<String> addedTestIdentifiers = {};

    for (var category in orderedCategories) {
      final tests = CognitiveTests.getTestsForCategory(category);
      for (var test in tests) {
        if (!addedTestIdentifiers.contains(test.identifier)) {
          orderedTests.add(test as RPStep);
          addedTestIdentifiers.add(test.identifier);
        }
      }
    }

    print(
      "Complete cognition task includes tests: ${orderedTests.map((t) => t.identifier).toList()}",
    );

    return _buildTask(
      "cognition_task_complete",
      'Évaluation Cognitive Complète',
      'Vous allez passer une série de tests cognitifs pour évaluer différents domaines de votre cognition. '
          'Cela peut prendre environ 20 à 30 minutes. Vous pouvez quitter à tout moment, et vos résultats partiels seront enregistrés.',
      orderedTests,
    );
  }

  RPOrderedTask _buildCognitionTaskForCategory(String category) {
    final tests = CognitiveTests.getTestsForCategory(category);
    return _buildTask(
      'cognition_task_${category.toLowerCase()}',
      'Test $category',
      'Vous avez choisi un test dans la catégorie $category. Suivez les instructions pour chaque activité.',
      tests.cast<RPStep>(),
    );
  }

  RPOrderedTask _buildTaskForIndividualTest(dynamic activity, String testName) {
    return _buildTask(
      'cognition_task_${activity.identifier}',
      testName,
      'Vous allez passer le test $testName. Suivez les instructions pour compléter l\'activité.',
      [activity as RPStep],
    );
  }

  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<bool> _saveResultsToFirestore(
    RPTaskResult result, {
    bool completed = true,
    String? testType,
    String? testName,
  }) async {
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
        'localisation_quiz': 'score',
      };

      Map<String, dynamic> scores = {};
      for (final entry in result.results.entries) {
        if (entry.value is RPActivityResult) {
          final stepResult = entry.value as RPActivityResult;
          final identifier = stepResult.identifier;
          if (identifier.startsWith('intro') ||
              identifier.startsWith('completion'))
            continue;

          final resultData =
              stepResult.results['result'] ?? stepResult.results['score'];
          if (resultData != null) {
            if (resultData is Map<String, dynamic>) {
              String scoreKey = scoreKeys[identifier] ?? 'score';
              dynamic scoreValue =
                  resultData[scoreKey] ?? resultData['score'] ?? 0;
              scores[identifier] =
                  identifier == 'localisation_quiz'
                      ? 5
                      : _parseToInt(scoreValue);
            } else if (resultData is int) {
              scores[identifier] =
                  identifier == 'localisation_quiz' ? 5 : resultData;
            }
          }
        }
      }

      if (scores.isEmpty) {
        return false;
      }

      int mmseScore =
          testType == 'Complet'
              ? CognitiveTests.calculateTotalMMSEScore(scores)
              : 0;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cognitive_results')
          .add({
            'timestamp': Timestamp.now(),
            'scores': scores,
            'mmseScore': mmseScore,
            'completed': completed,
            'category':
                widget.isCompleteTest
                    ? 'Complet'
                    : (widget.category.isNotEmpty
                        ? widget.category
                        : 'Individuel'),
            'testType':
                testType ??
                (widget.isCompleteTest
                    ? 'Complet'
                    : (widget.category.isNotEmpty
                        ? 'Catégorie'
                        : 'Individuel')),
            'testName': testName ?? '',
          });
      return true;
    } catch (e, stackTrace) {
      print('Erreur lors de la sauvegarde dans Firestore : $e');
      print('Stack trace : $stackTrace');
      return false;
    }
  }

  Future<TestResult> _runCognitiveTest(
    BuildContext context,
    RPOrderedTask task,
  ) async {
    final completer = Completer<TestResult>();
    bool hasCompleted = false;

    void complete(TestResult result) {
      if (!hasCompleted && !completer.isCompleted) {
        hasCompleted = true;
        completer.complete(result);
      }
    }

    if (task.steps.any((step) => step.identifier == 'localisation_quiz')) {
      final quizStep =
          task.steps.firstWhere(
                (step) => step.identifier == 'localisation_quiz',
              )
              as RPQuizActivity;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => GradientBackground(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    title: const Text('Localisation Quiz'),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                  body: quizStep.createWidget(context, (result) {
                    final taskResult = RPTaskResult(
                      identifier: task.identifier,
                    );
                    taskResult.results[result.identifier] = result;
                    complete(TestResult(result: taskResult, isCompleted: true));
                    Navigator.of(context).pop();
                  }),
                ),
              ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => WillPopScope(
                onWillPop: () async {
                  if (!_isTestRunning) return true;
                  complete(TestResult(result: null, isCompleted: false));
                  return true;
                },
                child: Theme(
                  data: Theme.of(context).copyWith(
                    scaffoldBackgroundColor: Colors.transparent,
                    appBarTheme: const AppBarTheme(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      titleTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
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
                              complete(
                                TestResult(result: null, isCompleted: false),
                              );
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
                            task: task,
                            onSubmit: (res) {
                              complete(
                                TestResult(result: res, isCompleted: true),
                              );
                              Navigator.of(context).pop();
                            },
                            onCancel: (res) {
                              complete(
                                TestResult(result: res, isCompleted: false),
                              );
                              Navigator.of(context).pop();
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
    }

    return completer.future;
  }

  Future<void> _handleTestResult(
    BuildContext context,
    TestResult testResult, {
    String? testType,
    String? testName,
  }) async {
    try {
      if (testResult.isCompleted && testResult.result != null) {
        final scores = <String, dynamic>{};
        for (final entry in testResult.result!.results.entries) {
          if (entry.value is RPActivityResult) {
            final stepResult = entry.value as RPActivityResult;
            final identifier = stepResult.identifier;
            if (identifier.startsWith('intro') ||
                identifier.startsWith('completion'))
              continue;
            final resultData =
                stepResult.results['result'] ?? stepResult.results['score'];
            if (resultData != null) {
              if (resultData is Map<String, dynamic>) {
                final score =
                    resultData['score'] ??
                    resultData['Total taps'] ??
                    resultData['reactionTime'] ??
                    0;
                scores[identifier] =
                    identifier == 'localisation_quiz' ? 5 : _parseToInt(score);
              } else if (resultData is int) {
                scores[identifier] =
                    identifier == 'localisation_quiz' ? 5 : resultData;
              }
            }
          }
        }

        final mmseScore =
            testType == 'Complet'
                ? CognitiveTests.calculateTotalMMSEScore(scores)
                : null;

        if (mounted) {
          // Navigation vers l'écran des résultats
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultsScreen(scores: scores, mmseScore: mmseScore),
              settings: const RouteSettings(name: '/results'),
            ),
          );
          
          // Sauvegarde des résultats dans Firestore
          final saved = await _saveResultsToFirestore(
            testResult.result!,
            completed: true,
            testType: testType,
            testName: testName,
          );
          
          // CORRECTION - Au lieu de retourner immédiatement à l'écran principal,
          // on attend que l'affichage de la SnackBar soit terminé
          showCustomSnackBar(
            context,
            saved ? 'Résultats enregistrés avec succès !' : 'Aucun résultat à enregistrer.',
            isError: !saved
          );
          
          // Attendre que le snackbar s'affiche avant de naviguer
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Navigation adaptée selon le type de test
          if (widget.category.isEmpty && !widget.isCompleteTest && mounted) {
            // Pour les tests individuels - retour à l'écran principal
            // Utiliser un push remplacement pour éviter le problème d'écran noir
            Navigator.of(context).popUntil((route) => route.settings.name == '/');
          }
        }
      } else if (testResult.result != null) {
        final saved = await _saveResultsToFirestore(
          testResult.result!,
          completed: false,
          testType: testType,
          testName: testName,
        );
        
        showCustomSnackBar(
          context,
          saved ? 'Test annulé. Résultats partiels enregistrés.' : 'Test annulé. Aucun résultat partiel à enregistrer.',
          isError: !saved
        );
      } else if (mounted) {
        showCustomSnackBar(
          context,
          'Test annulé.',
          isError: true
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Erreur lors du traitement des résultats : $e',
          isError: true
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (widget.isCompleteTest || widget.category.isNotEmpty) {
          return _TestRunner(
            isTestRunning: _isTestRunning,
            onStartTest: () async {
              if (mounted) {
                setState(() => _isTestRunning = true);
              }
              final task =
                  widget.isCompleteTest
                      ? _buildCompleteCognitionTask()
                      : _buildCognitionTaskForCategory(widget.category);
              final testResult = await _runCognitiveTest(context, task);
              await _handleTestResult(
                context,
                testResult,
                testType: widget.isCompleteTest ? 'Complet' : 'Catégorie',
              );
              if (mounted) {
                setState(() => _isTestRunning = false);
              }
            },
            title:
                widget.isCompleteTest
                    ? 'Passer un Test Cognitif Complet'
                    : 'Test Cognitif - ${widget.category}',
          );
        }

        return _TestList(
          isTestRunning: _isTestRunning,
          onSelectTest: (test) async {
            if (mounted) {
              setState(() => _isTestRunning = true);
            }
            final task = _buildTaskForIndividualTest(
              test['activity'],
              test['name'],
            );
            final testResult = await _runCognitiveTest(context, task);
            await _handleTestResult(
              context,
              testResult,
              testType: 'Individuel',
              testName: test['name'],
            );
            if (mounted) {
              setState(() => _isTestRunning = false);
            }
          },
        );
      },
    );
  }
}

// Widget pour exécuter un test complet ou par catégorie
class _TestRunner extends StatelessWidget {
  final bool isTestRunning;
  final VoidCallback onStartTest;
  final String title;

  const _TestRunner({
    required this.isTestRunning,
    required this.onStartTest,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !isTestRunning,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Test Cognitif'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: onStartTest,
                    child: const Text('Démarrer le Test'),
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

// Widget pour afficher la liste des tests individuels
class _TestList extends StatelessWidget {
  final bool isTestRunning;
  final Function(Map<String, dynamic>) onSelectTest;

  const _TestList({required this.isTestRunning, required this.onSelectTest});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Tests Cognitifs'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez un test à passer :',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: ListView.builder(
                  itemCount: CognitiveTests.individualTests.length,
                  itemBuilder: (context, index) {
                    final test = CognitiveTests.individualTests[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          test['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onTap: isTestRunning ? null : () => onSelectTest(test),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}