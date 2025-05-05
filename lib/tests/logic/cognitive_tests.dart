import 'package:research_package/research_package.dart';
import 'package:cognition_package/model.dart';
import 'quiz_activity.dart';
import '../question_exemple.dart';

class CognitiveTests {
  static const Map<String, int> mmseWeights = {
    'Enregistrement': 3,
    'Attention et Calcul': 5,
    'Rappel': 3,
    'Langage': 9,
    'Localisation': 10,
  };

  static final List<Map<String, dynamic>> individualTests = [
    {
      'name': 'Picture Sequence Memory Test',
      'activity': RPPictureSequenceMemoryActivity(
        identifier: "picture_sequence_test",
        numberOfTests: 3,
        numberOfPics: 3,
        lengthOfTest: 90,
      ),
      'categories': ['Enregistrement', 'Rappel'],
      'mmseMaxScore': 9,
    },
    {
      'name': 'Word Recall Test',
      'activity': RPWordRecallActivity(
        identifier: "word_recall_test",
        numberOfTests: 5,
        lengthOfTest: 90,
      ),
      'categories': ['Enregistrement', 'Rappel', 'Langage'],
      'mmseMaxScore': 3,
    },
    {
      'name': 'Paired Associates Learning Test',
      'activity': RPPairedAssociatesLearningActivity(
        identifier: "paired_associates_test",
        maxTestDuration: 100,
      ),
      'categories': ['Enregistrement', 'Rappel'],
      'mmseMaxScore': 8,
    },
    {
      'name': 'Corsi Block Tapping Test',
      'activity': RPCorsiBlockTappingActivity(
        identifier: "corsi_block_test",
      ),
      'categories': ['Enregistrement', 'Rappel'],
      'mmseMaxScore': 9,
    },
    {
      'name': 'Flanker Test',
      'activity': RPFlankerActivity(
        identifier: "flanker_test",
        lengthOfTest: 30,
        numberOfCards: 10,
      ),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Tapping Test',
      'activity': RPTappingActivity(
        identifier: "tapping_test",
        lengthOfTest: 10,
      ),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 50,
    },
    {
      'name': 'Trail Making Test',
      'activity': RPTrailMakingActivity(
        identifier: "trail_making_test",
        trailType: TrailType.B,
      ),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 25,
    },
    {
      'name': 'Letter Tapping Test',
      'activity': RPLetterTappingActivity(
        identifier: "letter_tapping_test",
      ),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Reaction Time Test',
      'activity': RPReactionTimeActivity(
        identifier: "reaction_time_test",
        lengthOfTest: 30,
        switchInterval: 4,
      ),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Stroop Effect Test',
      'activity': RPStroopEffectActivity(
        identifier: "stroop_test",
        lengthOfTest: 30,
        displayTime: 1000,
        delayTime: 750,
      ),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Rapid Visual Info Processing Test',
      'activity': RPRapidVisualInfoProcessingActivity(
        identifier: "rapid_visual_test",
        lengthOfTest: 60,
        interval: 9,
      ),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Delayed Recall Test',
      'activity': RPDelayedRecallActivity(
        identifier: "delayed_recall_test",
        numberOfTests: 5,
        lengthOfTest: 300,
      ),
      'categories': ['Rappel', 'Langage'],
      'mmseMaxScore': 3,
    },
    {
      'name': 'Localisation Quiz',
      'activity': RPQuizActivity(
        identifier: "localisation_quiz",
        questions: questions,
      ),
      'categories': ['Localisation'],
      'mmseMaxScore': 10,
    },
  ];

  static List<dynamic> getTestsForCategory(String category) {
    return individualTests
        .where((test) => (test['categories'] as List<String>).contains(category))
        .map((test) => test['activity'])
        .toList();
  }

  static List<dynamic> getAllTests() {
    return individualTests.map((test) => test['activity']).toSet().toList();
  }

  static Map<String, double> normalizeScores(Map<String, dynamic> rawScores) {
    Map<String, double> mmseScores = {
      'Enregistrement': 0,
      'Attention et Calcul': 0,
      'Rappel': 0,
      'Langage': 0,
      'Localisation': 0,
    };
    Map<String, int> testCounts = {
      'Enregistrement': 0,
      'Attention et Calcul': 0,
      'Rappel': 0,
      'Langage': 0,
      'Localisation': 0,
    };

    for (var test in individualTests) {
      final identifier = test['activity'].identifier;
      final categories = test['categories'] as List<String>;
      final maxRawScore = test['mmseMaxScore'] as int;

      if (rawScores.containsKey(identifier)) {
        int rawScore = rawScores[identifier] is int ? rawScores[identifier] : 0;
        if (rawScore < 0 || rawScore > maxRawScore) {
          print('Score invalide pour $identifier: $rawScore (max: $maxRawScore)');
          rawScore = rawScore.clamp(0, maxRawScore);
        }

        double normalizedScore = (rawScore / maxRawScore) * 100;
        int categoryCount = categories.where((c) => mmseWeights.containsKey(c)).length;

        for (var category in categories) {
          if (mmseWeights.containsKey(category)) {
            mmseScores[category] = mmseScores[category]! + (normalizedScore / (categoryCount > 0 ? categoryCount : 1));
            testCounts[category] = testCounts[category]! + 1;
          }
        }
      }
    }

    mmseScores.forEach((category, score) {
      if (testCounts[category]! > 0) {
        mmseScores[category] = (score / testCounts[category]!) * (mmseWeights[category]! / 100);
      }
    });

    return mmseScores;
  }

  static int calculateTotalMMSEScore(Map<String, dynamic> rawScores) {
    final normalizedScores = normalizeScores(rawScores);
    double total = normalizedScores.entries
        .where((entry) => entry.key != 'Localisation')
        .fold(0.0, (sum, entry) => sum + entry.value);
    print("MMSE scores: $normalizedScores, Total: $total");
    return total.round().clamp(0, 30);
  }
}