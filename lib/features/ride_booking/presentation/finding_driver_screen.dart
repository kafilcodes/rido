import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

class FindingDriverScreen extends StatelessWidget {
  const FindingDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
       decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset('assets/lottie/ride.json', height: 15.h), // Reusing existing lottie
          SizedBox(height: 2.h),
          Text("Connecting to nearby drivers...").h3().foreground(),
          SizedBox(height: 2.h),
          const material.LinearProgressIndicator(), // Using Material indicator for now, or could use Progress from Shadcn if available
          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            child: Button.outline(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel Request"),
            ),
          )
        ],
      ),
    );
  }
}
