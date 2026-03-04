import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:tour_vn/features/admin/presentation/screens/manage_destinations_screen.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';

import 'package:tour_vn/features/destination/domain/entities/location.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class FakeDestinationRepository implements DestinationRepository {
  List<Destination> destinations = [
    const Destination(
      id: 'test-1',
      name: 'Test Destination 1',
      heroImage: 'https://via.placeholder.com/150',
      description: 'Desc 1',
      engagementCount: 100,
      region: 'North',
      postCount: 50,
      countryCode: 'VN',
      categories: ['Food'],
    ),
  ];

  @override
  Future<List<Destination>> getAllDestinations() async {
    return destinations;
  }

  @override
  Future<void> createDestination(Destination destination) async {
    destinations.add(destination);
  }

  @override
  Future<void> updateDestination(Destination destination) async {
    final index = destinations.indexWhere((d) => d.id == destination.id);
    if (index >= 0) {
      destinations[index] = destination;
    }
  }

  @override
  Future<void> deleteDestination(String id) async {
    destinations.removeWhere((d) => d.id == id);
  }

  @override
  Future<Destination> getDestinationById(String id) async {
    return destinations.firstWhere((d) => d.id == id);
  }

  @override
  Future<List<Destination>> getDestinationsByRegion(String region) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Destination>> searchDestinations(String query) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Location>> getLocationsByDestination(String destinationId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Location>> getLocationsByCategory(
    String destinationId,
    String category,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Location> getLocationById(String locationId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Location>> getAllLocations() async {
    throw UnimplementedError();
  }

  @override
  Future<List<Location>> searchLocations(String query) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createLocation(Location location) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteLocation(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateLocation(Location location) async {
    throw UnimplementedError();
  }

  @override
  Future<({List<Destination> items, DocumentSnapshot? lastDoc})>
  getDestinationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<({List<Location> items, DocumentSnapshot? lastDoc})>
  getLocationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Location>> getLocationsByIds(List<String> ids) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDestinationBatch(List<String> ids) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteLocationBatch(List<String> ids) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Location>> searchLocationsByKeywords(
    String keyword, {
    String? destinationId,
    int limit = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<int> fixInconsistentDestinationIds() async {
    return 0;
  }
}

void main() {
  late FakeDestinationRepository fakeRepo;

  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    fakeRepo = FakeDestinationRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [destinationRepositoryProvider.overrideWithValue(fakeRepo)],
      child: const MaterialApp(home: ManageDestinationsScreen()),
    );
  }

  testWidgets('Should display list of destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Manage Destinations'), findsOneWidget);
    expect(find.text('Test Destination 1'), findsOneWidget);
    expect(
      find.text('Desc 1'),
      findsNothing,
    ); // Description isn't shown in list directly
    expect(find.textContaining('North'), findsOneWidget); // Subtitle
  });

  testWidgets('Should open Add dialog and add new destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap the FAB to open add dialog
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Dialog title 'Add Destination' is visible (also appears in submit button)
    expect(find.text('Add Destination'), findsAtLeast(1));

    // Fill form
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ID (slug, e.g., da-lat)'),
      'test-2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Test Destination 2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hero Image URL'),
      'https://via.placeholder.com/150',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Desc 2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Region (e.g., Miền Trung)'),
      'South',
    );

    // Submit
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Add Destination').first,
    );
    await tester.pumpAndSettle();

    // Verify it was added to list
    expect(fakeRepo.destinations.length, 2);
    expect(find.text('Test Destination 2'), findsOneWidget);
  });

  testWidgets('Should open Edit dialog and update destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final editButton = find.byTooltip('Edit');
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Destination'), findsOneWidget);

    // Change name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Updated Destination 1',
    );

    // Submit
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(fakeRepo.destinations.first.name, 'Updated Destination 1');
    expect(find.text('Updated Destination 1'), findsOneWidget);
  });

  testWidgets('Should delete destination on confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final deleteButton = find.byTooltip('Delete');
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete Destination?'), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(fakeRepo.destinations.length, 0);
    expect(find.text('No destinations found.'), findsOneWidget);
  });
}
