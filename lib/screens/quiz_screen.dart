import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_correct/services/quiz_service.dart';
import 'package:course_correct/providers/progress_provider.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String moduleTitle;

  const QuizScreen({super.key, required this.courseId, required this.moduleId, required this.moduleTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();

  List<Map<String, dynamic>> _questions = [];
  final Map<int, int> _answers = {}; // questionIndex -> selectedOptionIndex
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final questions = await _quizService.getQuizzes(widget.courseId, widget.moduleId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load quiz. Please try again later.")),
      );
    }
  }

  void _submitQuiz() async {
    if (_answers.length < _questions.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final selectedIndex = _answers[i];
      if (selectedIndex != null &&
          _questions[i]['correct_answer'] == _questions[i]['options'][selectedIndex]) {
        correct++;
      }
    }

    final scorePercent = (correct / _questions.length) * 100;
    final isPassed = scorePercent >= 70;

    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    try {
      await _quizService.recordQuizAttempt(
        userId: progressProvider.userId,
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        score: correct,
        totalQuestions: _questions.length,
      );

      await progressProvider.updateQuizScore(widget.courseId, widget.moduleId, scorePercent);

      if (isPassed) {
        await progressProvider.markModuleComplete(widget.courseId, widget.moduleId, scorePercent);
        await progressProvider.unlockNextModule(widget.courseId, widget.moduleId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPassed
              ? "✅ Quiz passed! Great job!"
              : "❌ Quiz failed. Try again!"),
          backgroundColor: isPassed ? Colors.green : Colors.red,
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Q${index + 1}: ${q['question']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...List.generate(q['options'].length, (optIndex) {
                          return RadioListTile<int>(
                            title: Text(q['options'][optIndex]),
                            value: optIndex,
                            groupValue: _answers[index],
                            onChanged: (val) {
                              setState(() {
                                _answers[index] = val!;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitQuiz,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text("Submit Quiz"),
        ),
      ),
    );
  }
}
