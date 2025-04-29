import 'package:research_package/research_package.dart';
import 'package:cognition_package/model.dart';

// Classe pour gérer tous les tests cognitifs
class CognitiveTests {
  // Liste des tests individuels avec leurs noms
  static final List<Map<String, dynamic>> individualTests = [
    {
      'name': 'Flanker Test',
      'activity': RPFlankerActivity(
        identifier: "flanker_test",
        lengthOfTest: 30,
        numberOfCards: 10,
      ),
      'categories': ['Attention & Calcul'],
    },
    {
      'name': 'Tapping Test',
      'activity': RPTappingActivity(
        identifier: "tapping_test",
        lengthOfTest: 10,
      ),
      'categories': ['Attention & Calcul'],
    },
    {
      'name': 'Trail Making Test',
      'activity': RPTrailMakingActivity(
        identifier: "trail_making_test",
        trailType: TrailType.B,
      ),
      'categories': ['Attention & Calcul'],
    },
    {
      'name': 'Picture Sequence Memory Test',
      'activity': RPPictureSequenceMemoryActivity(
        identifier: "picture_sequence_test",
        numberOfTests: 3,
        numberOfPics: 3,
        lengthOfTest: 90,
      ),
      'categories': ['Enregistrement', 'Rappel'],
    },
    {
      'name': 'Word Recall Test',
      'activity': RPWordRecallActivity(
        identifier: "word_recall_test",
        numberOfTests: 5,
        lengthOfTest: 90,
      ),
      'categories': ['Enregistrement', 'Rappel', 'Langage'],
    },
    {
      'name': 'Letter Tapping Test',
      'activity': RPLetterTappingActivity(
        identifier: "letter_tapping_test",
      ),
      'categories': ['Attention & Calcul'],
    },
    {
      'name': 'Paired Associates Learning Test',
      'activity': RPPairedAssociatesLearningActivity(
        identifier: "paired_associates_test",
        maxTestDuration: 100,
      ),
      'categories': ['Enregistrement', 'Rappel'],
    },
    {
      'name': 'Reaction Time Test',
      'activity': RPReactionTimeActivity(
        identifier: "reaction_time_test",
        lengthOfTest: 30,
        switchInterval: 4,
      ),
      'categories': ['Attention & Calcul'],
    },
    {
      'name': 'Stroop Effect Test',
      'activity': RPStroopEffectActivity(
        identifier: "stroop_test",
        lengthOfTest: 30,
        displayTime: 1000,
        delayTime: 750,
      ),
      'categories': ['Attention & Calcul'],
    },
    {
      'name': 'Corsi Block Tapping Test',
      'activity': RPCorsiBlockTappingActivity(
        identifier: "corsi_block_test",
      ),
      'categories': ['Enregistrement', 'Rappel'],
    },
    {
      'name': 'Rapid Visual Info Processing Test',
      'activity': RPRapidVisualInfoProcessingActivity(
        identifier: "rapid_visual_test",
        lengthOfTest: 60,
        interval: 9,
      ),
      'categories': ['Attention & Calcul'],
    },
    {
      'name': 'Visual Array Change Test',
      'activity': RPVisualArrayChangeActivity(
        identifier: "visual_array_test",
        numberOfTests: 5,
        lengthOfTest: 1000,
      ),
      'categories': ['Perception'],
    },
    {
      'name': 'Continuous Visual Tracking Test',
      'activity': RPContinuousVisualTrackingActivity(
        identifier: "visual_tracking_test",
        lengthOfTest: 60,
        amountOfTargets: 3,
      ),
      'categories': ['Perception'],
    },
    {
      'name': 'Delayed Recall Test',
      'activity': RPDelayedRecallActivity(
        identifier: "delayed_recall_test",
        numberOfTests: 5,
        lengthOfTest: 300,
      ),
      'categories': ['Rappel', 'Langage'],
    },
  ];

  // Méthode pour obtenir les tests d'une catégorie spécifique
  static List<dynamic> getTestsForCategory(String category) {
    return individualTests
        .where((test) => (test['categories'] as List<String>).contains(category))
        .map((test) => test['activity'])
        .toList();
  }

  // Méthode pour obtenir tous les tests (pour le test complet)
  static List<dynamic> getAllTests() {
    return individualTests.map((test) => test['activity']).toSet().toList();
  }
}