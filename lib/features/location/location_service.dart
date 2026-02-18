import 'package:geolocator/geolocator.dart';
import 'package:onboarding_alarm_app/helpers/permission_helper.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    final LocationPermission permissionStatus =
        await PermissionHelper.requestLocationPermission();

    if (permissionStatus == LocationPermission.denied) {
      throw LocationPermissionDeniedException('Location permission denied.');
    }

    if (permissionStatus == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException(
        'Location permission denied forever.',
      );
    }

    final bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      throw AppLocationServiceDisabledException();
    }

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }
}

class LocationPermissionDeniedException implements Exception {
  LocationPermissionDeniedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationPermissionDeniedForeverException implements Exception {
  LocationPermissionDeniedForeverException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppLocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Location services are disabled.';
}
