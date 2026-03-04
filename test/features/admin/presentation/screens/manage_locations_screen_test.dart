import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_location_provider.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_destination_provider.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_locations_screen.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';

/// Mock HTTP overrides for image loading
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

/// Fake destination repository that doesn't touch Firebase
class FakeDestinationRepository implements DestinationRepository {
  final List<Location> _locations;
  final List<Destination> _destinations;

  FakeDestinationRepository({
    List<Location>? locations,
    List<Destination>? destinations,
  }) : _locations = locations ?? [],
       _destinations = destinations ?? [];

  @override
  Future<List<Location>> getAllLocations() async => _locations;

  @override
  Future<List<Destination>> getAllDestinations() async => _destinations;

  @override
  Future<void> createLocation(Location location) async {
    _locations.add(location);
  }

  @override
  Future<void> updateLocation(Location location) async {
    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index != -1) _locations[index] = location;
  }

  @override
  Future<void> deleteLocation(String id) async {
    _locations.removeWhere((l) => l.id == id);
  }

  // Stub all other methods from DestinationRepository
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  final mockLocations = [
    const Location(
      id: 'loc-1',
      destinationId: 'da-lat',
      name: 'Hồ Xuân Hương',
      image: 'https://via.placeholder.com/150',
      category: 'places',
      latitude: 11.9404,
      longitude: 108.4411,
    ),
    const Location(
      id: 'loc-2',
      destinationId: 'ninh-binh',
      name: 'Tràng An',
      image: 'https://via.placeholder.com/150',
      category: 'places',
    ),
  ];

  final mockDestinations = [
    const Destination(
      id: 'da-lat',
      name: 'Đà Lạt',
      description: 'City of flowers',
      heroImage: 'https://via.placeholder.com/150',
      engagementCount: 10,
    ),
    const Destination(
      id: 'ninh-binh',
      name: 'Ninh Bình',
      description: 'Heritage site',
      heroImage: 'https://via.placeholder.com/150',
      engagementCount: 5,
    ),
  ];

  Widget createWidgetUnderTest({
    List<Location>? locations,
    List<Destination>? destinations,
  }) {
    final fakeRepo = FakeDestinationRepository(
      locations: locations ?? List<Location>.from(mockLocations),
      destinations: destinations ?? List<Destination>.from(mockDestinations),
    );

    return ProviderScope(
      overrides: [destinationRepositoryProvider.overrideWithValue(fakeRepo)],
      child: const MaterialApp(home: ManageLocationsScreen()),
    );
  }

  testWidgets('Should display locations list', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Manage Locations'), findsOneWidget);
    expect(find.text('Hồ Xuân Hương'), findsOneWidget);
    expect(find.text('Tràng An'), findsOneWidget);
  });

  testWidgets('Should open add location form dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap the FAB to add
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add Location'), findsAtLeast(1));
    expect(find.text('Latitude (-90 to 90)'), findsOneWidget);
  });

  testWidgets('Should show delete confirmation dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap delete on first item
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();

    expect(find.text('Delete Location?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Should show empty state', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(locations: []));
    await tester.pumpAndSettle();

    expect(find.text('No locations found.'), findsOneWidget);
  });
}
