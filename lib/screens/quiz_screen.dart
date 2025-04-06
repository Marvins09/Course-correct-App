import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const QuizScreen({super.key, required this.courseId, required this.moduleId});

  @override
  QuizScreenState createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> questions = [];
  Map<int, String> selectedAnswers = {};
  bool quizCompleted = false;
  int correctAnswersCount = 0;
  int attempts = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuizQuestions();
    _fetchUserQuizProgress();
  }

  Future<void> _fetchQuizQuestions() async {
    try {
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
                "explanation": doc["explanation"] ?? "No explanation provided.",
              };
            }).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching quiz questions: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserQuizProgress() async {
    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('user_progress')
              .doc(userId)
              .collection('courses')
              .doc(widget.courseId)
              .collection('modules')
              .doc(widget.moduleId)
              .collection('quizzes')
              .doc("quiz_progress")
              .get();

      if (doc.exists) {
        setState(() {
          quizCompleted = doc["completed"] ?? false;
          attempts = doc["attempts"] ?? 0;
          correctAnswersCount = doc["score"] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching quiz progress: $e");
    }
  }

  Future<void> _submitQuiz() async {
    correctAnswersCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]["correct_answer"]) {
        correctAnswersCount++;
      }
    }

    attempts++;

    await _firestore
        .collection('user_progress')
        .doc(userId)
        .collection('courses')
        .doc(widget.courseId)
        .collection('modules')
        .doc(widget.moduleId)
        .collection('quizzes')
        .doc("quiz_progress")
        .set({
          "completed": true,
          "score": correctAnswersCount,
          "attempts": attempts,
          "completedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _firestore
        .collection('user_progress')
        .doc(userId)
        .collection('courses')
        .doc(widget.courseId)
        .collection('modules')
        .doc(widget.moduleId)
        .set({"unlocked": true}, SetOptions(merge: true));

    setState(() {
      quizCompleted = true;
    });

    _showSnackbar(
      "🎉 Quiz Submitted! You scored $correctAnswersCount/${questions.length}.",
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body:
          isLoading
              ? Center(child: Lottie.asset('assets/loading.json', width: 150))
              : questions.isEmpty
              ? Center(child: Lottie.asset('assets/no_data.json', width: 200))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Q${index + 1}: ${questions[index]["question"]}",
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  ...questions[index]["options"].map<Widget>(
                                    (option) => RadioListTile<String>(
                                      title: Text(option),
                                      value: option,
                                      groupValue: selectedAnswers[index],
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
                                  ),
                                  if (quizCompleted)
                                    Text(
                                      "✔ Correct Answer: ${questions[index]["correct_answer"]}",
                                      style: const TextStyle(
                                        color: Colors.green,
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
                  ],
                ),
              ),
    );
  }
}
