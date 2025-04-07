import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:course_correct/services/content_service.dart';
import 'package:course_correct/models/content_model.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:course_correct/screens/quiz_screen.dart';

class ModuleContentScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String moduleTitle;

  const ModuleContentScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.moduleTitle,
  });

  @override
  ModuleContentScreenState createState() => ModuleContentScreenState();
}

class ModuleContentScreenState extends State<ModuleContentScreen> {
  List<ContentModel> materials = [];
  bool isLoading = true;
  bool hasError = false;
  final ScrollController _scrollController = ScrollController();
  bool _showStartQuiz = false;

  @override
  void initState() {
    super.initState();
    _fetchCourseMaterials();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (!_showStartQuiz && currentScroll >= maxScroll - 50) {
      setState(() => _showStartQuiz = true);
    }
  }

  Future<void> _fetchCourseMaterials() async {
    try {
      List<ContentModel> data = await ContentService().getContents(
        widget.courseId,
        widget.moduleId,
      );

      setState(() {
        materials = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching course materials: $e");
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Widget _buildContentView(ContentModel content) {
    switch (content.type) {
      case ContentType.pdf:
      case ContentType.docx:
        return _buildWebView(content.contentUrl);
      case ContentType.txt:
        return _buildTextView(content.contentUrl);
      case ContentType.image:
        return _buildImageView(content.contentUrl);
      default:
        return const Center(child: Text("⚠ Unsupported file type."));
    }
  }

  Future<bool> _isValidUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Widget _buildWebView(String url) {
    return FutureBuilder<bool>(
      future: _isValidUrl(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !(snapshot.data ?? false)) {
          return const Center(
            child: Text("⚠ Unable to load document. Check permissions."),
          );
        } else {
          return WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(Uri.parse(url)),
          );
        }
      },
    );
  }

  Widget _buildTextView(String url) {
    return FutureBuilder<String>(
      future: _fetchTextFromUrl(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("⚠ Error loading text."));
        } else {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(child: Text(snapshot.data ?? "")),
          );
        }
      },
    );
  }

  Widget _buildImageView(String url) {
    return Center(child: Image.network(url, fit: BoxFit.contain));
  }

  Future<String> _fetchTextFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        debugPrint(
          "❌ Error fetching text file: Status code \${response.statusCode}",
        );
        return "Error loading text content.";
      }
    } catch (e) {
      debugPrint("❌ Error fetching text file: $e");
      return "Error loading text content.";
    }
  }

  Widget _buildResourcesSection(String videoUrl) {
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (videoId == null) return const SizedBox();

    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    return YoutubePlayerScaffold(
      controller: controller,
      builder: (context, player) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Resources',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: player,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "⚠ Failed to load materials. Try again later.",
          style: TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _fetchCourseMaterials,
          child: const Text("Retry"),
        ),
      ],
    );
  }

  void _onStartQuizPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          courseId: widget.courseId,
          moduleId: widget.moduleId,
          moduleTitle: widget.moduleTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.moduleTitle)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? _buildErrorView()
              : Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final content in materials) ...[
                              Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        content.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 500,
                                        child: _buildContentView(content),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (materials.first.videoUrl != null &&
                                materials.first.videoUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: _buildResourcesSection(materials.first.videoUrl!),
                              ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                    if (_showStartQuiz)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: ElevatedButton.icon(
                          onPressed: _onStartQuizPressed,
                          icon: const Icon(Icons.quiz),
                          label: const Text("Start Quiz"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
