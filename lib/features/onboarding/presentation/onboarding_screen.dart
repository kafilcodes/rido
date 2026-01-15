import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  Future<void> _onIntroEnd(BuildContext context) async {
    // Request permissions
    await [
      Permission.location,
      Permission.notification,
      Permission.sms,
    ].request();
    
    // Save to prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    // Navigate to Auth
    if (mounted) {
      context.go('/auth');
    }
  }

  Widget _buildImage(String assetName) {
    return Center(
      child: Lottie.asset(
        'assets/lottie/$assetName', 
        width: 90.w, // Increased size
        height: 50.h,
        fit: BoxFit.contain
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      allowImplicitScrolling: true,
      autoScrollDuration: null,
      infiniteAutoScroll: false,
      bodyPadding: EdgeInsets.only(top: 10.h), // Center the content vertically
      pages: [
        PageViewModel(
          title: "Request a Ride",
          body: "Get where you need to go, fast and safe.",
          image: _buildImage('request_a_ride.json'),
          decoration: PageDecoration(
            titleTextStyle: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
            bodyTextStyle: TextStyle(fontSize: 14.sp, color: Theme.of(context).textTheme.bodyMedium?.color),
            imagePadding: EdgeInsets.zero,
          ),
        ),
        PageViewModel(
          title: "Send a Parcel",
          body: "Deliver packages locally with ease.",
          image: _buildImage('send_a_parcel.json'),
          decoration: PageDecoration(
            titleTextStyle: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
            bodyTextStyle: TextStyle(fontSize: 14.sp, color: Theme.of(context).textTheme.bodyMedium?.color),
             imagePadding: EdgeInsets.zero,
          ),
        ),
        PageViewModel(
          title: "Get Started",
          body: "We need a few permissions to serve you better.",
          image: _buildImage('get_started.json'),
          decoration: PageDecoration(
            titleTextStyle: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
            bodyTextStyle: TextStyle(fontSize: 14.sp, color: Theme.of(context).textTheme.bodyMedium?.color),
             imagePadding: EdgeInsets.zero,
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      back: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
      skip: Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color)),
      next: Icon(Icons.arrow_forward, color: Theme.of(context).primaryColor), // Use primary color for next
      done: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Start', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: const Color(0xFFBDBDBD),
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}
