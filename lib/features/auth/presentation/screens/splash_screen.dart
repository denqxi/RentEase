import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset('assets/images/splash.mp4');
    try {
      await _controller.initialize();
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
      });

      _controller.play();

      _controller.addListener(() {
        if (!mounted || _hasCompleted) return;
        if (_controller.value.position >= _controller.value.duration &&
            !_controller.value.isPlaying) {
          _finishSplash();
        }
      });

      // Fallback timer in case video duration is long or listener missed end
      final duration = _controller.value.duration;
      Future.delayed(duration + const Duration(milliseconds: 300), () {
        _finishSplash();
      });
    } catch (e) {
      debugPrint('Error loading splash video: $e');
      // If video fails to load, proceed after a fallback delay
      Future.delayed(const Duration(seconds: 2), () {
        _finishSplash();
      });
    }
  }

  void _finishSplash() {
    if (_hasCompleted || !mounted) return;
    _hasCompleted = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

