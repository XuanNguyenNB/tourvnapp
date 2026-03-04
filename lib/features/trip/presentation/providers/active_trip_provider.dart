import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trip.dart';

class ActiveTripNotifier extends Notifier<Trip?> {
  @override
  Trip? build() {
    return null;
  }

  void setActiveTrip(Trip trip) {
    state = trip;
  }

  void clearActiveTrip() {
    state = null;
  }
}

final activeTripProvider = NotifierProvider<ActiveTripNotifier, Trip?>(
  ActiveTripNotifier.new,
);
