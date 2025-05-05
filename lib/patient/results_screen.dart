import 'package:flutter/material.dart';
import '../shared/widgets/gradient_background.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> scores;
  final int? mmseScore;

  const ResultsScreen({super.key, required this.scores, this.mmseScore});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Résultats'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Vos scores',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (mmseScore != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Score MMSE : $mmseScore/30',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final testName = scores.keys.elementAt(index);
                    final score = scores[testName];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      child: ListTile(
                        title: Text(
                          testName,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        trailing: Text(
                          score.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}