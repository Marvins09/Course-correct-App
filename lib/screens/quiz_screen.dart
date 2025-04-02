import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const QuizScreen({super.key, required this.courseId, required this.moduleId});

  @override
  QuizScreenState createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> questions = [];
  Map<int, String> selectedAnswers = {};
  bool quizCompleted = false;
  int correctAnswersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchQuizQuestions();
  }

  Future<void> _fetchQuizQuestions() async {
    QuerySnapshot querySnapshot =
        await _firestore
            .collection('courses')
            .doc(widget.courseId)
            .collection('modules')
            .doc(widget.moduleId)
            .collection('quizzes')
            .get();

    setState(() {
      questions =
          querySnapshot.docs.map((doc) {
            return {
              "id": doc.id,
              "question": doc["question"],
              "options": List<String>.from(doc["options"]),
              "correct_answer": doc["correct_answer"],
              "explanation": doc["explanation"],
            };
          }).toList();
    });
  }

  void _submitQuiz() {
    correctAnswersCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]["correct_answer"]) {
        correctAnswersCount++;
      }
    }

    setState(() {
      quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body:
          questions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Q${index + 1}: ${questions[index]["question"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    children:
                                        (questions[index]["options"]
                                                as List<String>)
                                            .map(
                                              (option) => RadioListTile<String>(
                                                title: Text(option),
                                                value: option,
                                                groupValue:
                                                    selectedAnswers[index],
                                                onChanged:
                                                    quizCompleted
                                                        ? null
                                                        : (value) {
                                                          setState(() {
                                                            selectedAnswers[index] =
                                                                value!;
                                                          });
                                                        },
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  if (quizCompleted)
                                    Text(
                                      "✔ Correct Answer: ${questions[index]["correct_answer"]}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (quizCompleted)
                                    Text(
                                      "💡 Explanation: ${questions[index]["explanation"]}",
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: quizCompleted ? null : _submitQuiz,
                      child: const Text("Submit Quiz"),
                    ),
                    if (quizCompleted)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "🎉 You got $correctAnswersCount/${questions.length} correct!",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
