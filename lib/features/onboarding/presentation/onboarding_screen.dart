import 'package:flutter/material.dart' as material;
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends material.StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  material.State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends material.State<OnboardingScreen> {
  final _introKey = material.GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(material.BuildContext context) async {
    await [Permission.location].request();
    if (context.mounted) context.go('/auth');
  }

  material.Widget _buildImage(String assetName) {
    return Lottie.asset(
      'assets/lottie/$assetName',
      width: 80.w,
      height: 40.h, 
      fit: material.BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const material.Icon(LucideIcons.imageOff, size: 50, color: material.Colors.red);
      },
    );
  }

  PageViewModel _buildPage({
    required String title,
    required String body,
    required String lottie,
    int imageFlex = 3, // Default flex
    double topPadding = 40.0, // Default top padding
  }) {
    return PageViewModel(
      // Custom Layout: Image Top, Text Bottom
      titleWidget: Padding(
        padding: const material.EdgeInsets.only(top: 20.0), 
        child: Text(title).h3().foreground().center(),
      ),
      // Body: Centered and Justified
      bodyWidget: Padding(
        padding: const material.EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          body,
          textAlign: material.TextAlign.center,
          style: Theme.of(context).typography.small.copyWith(
            color: Theme.of(context).colorScheme.mutedForeground,
            fontSize: 14,
          ), 
        ),
      ),
      image: Padding(
        padding: material.EdgeInsets.only(top: topPadding), 
        child: _buildImage(lottie),
      ),
      decoration: PageDecoration( // Removed const to allow custom flex
        pageColor: material.Colors.transparent,
        bodyPadding: const material.EdgeInsets.symmetric(horizontal: 24),
        imagePadding: material.EdgeInsets.zero,
        imageFlex: imageFlex, 
        bodyFlex: 2,
      ),
    );
  }
  
  // Helper for Gradient Text/Icon
  material.Widget _gradientWidget(material.Widget child) {
    return ShaderMask(
      shaderCallback: (bounds) => const material.LinearGradient(
        colors: [material.Color(0xFF6366F1), material.Color(0xFFA855F7)],
        begin: material.Alignment.topLeft,
        end: material.Alignment.bottomRight,
      ).createShader(bounds),
      child: child,
    );
  }

  @override
  material.Widget build(material.BuildContext context) {
    // USE SHADCN THEME for correct brightness/colors
    final theme = Theme.of(context);
    
    return material.Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: material.SafeArea(
        child: IntroductionScreen(
          key: _introKey,
          globalBackgroundColor: material.Colors.transparent,
          allowImplicitScrolling: true,
          pages: [
            _buildPage(
              title: "Request a Ride",
              body: "Request a ride get picked up by a nearby community driver",
              lottie: "request_a_ride.json",
            ),
            _buildPage(
              title: "Send a Parcel",
              body: "Confirm your driver to send a parcel safely to your destination",
              lottie: "send_a_parcel.json", 
              imageFlex: 4, // Bigger animation for 2nd slide
              topPadding: 20.0, // Less padding to accommodate size
            ),
            _buildPage(
              title: "Get Started",
              body: "Know your driver in advance and view current location in real time",
              lottie: "get_started.json", 
              imageFlex: 4, // Bigger animation for 3rd slide
              topPadding: 20.0,
            ),
          ],
          onDone: () => _onIntroEnd(context),
          onSkip: () => _onIntroEnd(context),
          showSkipButton: true,
          // Skip: Greyish, 60% opacity
          skip: material.Opacity(
            opacity: 0.6,
            child: const Text("Skip", style: material.TextStyle(fontWeight: material.FontWeight.w600)),
          ),
          // Next: Smaller Gradient Arrow (Size reduced from 28 to 24)
          next: _gradientWidget(const material.Icon(LucideIcons.arrowRight, size: 24, color: material.Colors.white)),
          // Done: Gradient Text
          done: _gradientWidget(const Text("Done", style: material.TextStyle(fontWeight: material.FontWeight.bold, fontSize: 16, color: material.Colors.white))),
          curve: material.Curves.fastLinearToSlowEaseIn,
          controlsMargin: const material.EdgeInsets.all(16),
          controlsPadding: const material.EdgeInsets.all(12.0),
          dotsDecorator: DotsDecorator(
            size: const material.Size(10.0, 10.0),
            color: material.Colors.grey.withOpacity(0.5),
            activeSize: const material.Size(22.0, 10.0),
            // We can't easily gradient the dot API, so we use the primary color (Indigo)
            activeColor: const material.Color(0xFF6366F1), 
            activeShape: material.RoundedRectangleBorder(
              borderRadius: material.BorderRadius.circular(25.0),
            ),
          ),
        ),
      ),
    );
  }
}
