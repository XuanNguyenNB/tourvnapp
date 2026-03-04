import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/destination_repository.dart';
import '../../domain/entities/destination.dart';

/// Provider for DestinationRepository
final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository();
});

/// Provider for fetching destination by ID
///
/// Usage:
/// ```dart
/// final destinationAsync = ref.watch(destinationByIdProvider('da-lat'));
/// ```
final destinationByIdProvider = FutureProvider.family<Destination, String>((
  ref,
  id,
) async {
  final repository = ref.watch(destinationRepositoryProvider);
  return repository.getDestinationById(id);
});

/// Provider for fetching all destinations
final allDestinationsProvider = FutureProvider<List<Destination>>((ref) async {
  final repository = ref.watch(destinationRepositoryProvider);
  return repository.getAllDestinations();
});

/// Provider for searching destinations
final searchDestinationsProvider =
    FutureProvider.family<List<Destination>, String>((ref, query) async {
      final repository = ref.watch(destinationRepositoryProvider);
      return repository.searchDestinations(query);
    });
