import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../debug/debug_screen_viewer.dart';
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

  // Debug-only: set once the debug screen viewer has been opened, so a late
  // video-completion callback doesn't also call widget.onComplete() out from
  // under it. See lib/debug/debug_screen_viewer.dart — remove this,
  // _openDebugViewer and the button in build() when no longer needed.
  bool _navigatedToDebugViewer = false;

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
    if (_hasCompleted || !mounted || _navigatedToDebugViewer) return;
    _hasCompleted = true;
    _controller?.pause();
    widget.onComplete();
  }

  // Debug-only: stop the real app from navigating out from under the debug
  // screen viewer while it's open. See lib/debug/debug_screen_viewer.dart —
  // remove this, _openDebugViewer and the button in build() when no longer
  // needed.
  void _openDebugViewer() {
    _navigatedToDebugViewer = true;
    _controller?.pause();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DebugScreenViewer()));
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _isInitialized && controller != null
                ? RepaintBoundary(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Debug-only entry point into lib/debug/debug_screen_viewer.dart —
          // jump straight to any screen instead of walking the real
          // sign-in/onboarding flow. Remove this button, _openDebugViewer
          // and _navigatedToDebugViewer above when no longer needed.
          if (kDebugMode)
            Positioned(
              top: 48,
              right: 16,
              child: SafeArea(
                child: FloatingActionButton.small(
                  heroTag: 'debugScreenViewer',
                  onPressed: _openDebugViewer,
                  tooltip: 'Debug: screen viewer',
                  child: const Icon(Icons.bug_report_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
