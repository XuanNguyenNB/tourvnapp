import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../destination/data/repositories/destination_repository.dart';
import '../../../destination/domain/entities/destination.dart';
import '../../../destination/domain/entities/location.dart';
import '../../../destination/presentation/providers/destination_provider.dart';

final adminDestinationLookupProvider = FutureProvider<List<Destination>>((ref) {
  final repository = ref.watch(destinationRepositoryProvider);
  return repository.getAllDestinations();
});

final adminLocationLookupProvider = FutureProvider<List<Location>>((ref) {
  final repository = ref.watch(destinationRepositoryProvider);
  return repository.getAllLocations();
});
