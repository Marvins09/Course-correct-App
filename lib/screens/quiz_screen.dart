import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String userId =
      FirebaseAuth.instance.currentUser!.uid; // ✅ Use actual user ID

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

  /// ✅ Fetch quiz questions from Firestore
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
                "correct_answer": doc["correctAnswer"],
                "explanation": doc["explanation"] ?? "No explanation provided.",
              };
            }).toList();
      });
    } catch (e) {
      debugPrint("❌ Error fetching quiz questions: $e");
    }
  }

  /// ✅ Fetch user's quiz progress from Firestore
  Future<void> _fetchUserQuizProgress() async {
    try {
      DocumentSnapshot doc =
          await _firestore
              .collection('user_progress')
              .doc(userId) // ✅ Uses actual user ID
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
    setState(() => isLoading = false);
  }

  /// ✅ Submit quiz and store results in Firestore
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
        .doc(userId) // ✅ Uses actual user ID
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

    setState(() {
      quizCompleted = true;
    });

    _showSnackbar(
      "🎉 Quiz Submitted! You scored $correctAnswersCount/${questions.length}.",
    );
  }

  /// ✅ Show SnackBar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// ✅ Retry quiz (reset answers)
  void _retryQuiz() {
    setState(() {
      selectedAnswers.clear();
      quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : questions.isEmpty
              ? const Center(child: Text("No quiz questions available."))
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
                      Column(
                        children: [
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
                          ElevatedButton(
                            onPressed: _retryQuiz,
                            child: const Text("Retry Quiz"),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
    );
  }
}
