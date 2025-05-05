import 'package:flutter/material.dart';
import 'package:research_package/research_package.dart';
import '../question_exemple.dart';
import '../question_model.dart';

class RPQuizActivity extends RPStep {
  final String identifier;
  final List<QuestionModel> questions;

  RPQuizActivity({
    required this.identifier,
    required this.questions,
  }) : super(identifier: identifier, title: "Localisation Quiz");

  @override
  Widget createWidget(BuildContext context, Function(RPResult) onResult) {
    print("RPQuizActivity: createWidget called for identifier: $identifier with ${questions.length} questions");
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
  int _score = 0;
  bool _answered = false;
  bool _btnPressed = false;
  PageController? _controller;
  String _btnText = "Question suivante";
  int _currentPage = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    print("RPQuizActivityWidget: initState called with ${widget.step.questions.length} questions");
    if (widget.step.questions.isEmpty) {
      print("RPQuizActivityWidget: Warning - Questions list is empty!");
      _completeQuiz(0);
    } else {
      print("RPQuizActivityWidget: Questions loaded: ${widget.step.questions.map((q) => q.question).toList()}");
    }
    _controller = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _completeQuiz(int score) {
    if (!_completed) {
      _completed = true;
      print("RPQuizActivityWidget: Completing quiz with score: $score");
      final result = RPActivityResult(identifier: widget.step.identifier);
      result.results['score'] = score;
      widget.onResult(result); 
    }
  }

  void _onAnswerSelected(bool isCorrect) {
    if (!_answered) {
      setState(() {
        _answered = true;
        _btnPressed = true;
        if (isCorrect) {
          _score++;
        }
        print("RPQuizActivityWidget: Answer selected for question ${_currentPage + 1}, correct: $isCorrect, current score: $_score");
      });
    }
  }

  void _nextQuestion() {
    print("RPQuizActivityWidget: Next question requested, current page: $_currentPage");
    if (_currentPage == widget.step.questions.length - 1) {
      _completeQuiz(_score);
    } else {
      _controller!.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInExpo,
      );
      setState(() {
        _btnPressed = false;
        _answered = false;
        _currentPage++;
        if (_currentPage == widget.step.questions.length - 1) {
          _btnText = "Terminer";
        }
        print("RPQuizActivityWidget: Advanced to question ${_currentPage + 1}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("RPQuizActivityWidget: Building UI for question ${_currentPage + 1}");
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: widget.step.questions.isEmpty
          ? const Center(
              child: Text(
                "Aucune question disponible pour ce quiz.",
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
            )
          : PageView.builder(
              controller: _controller!,
              onPageChanged: (page) {
                print("RPQuizActivityWidget: Page changed to question ${page + 1}");
                setState(() {
                  _currentPage = page;
                  if (page == widget.step.questions.length - 1) {
                    _btnText = "Terminer";
                  } else {
                    _btnText = "Question suivante";
                  }
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.step.questions.length,
              itemBuilder: (context, index) {
                final questionModel = widget.step.questions[index];
                final questionText = questionModel.question ?? "Question non disponible";
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
                    const Divider(
                      color: Colors.white,
                    ),
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
                          margin: const EdgeInsets.only(bottom: 20.0, left: 12.0, right: 12.0),
                          child: RawMaterialButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            fillColor: _btnPressed
                                ? isCorrect
                                    ? Colors.green
                                    : Colors.red
                                : const Color(0xFF1976D2),
                            onPressed: !_answered
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
