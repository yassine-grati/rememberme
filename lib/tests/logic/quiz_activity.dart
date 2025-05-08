import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import '../question_exemple.dart';
import '../question_model.dart';

class RPQuizActivity extends RPStep {
  final String identifier;
  final List<QuestionModel> questions;
  final bool isCompleteTest;

  RPQuizActivity({
    required this.identifier,
    required this.questions,
    this.isCompleteTest = false,
  }) : super(identifier: identifier, title: "Localisation Quiz");

  @override
  Widget createWidget(BuildContext context, Function(RPResult) onResult) {
    print(
      "RPQuizActivity: createWidget called for identifier: $identifier with ${questions.length} questions, isCompleteTest: $isCompleteTest",
    );
    return _RPQuizActivityWidget(this, onResult);
  }
}

class _RPQuizActivityWidget extends StatefulWidget {
  final RPQuizActivity step;
  final Function(RPResult) onResult;

  const _RPQuizActivityWidget(this.step, this.onResult);

  @override
  _RPQuizActivityWidgetState createState() => _RPQuizActivityWidgetState();
}

class _RPQuizActivityWidgetState extends State<_RPQuizActivityWidget> {
  int _score = 5; // Fixed score at 5
  bool _answered = false;
  bool _btnPressed = false;
  PageController? _controller;
  String _btnText = "Question suivante";
  int _currentPage = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    print(
      "RPQuizActivityWidget: initState called with ${widget.step.questions.length} questions, isCompleteTest: ${widget.step.isCompleteTest}",
    );
    if (widget.step.questions.isEmpty) {
      print("RPQuizActivityWidget: Warning - Questions list is empty!");
      _completeQuiz(_score);
    } else {
      print(
        "RPQuizActivityWidget: Initializing controller for ${widget.step.questions.length} questions",
      );
      _controller = PageController(initialPage: 0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _completeQuiz(int score) {
    if (!_completed && mounted) {
      _completed = true;
      print(
        "RPQuizActivityWidget: Completing quiz with fixed score: $score, isCompleteTest: ${widget.step.isCompleteTest}",
      );
      final result = RPActivityResult(identifier: widget.step.identifier);
      result.results['score'] = score;
      widget.onResult(result);
    }
  }

  void _onAnswerSelected(bool isCorrect) {
    if (!_answered && mounted) {
      setState(() {
        _answered = true;
        _btnPressed = true;
        print(
          "RPQuizActivityWidget: Answer selected for question ${_currentPage + 1}, correct: $isCorrect, fixed score: $_score",
        );
      });
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    print(
      "RPQuizActivityWidget: Next question requested, current page: $_currentPage, isCompleteTest: ${widget.step.isCompleteTest}",
    );
    if (_currentPage == widget.step.questions.length - 1) {
      _completeQuiz(_score);
    } else {
      if (_controller != null) {
        _controller!.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInExpo,
        );
        if (mounted) {
          setState(() {
            _btnPressed = false;
            _answered = false;
            _currentPage++;
            _btnText =
                _currentPage == widget.step.questions.length - 1
                    ? (widget.step.isCompleteTest ? "Suivant" : "Terminer")
                    : "Question suivante";
          });
        }
      } else {
        print("RPQuizActivityWidget: Error - _controller is null");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      "RPQuizActivityWidget: Building UI for question ${_currentPage + 1} of ${widget.step.questions.length}, isCompleteTest: ${widget.step.isCompleteTest}",
    );
    if (_controller == null) {
      return const Center(
        child: Text(
          "Erreur: Impossible de charger les questions.",
          style: TextStyle(color: Colors.white, fontSize: 18.0),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child:
          widget.step.questions.isEmpty
              ? const Center(
                child: Text(
                  "Aucune question disponible pour ce quiz.",
                  style: TextStyle(color: Colors.white, fontSize: 18.0),
                ),
              )
              : PageView.builder(
                controller: _controller!,
                onPageChanged: (page) {
                  if (!mounted) return;
                  print(
                    "RPQuizActivityWidget: Page changed to question ${page + 1}",
                  );
                  setState(() {
                    _currentPage = page;
                    _btnText =
                        page == widget.step.questions.length - 1
                            ? (widget.step.isCompleteTest
                                ? "Suivant"
                                : "Terminer")
                            : "Question suivante";
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.step.questions.length,
                itemBuilder: (context, index) {
                  final questionModel = widget.step.questions[index];
                  final questionText =
                      questionModel.question ?? "Question non disponible";
                  final answerOptions = questionModel.answers ?? {};

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          "Question ${index + 1}/${widget.step.questions.length}",
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28.0,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white),
                      const SizedBox(height: 10.0),
                      SizedBox(
                        width: double.infinity,
                        height: 200.0,
                        child: Text(
                          questionText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                          ),
                        ),
                      ),
                      if (answerOptions.isNotEmpty)
                        ...answerOptions.entries.map((entry) {
                          final answerText = entry.key;
                          final isCorrect = entry.value;
                          return Container(
                            width: double.infinity,
                            height: 50.0,
                            margin: const EdgeInsets.only(
                              bottom: 20.0,
                              left: 12.0,
                              right: 12.0,
                            ),
                            child: RawMaterialButton(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              fillColor:
                                  _btnPressed
                                      ? isCorrect
                                          ? Colors.green
                                          : Colors.red
                                      : const Color(0xFF1976D2),
                              onPressed:
                                  !_answered
                                      ? () {
                                        _onAnswerSelected(isCorrect);
                                      }
                                      : null,
                              child: Text(
                                answerText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                          );
                        }).toList()
                      else
                        const Text(
                          "Aucune réponse disponible",
                          style: TextStyle(color: Colors.white, fontSize: 18.0),
                        ),
                      const SizedBox(height: 40.0),
                      RawMaterialButton(
                        onPressed: _answered ? _nextQuestion : null,
                        shape: const StadiumBorder(),
                        fillColor: Colors.blue,
                        padding: const EdgeInsets.all(18.0),
                        elevation: 0.0,
                        child: Text(
                          _btnText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
