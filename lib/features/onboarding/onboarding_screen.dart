import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const List<_OnboardingSlide> _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=1200&q=80',
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
    ),
    _OnboardingSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
    ),
    _OnboardingSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1473116763249-2faaef81ccda?auto=format&fit=crop&w=1200&q=80',
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
    ),
  ];

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
    final Size screenSize = MediaQuery.of(context).size;
    final double titleSize = (screenSize.width * 0.072).clamp(24.0, 32.0);
    final double descriptionSize = (screenSize.width * 0.042).clamp(14.0, 17.0);

    return Scaffold(
      backgroundColor: const Color(0xFF09002F),
      body: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF09002F), Color(0xFF0A2C72)],
            ),
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final _OnboardingSlide slide = _slides[index];
                    return Column(
                      children: <Widget>[
                        Expanded(
                          flex: 70,
                          child: Stack(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(32),
                                ),
                                child: SizedBox.expand(
                                  child: Image.network(
                                    slide.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: const Color(0xFF1B2F61),
                                            ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 14,
                                top: MediaQuery.of(context).padding.top + 8,
                                child: TextButton(
                                  onPressed: _completeOnboarding,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                  ),
                                  child: const Text(
                                    AppStrings.skip,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          flex: 30,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  slide.title,
                                  style: TextStyle(
                                    color: Color(0xFFF1F2FF),
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  slide.description,
                                  style: TextStyle(
                                    color: Color(0xFFCDD0EC),
                                    fontSize: descriptionSize,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(
                        _slides.length,
                        (int index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? const Color(0xFF5A1BFF)
                                : const Color(0xFF3A4A94),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A00FF),
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? AppStrings.getStarted
                              : AppStrings.next,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  final String imageUrl;
  final String title;
  final String description;
}
