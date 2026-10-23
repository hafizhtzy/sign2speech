import 'package:flutter/material.dart';

import 'onboarding_1_screen.dart';

/// Legacy & direct route forwarder for Onboarding Step 2.
/// Directly embeds the unified HajiCare PageView at slide 1.
class Onboarding2Screen extends StatelessWidget {
  const Onboarding2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Onboarding1Screen(initialPage: 1);
  }
}
