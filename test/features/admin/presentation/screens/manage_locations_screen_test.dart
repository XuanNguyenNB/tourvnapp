import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/admin/presentation/providers/admin_category_provider.dart';
import 'package:tour_vn/features/admin/presentation/screens/manage_locations_screen.dart';
import 'package:tour_vn/features/destination/data/repositories/destination_repository.dart';
import 'package:tour_vn/features/destination/domain/entities/category.dart';
import 'package:tour_vn/features/destination/domain/entities/destination.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/destination/presentation/providers/destination_provider.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class FakeDestinationRepository implements DestinationRepository {
  FakeDestinationRepository({
    List<Location>? locations,
    List<Destination>? destinations,
  }) : _locations = locations ?? <Location>[],
       _destinations = destinations ?? <Destination>[];

  final List<Location> _locations;
  final List<Destination> _destinations;

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
    final index = _locations.indexWhere((item) => item.id == location.id);
    if (index != -1) {
      _locations[index] = location;
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    _locations.removeWhere((location) => location.id == id);
  }

  @override
  Future<({List<Destination> items, DocumentSnapshot? lastDoc})>
  getDestinationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    return (items: _destinations.take(limit).toList(), lastDoc: null);
  }

  @override
  Future<({List<Location> items, DocumentSnapshot? lastDoc})>
  getLocationsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
  }) async {
    final filtered = destinationId == null
        ? _locations
        : _locations
              .where((location) => location.destinationId == destinationId)
              .toList();
    return (items: filtered.take(limit).toList(), lastDoc: null);
  }

  @override
  Future<({List<Location> items, DocumentSnapshot? lastDoc})>
  fetchAdminLocations({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? destinationId,
    String? category,
    String search = '',
  }) async {
    var filtered = _locations.toList();
    if (destinationId != null && destinationId.isNotEmpty) {
      filtered = filtered
          .where((location) => location.destinationId == destinationId)
          .toList();
    }
    if (category != null && category.isNotEmpty) {
      filtered = filtered
          .where((location) => location.category == category)
          .toList();
    }
    if (search.trim().isNotEmpty) {
      final normalized = search.trim().toLowerCase();
      filtered = filtered
          .where((location) => location.name.toLowerCase().contains(normalized))
          .toList();
    }
    return (items: filtered.take(limit).toList(), lastDoc: null);
  }

  @override
  Future<int> fixInconsistentDestinationIds() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
      overrides: [
        destinationRepositoryProvider.overrideWithValue(fakeRepo),
        activeCategoriesProvider.overrideWith(
          (_) async => Category.defaultCategories.take(3).toList(),
        ),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(1600, 1600)),
          child: ManageLocationsScreen(),
        ),
      ),
    );
  }

  testWidgets('Should display locations list', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Quản lý Địa điểm'), findsOneWidget);
    expect(find.text('Hồ Xuân Hương'), findsOneWidget);
    expect(find.text('Tràng An'), findsOneWidget);
  });

  testWidgets('Should open add location form dialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm địa điểm'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm Địa điểm'), findsOneWidget);
    expect(find.text('Vĩ độ (-90 đến 90)'), findsOneWidget);
  });

  testWidgets('Should show delete confirmation dialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa').first);
    await tester.pumpAndSettle();

    expect(find.text('Xóa địa điểm?'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Xóa'), findsWidgets);
  });

  testWidgets('Should show empty state', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(locations: []));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có địa điểm nào'), findsOneWidget);
  });
}
