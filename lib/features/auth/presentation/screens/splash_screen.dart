import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../features/onboarding/model/onboarding_page_data.dart';

/// Splash screen that plays the introductory video and pre-caches
/// the onboarding hero assets in the background to ensure zero jank and
/// instantaneous 60/120fps rendering on real devices.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm up and pre-cache all onboarding images into GPU memory
    // during the splash video so there is zero frame drop when swiping.
    _precacheOnboardingImages();
  }

  void _precacheOnboardingImages() {
    for (final page in OnboardingPageData.pages) {
      precacheImage(AssetImage(page.imageAsset), context);
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset('assets/images/splash.mp4');
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _isInitialized = true;
      });

      controller.play();

      controller.addListener(() {
        if (!mounted || _hasCompleted) return;
        if (controller.value.position >= controller.value.duration &&
            !controller.value.isPlaying) {
          _finishSplash();
        }
      });

      // Fallback timer in case video duration is long or listener missed end
      final duration = controller.value.duration;
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
    _controller?.pause();
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isInitialized && controller != null
            ? RepaintBoundary(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
