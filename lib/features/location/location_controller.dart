import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationController extends GetxController {
  final Rxn<Position> position = Rxn<Position>();

  String get displayLocation {
    final Position? value = position.value;
    if (value == null) {
      return 'Add your location';
    }

    return '${value.latitude.toStringAsFixed(5)}, ${value.longitude.toStringAsFixed(5)}';
  }

  void setPosition(Position newPosition) {
    position.value = newPosition;
  }
}
