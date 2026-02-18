import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:onboarding_alarm_app/features/alarm/alarm_screen.dart';
import 'package:onboarding_alarm_app/features/location/location_controller.dart';
import 'package:onboarding_alarm_app/features/location/location_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();
  final LocationController _locationController = Get.find<LocationController>();

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
      _locationController.setPosition(position);
    } on LocationPermissionDeniedException {
      setState(() {
        _errorText = 'Location permission denied. Allow access to continue.';
      });
    } on LocationPermissionDeniedForeverException {
      setState(() {
        _errorText =
            'Location permission is permanently denied. Please enable it in settings.';
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

  Future<void> _handleHomeTap() async {
    if (!_canContinue) {
      await _requestLocation();
    }

    if (!mounted || !_canContinue) {
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AlarmScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double titleSize = (screenSize.width * 0.085).clamp(26.0, 34.0);
    final double subtitleSize = (screenSize.width * 0.045).clamp(14.0, 18.0);
    final double topImageGap = (screenSize.height * 0.05).clamp(24.0, 80.0);
    final double imageHeight = (screenSize.height * 0.30).clamp(190.0, 320.0);
    final String locationButtonLabel = _position == null
        ? 'Use Current Location'
        : '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}';

    return Scaffold(
      backgroundColor: const Color(0xFF09002F),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF09002F), Color(0xFF0B2375)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  'Welcome! Your Smart Travel Alarm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Stay on schedule and enjoy every moment of your journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE5E7F8),
                    fontSize: subtitleSize,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 100),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF27325F),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.landscape_rounded,
                            color: Colors.white70,
                            size: 44,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Spacer(),
                if (_errorText != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFF9DA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (_showSettingsAction)
                  TextButton(
                    onPressed: Geolocator.openAppSettings,
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (_showLocationSettingsAction)
                  TextButton(
                    onPressed: Geolocator.openLocationSettings,
                    child: const Text(
                      'Open Location Settings',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                _ActionButton(
                  label: _isLoading
                      ? 'Getting Location...'
                      : locationButtonLabel,
                  icon: Icons.my_location_outlined,
                  isPrimary: false,
                  onPressed: _isLoading ? null : _requestLocation,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Home',
                  isPrimary: true,
                  onPressed: _isLoading ? null : _handleHomeTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF5A00FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
              border: isPrimary
                  ? null
                  : Border.all(
                      color: isEnabled
                          ? const Color(0xFF4B63D7)
                          : const Color(0x664B63D7),
                      width: 1.2,
                    ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      icon,
                      size: 18,
                      color: isEnabled ? Colors.white : Colors.white54,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
