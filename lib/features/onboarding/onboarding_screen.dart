import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onboarding_alarm_app/common_widgets/onboarding_page.dart';
import 'package:onboarding_alarm_app/common_widgets/primary_button.dart';
import 'package:onboarding_alarm_app/constants/app_colors.dart';
import 'package:onboarding_alarm_app/constants/app_strings.dart';
import 'package:onboarding_alarm_app/features/location/location_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _onboardingKey = 'onboarding_completed';

  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } on MissingPluginException {
      // Continue without persistence when plugin is unavailable.
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LocationScreen()),
    );
  }

  Future<void> _requestPermissionsAndComplete() async {
    await [Permission.location, Permission.notification].request();

    _completeOnboarding();
  }

  void _onNextPressed() {
    if (_currentPage == 2) {
      _requestPermissionsAndComplete();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const OnboardingPage(
        title: AppStrings.onboardingTitle1,
        description: AppStrings.onboardingDesc1,
        icon: Icons.mobile_friendly_outlined,
      ),
      const OnboardingPage(
        title: AppStrings.onboardingTitle2,
        description: AppStrings.onboardingDesc2,
        icon: Icons.location_on_outlined,
      ),
      const OnboardingPage(
        title: AppStrings.onboardingTitle3,
        description: AppStrings.onboardingDesc3,
        icon: Icons.alarm_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      AppStrings.skip,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() => _currentPage = index);
                },
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      pages.length,
                      (int index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: _currentPage == pages.length - 1
                        ? AppStrings.getStarted
                        : AppStrings.next,
                    onPressed: _onNextPressed,
                    icon: Icons.arrow_forward,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
