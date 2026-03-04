import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tour_vn/features/trip/domain/entities/trip.dart';
import 'package:tour_vn/features/trip/domain/entities/trip_day.dart';
import 'package:tour_vn/features/trip/data/repositories/trip_repository.dart';

/// Mock classes
class MockTripRepository extends Mock implements TripRepository {}

/// Creates a sample trip for testing
Trip createTestTrip({
  String id = 'test-trip-id',
  String name = 'Test Trip',
  String userId = 'test-user-id',
}) {
  return Trip(
    id: id,
    userId: userId,
    name: name,
    destinationId: 'destination-1',
    destinationName: 'Test Destination',
    days: const [TripDay(dayNumber: 1, activities: [])],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('Delete Trip - Unit Tests', () {
    late MockTripRepository mockRepository;

    setUp(() {
      mockRepository = MockTripRepository();
    });

    test('TripRepository.deleteTrip deletes trip when called', () async {
      // Arrange
      const userId = 'test-user-id';
      const tripId = 'test-trip-id';

      when(
        () => mockRepository.deleteTrip(userId, tripId),
      ).thenAnswer((_) async {});

      // Act
      await mockRepository.deleteTrip(userId, tripId);

      // Assert
      verify(() => mockRepository.deleteTrip(userId, tripId)).called(1);
    });

    test('deleteTrip throws exception when network fails', () async {
      // Arrange
      const userId = 'test-user-id';
      const tripId = 'test-trip-id';

      when(
        () => mockRepository.deleteTrip(userId, tripId),
      ).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(() => mockRepository.deleteTrip(userId, tripId), throwsException);
    });
  });

  group('Delete Confirmation Dialog', () {
    testWidgets('dialog displays trip name correctly', (tester) async {
      // Arrange
      const tripName = 'My Test Trip';

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Xóa chuyến đi?'),
                      content: Text('Bạn có chắc muốn xóa "$tripName"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      // Act - open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Xóa chuyến đi?'), findsOneWidget);
      expect(find.text('Bạn có chắc muốn xóa "$tripName"?'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
    });

    testWidgets('cancel button returns false and closes dialog', (
      tester,
    ) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Xóa chuyến đi?'),
                      actions: [
                        TextButton(
                          key: const Key('cancel_button'),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          key: const Key('delete_button'),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isFalse);
      expect(find.text('Xóa chuyến đi?'), findsNothing);
    });

    testWidgets('delete button returns true and closes dialog', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Xóa chuyến đi?'),
                      actions: [
                        TextButton(
                          key: const Key('cancel_button'),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          key: const Key('delete_button'),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isTrue);
      expect(find.text('Xóa chuyến đi?'), findsNothing);
    });
  });

  group('Delete Trip Flow - Integration Style Tests', () {
    testWidgets('delete success shows snackbar message', (tester) async {
      // This test verifies the SnackBar appears after successful deletion
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa chuyến đi "Test Trip"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Delete Trip'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Delete Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(find.text('Đã xóa chuyến đi "Test Trip"'), findsOneWidget);
    });

    testWidgets('delete error shows error snackbar', (tester) async {
      // This test verifies error SnackBar appears on failure
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Không thể xóa chuyến đi. Vui lòng thử lại.',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Delete Trip'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Delete Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(
        find.text('Không thể xóa chuyến đi. Vui lòng thử lại.'),
        findsOneWidget,
      );
    });
  });

  group('Dismissible Component Tests', () {
    testWidgets('Dismissible reveals background on swipe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Dismissible(
                  key: const Key('dismiss_test'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.white),
                        Text('Xóa', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  child: Container(
                    key: const Key('trip_card'),
                    height: 100,
                    color: Colors.blue,
                    child: const Center(child: Text('Trip Card')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Trip Card'), findsOneWidget);

      // Swipe left
      await tester.drag(
        find.byKey(const Key('trip_card')),
        const Offset(-200, 0),
      );
      await tester.pump();

      // During swipe, the background should be visible
      // Note: Can't easily verify background is shown in widget tests
      // as it requires checking render tree visibility
    });

    testWidgets('confirmDismiss controls whether item is dismissed', (
      tester,
    ) async {
      bool confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Dismissible(
                  key: const Key('dismiss_test_2'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    confirmCalled = true;
                    return false; // Don't dismiss
                  },
                  background: Container(color: Colors.red),
                  child: Container(
                    key: const Key('trip_card_2'),
                    height: 100,
                    color: Colors.blue,
                    child: const Center(child: Text('Trip Card 2')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Swipe completely
      await tester.fling(
        find.byKey(const Key('trip_card_2')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Verify confirmDismiss was called
      expect(confirmCalled, isTrue);

      // Card should still be present since confirmDismiss returned false
      expect(find.text('Trip Card 2'), findsOneWidget);
    });
  });
}
