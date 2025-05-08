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
      'activity': RPPictureSequenceMemoryActivity(identifier: "picture_sequence_test", numberOfTests: 3, numberOfPics: 3, lengthOfTest: 90),
      'categories': ['Enregistrement', 'Rappel'],
      'mmseMaxScore': 9,
    },
    {
      'name': 'Word Recall Test',
      'activity': RPWordRecallActivity(identifier: "word_recall_test", numberOfTests: 5, lengthOfTest: 90),
      'categories': ['Enregistrement', 'Rappel', 'Langage'],
      'mmseMaxScore': 5,
    },
    {
      'name': 'Paired Associates Learning Test',
      'activity': RPPairedAssociatesLearningActivity(identifier: "paired_associates_test", maxTestDuration: 100),
      'categories': ['Enregistrement', 'Rappel'],
      'mmseMaxScore': 8,
    },
    {
      'name': 'Corsi Block Tapping Test',
      'activity': RPCorsiBlockTappingActivity(identifier: "corsi_block_test"),
      'categories': ['Enregistrement', 'Rappel'],
      'mmseMaxScore': 9,
    },
    {
      'name': 'Flanker Test',
      'activity': RPFlankerActivity(identifier: "flanker_test", lengthOfTest: 30, numberOfCards: 10),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Tapping Test',
      'activity': RPTappingActivity(identifier: "tapping_test", lengthOfTest: 10),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 100,
    },
    {
      'name': 'Trail Making Test',
      'activity': RPTrailMakingActivity(identifier: "trail_making_test", trailType: TrailType.B),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 25,
    },
    {
      'name': 'Letter Tapping Test',
      'activity': RPLetterTappingActivity(identifier: "letter_tapping_test"),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Reaction Time Test',
      'activity': RPReactionTimeActivity(identifier: "reaction_time_test", lengthOfTest: 30, switchInterval: 4),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Stroop Effect Test',
      'activity': RPStroopEffectActivity(identifier: "stroop_test", lengthOfTest: 30, displayTime: 1000, delayTime: 750),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Rapid Visual Info Processing Test',
      'activity': RPRapidVisualInfoProcessingActivity(identifier: "rapid_visual_test", lengthOfTest: 60, interval: 9),
      'categories': ['Attention et Calcul'],
      'mmseMaxScore': 10,
    },
    {
      'name': 'Delayed Recall Test',
      'activity': RPDelayedRecallActivity(identifier: "delayed_recall_test", numberOfTests: 3, lengthOfTest: 300),
      'categories': ['Rappel', 'Langage'],
      'mmseMaxScore': 3,
    },
    {
      'name': 'Visual Array Change Test',
      'activity': RPVisualArrayChangeActivity(identifier: "visual_array_test", numberOfTests: 5, lengthOfTest: 1000),
      'categories': ['Perception'],
    },
    {
      'name': 'Continuous Visual Tracking Test',
      'activity': RPContinuousVisualTrackingActivity(identifier: "visual_tracking_test", lengthOfTest: 60, amountOfTargets: 3),
      'categories': ['Perception'],
    },
    {
      'name': 'Localisation Quiz',
      'activity': RPQuizActivity(identifier: "localisation_quiz", questions: questions),
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

  static Map<String, double> calculateMMSEByThreshold(Map<String, dynamic> rawScores) {
    Map<String, double> mmseScores = {
      'Enregistrement': 0.0,
      'Attention et Calcul': 0.0,
      'Rappel': 0.0,
      'Langage': 0.0,
      'Localisation': 0.0,
    };

    for (var test in individualTests) {
      final identifier = test['activity'].identifier;
      final categories = test['categories'] as List<String>;
      final maxRawScore = test['mmseMaxScore'] as int? ?? 0;

      if (categories.contains('Perception') || !categories.any((c) => mmseWeights.containsKey(c))) {
        continue;
      }

      int rawScore = rawScores.containsKey(identifier) && rawScores[identifier] is int
          ? rawScores[identifier]
          : 0;

      if (identifier == 'localisation_quiz') {
        rawScore = 5; // Assuming 5/10 correct
      } else if (rawScore > maxRawScore) {
        rawScore = maxRawScore;
      }

      Map<String, double> contributions = {};

      for (var category in categories) {
        if (!mmseWeights.containsKey(category)) continue;

        double contribution = 0.0;
        if (category == 'Langage') {
          // Proportional scoring for Langage
          if (identifier == 'word_recall_test') {
            contribution = (rawScore / maxRawScore) * 4.5;
          } else if (identifier == 'delayed_recall_test') {
            contribution = (rawScore / maxRawScore) * 4.5;
          }
        } else {
          // Threshold-based scoring for other categories
          switch (identifier) {
            case 'delayed_recall_test':
              if (category == 'Rappel') contribution = (rawScore >= 3) ? 3.0 : 0.0;
              break;
            case 'stroop_test':
              if (category == 'Attention et Calcul') contribution = (rawScore > 0 && rawScore < 650 && rawScore <= 2) ? 1.0 : 0.0;
              break;
            case 'corsi_block_test':
              if (category == 'Enregistrement') contribution = (rawScore >= 5) ? 3.0 : 0.0;
              if (category == 'Rappel') contribution = (rawScore >= 4) ? 3.0 : 0.0;
              break;
            case 'picture_sequence_test':
              if (category == 'Enregistrement') contribution = (rawScore >= 5) ? 3.0 : 0.0;
              if (category == 'Rappel') contribution = (rawScore >= 4) ? 3.0 : 0.0;
              break;
            case 'paired_associates_test':
              if (category == 'Enregistrement') contribution = (rawScore >= 5) ? 3.0 : 0.0;
              if (category == 'Rappel') contribution = (rawScore >= 4) ? 3.0 : 0.0;
              break;
            case 'flanker_test':
              if (category == 'Attention et Calcul') contribution = (rawScore > 0 && rawScore < 500 && rawScore >= 90) ? 1.0 : 0.0;
              break;
            case 'tapping_test':
              if (category == 'Attention et Calcul') contribution = (rawScore >= 50) ? 1.0 : 0.0;
              break;
            case 'trail_making_test':
              if (category == 'Attention et Calcul') contribution = (rawScore > 0 && rawScore < 30) ? 1.0 : 0.0;
              break;
            case 'rapid_visual_test':
              if (category == 'Attention et Calcul') contribution = (rawScore >= 10) ? 1.0 : 0.0;
              break;
            case 'word_recall_test':
              if (category == 'Enregistrement') contribution = (rawScore >= 5) ? 3.0 : 0.0;
              if (category == 'Rappel') contribution = (rawScore >= 4) ? 3.0 : 0.0;
              break;
            case 'reaction_time_test':
              if (category == 'Attention et Calcul') contribution = (rawScore > 0 && rawScore < 600) ? 1.0 : 0.0;
              break;
            case 'letter_tapping_test':
              if (category == 'Attention et Calcul') contribution = (rawScore >= 90) ? 1.0 : 0.0;
              break;
            case 'localisation_quiz':
              if (category == 'Localisation') contribution = 5.0;
              break;
          }
        }
        contributions[category] = contribution;
      }

      contributions.forEach((category, contribution) {
        mmseScores[category] = (mmseScores[category]! + contribution).clamp(0.0, mmseWeights[category]!.toDouble());
      });
    }

    return mmseScores;
  }

  static int calculateTotalMMSEScore(Map<String, dynamic> rawScores) {
    final mmseScores = calculateMMSEByThreshold(rawScores);
    double total = mmseScores.entries
        .where((entry) => mmseWeights.containsKey(entry.key))
        .fold(0.0, (sum, entry) => sum + entry.value);
    int finalScore = total.round().clamp(0, 30);
    print('MMSE scores: $mmseScores, Total: $finalScore/30');
    return finalScore;
  }
}