import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late YoutubePlayerController _controller;
  bool isPlayerReady = false;

  @override
  void initState() {
    super.initState();

    // Extract video ID
    String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    dev.log("Extracted Video ID: $videoId");

    if (videoId == null || videoId.isEmpty) {
      dev.log("Invalid YouTube URL: ${widget.videoUrl}");
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        isLive: false,
      ),
    )..addListener(() {
      if (_controller.value.hasPlayed && !isPlayerReady) {
        setState(() {
          isPlayerReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(controller: _controller),
      builder: (context, player) {
        return Column(children: [player]);
      },
    );
  }
}
