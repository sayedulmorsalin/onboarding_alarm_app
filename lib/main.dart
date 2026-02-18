import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:onboarding_alarm_app/constants/app_colors.dart';
import 'package:onboarding_alarm_app/constants/app_strings.dart';
import 'package:onboarding_alarm_app/features/alarm/alarm_screen.dart';
import 'package:onboarding_alarm_app/features/alarm/alarm_service.dart';
import 'package:onboarding_alarm_app/features/location/location_controller.dart';
import 'package:onboarding_alarm_app/features/location/location_screen.dart';
import 'package:onboarding_alarm_app/features/onboarding/onboarding_screen.dart';
import 'package:onboarding_alarm_app/helpers/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz_data.initializeTimeZones();
  await AlarmService.instance.initialize();
  await [Permission.notification, Permission.scheduleExactAlarm].request();

  bool onboardingCompleted = false;
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    onboardingCompleted = prefs.getBool(_AppBoot.onboardingKey) ?? false;
  } on MissingPluginException {
    onboardingCompleted = false;
  }

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.onboardingCompleted, super.key});

  final bool onboardingCompleted;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AlarmController>()) {
      Get.put<AlarmController>(
        AlarmController(AlarmService.instance, DatabaseHelper.instance),
        permanent: true,
      );
    }
    if (!Get.isRegistered<LocationController>()) {
      Get.put<LocationController>(LocationController(), permanent: true);
    }

    return GetMaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: _AppBoot(onboardingCompleted: onboardingCompleted),
    );
  }
}

class _AppBoot extends StatelessWidget {
  const _AppBoot({required this.onboardingCompleted});

  static const String onboardingKey = 'onboarding_completed';

  final bool onboardingCompleted;

  @override
  Widget build(BuildContext context) {
    if (!onboardingCompleted) {
      return const OnboardingScreen();
    }

    return const LocationScreen();
  }
}
