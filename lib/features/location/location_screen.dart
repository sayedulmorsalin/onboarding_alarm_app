import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:onboarding_alarm_app/common_widgets/primary_button.dart';
import 'package:onboarding_alarm_app/constants/app_colors.dart';
import 'package:onboarding_alarm_app/constants/app_strings.dart';
import 'package:onboarding_alarm_app/features/alarm/alarm_screen.dart';
import 'package:onboarding_alarm_app/features/location/location_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();

  Position? _position;
  String? _errorText;
  bool _isLoading = false;
  bool _canContinue = false;
  bool _showSettingsAction = false;
  bool _showLocationSettingsAction = false;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _showSettingsAction = false;
      _showLocationSettingsAction = false;
    });

    try {
      final Position position = await _locationService.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
        _canContinue = true;
      });
    } on LocationPermissionDeniedException {
      setState(() {
        _errorText = AppStrings.deniedMessage;
      });
    } on LocationPermissionDeniedForeverException {
      setState(() {
        _errorText = AppStrings.deniedForeverMessage;
        _showSettingsAction = true;
      });
    } on AppLocationServiceDisabledException catch (error) {
      setState(() {
        _errorText = error.toString();
        _showLocationSettingsAction = true;
      });
    } catch (error) {
      setState(() {
        _errorText = 'Unable to fetch location: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  void _goToAlarmScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AlarmScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.locationTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Position',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_position != null) ...[
                        Text(
                          'Latitude: ${_position!.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Longitude: ${_position!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ] else
                        const Text(
                          'Tap the button below to fetch your location.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: AppStrings.requestLocation,
                onPressed: _requestLocation,
                isLoading: _isLoading,
                icon: Icons.my_location,
              ),
              if (_showSettingsAction) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _openSettings,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    AppStrings.openSettings,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
              if (_showLocationSettingsAction) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _openLocationSettings,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    AppStrings.openLocationSettings,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                label: AppStrings.continueToAlarms,
                onPressed: _canContinue ? _goToAlarmScreen : null,
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
