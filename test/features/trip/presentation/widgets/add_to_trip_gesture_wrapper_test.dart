import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/presentation/widgets/add_to_trip_gesture_wrapper.dart';
import 'package:tour_vn/features/trip/presentation/widgets/day_picker_bottom_sheet.dart';

void main() {
  group('TripItemData', () {
    test('creates location item with factory constructor', () {
      final item = TripItemData.fromLocation(
        id: 'loc-1',
        name: 'Hội An Ancient Town',
        imageUrl: 'https://example.com/image.jpg',
        categoryEmoji: '🏛️',
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
      );

      expect(item.id, 'loc-1');
      expect(item.name, 'Hội An Ancient Town');
      expect(item.imageUrl, 'https://example.com/image.jpg');
      expect(item.type, 'location');
      expect(item.emoji, '🏛️');
      expect(item.destinationId, 'da-nang');
      expect(item.destinationName, 'Đà Nẵng');
    });

    test('creates review item with factory constructor', () {
      final item = TripItemData.fromReview(
        id: 'rev-1',
        name: 'Minh Anh',
        imageUrl: 'https://example.com/review.jpg',
        destinationId: 'ha-noi',
        destinationName: 'Hà Nội',
      );

      expect(item.id, 'rev-1');
      expect(item.name, 'Minh Anh');
      expect(item.imageUrl, 'https://example.com/review.jpg');
      expect(item.type, 'review');
      expect(item.emoji, isNull);
      expect(item.destinationId, 'ha-noi');
      expect(item.destinationName, 'Hà Nội');
    });

    test('handles null optional fields', () {
      const item = TripItemData(
        id: 'test-1',
        name: 'Test Item',
        type: 'location',
        destinationId: 'test-dest',
        destinationName: 'Test Destination',
      );

      expect(item.id, 'test-1');
      expect(item.name, 'Test Item');
      expect(item.imageUrl, isNull);
      expect(item.emoji, isNull);
    });
  });

  group('AddToTripGestureWrapper', () {
    late TripItemData testItemData;

    setUp(() {
      testItemData = TripItemData.fromLocation(
        id: 'loc-1',
        name: 'Test Location',
        imageUrl: 'https://example.com/image.jpg',
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
      );
    });

    testWidgets('wraps child widget correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              child: Container(
                key: const Key('test-child'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('test-child')), findsOneWidget);
    });

    testWidgets('calls onTap callback on single tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              onTap: () => tapped = true,
              child: Container(
                key: const Key('tappable'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('tappable')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows Day Picker on long press', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddToTripGestureWrapper(
                itemData: testItemData,
                child: Container(
                  key: const Key('long-pressable'),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(const Key('long-pressable')));
      await tester.pumpAndSettle();

      // Day Picker Bottom Sheet should be displayed
      expect(find.text('Thêm vào chuyến đi'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
    });

    testWidgets('calls custom onLongPress callback when provided', (
      tester,
    ) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              onLongPress: () => longPressed = true,
              child: Container(
                key: const Key('custom-long-press'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byKey(const Key('custom-long-press')));
      await tester.pump();

      expect(longPressed, isTrue);
      // Default Day Picker should NOT be shown
      expect(find.text('Thêm vào chuyến đi'), findsNothing);
    });

    testWidgets('applies scale animation when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              enableScaleAnimation: true,
              child: Container(
                key: const Key('animated'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Find Transform.scale widget (from animation)
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('respects custom long press duration', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              longPressDuration: const Duration(milliseconds: 800),
              onLongPress: () => longPressed = true,
              child: Container(
                key: const Key('custom-duration'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Start pressing
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('custom-duration'))),
      );

      // Wait less than custom duration
      await tester.pump(const Duration(milliseconds: 500));
      expect(longPressed, isFalse);

      // Wait for full duration
      await tester.pump(const Duration(milliseconds: 400));
      expect(longPressed, isTrue);

      await gesture.up();
    });

    testWidgets('cancels long-press when finger moves (scroll detection)', (
      tester,
    ) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              movementTolerance: 10.0,
              onLongPress: () => longPressed = true,
              child: Container(
                key: const Key('scroll-test'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byKey(const Key('scroll-test')));

      // Start pressing
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 200));

      // Move finger more than tolerance (simulating scroll)
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();

      // Wait past long-press duration
      await tester.pump(const Duration(milliseconds: 500));

      // Long press should have been cancelled due to movement
      expect(longPressed, isFalse);

      await gesture.up();
    });

    testWidgets('allows slight finger wobble within tolerance', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              movementTolerance: 10.0,
              onLongPress: () => longPressed = true,
              child: Container(
                key: const Key('wobble-test'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byKey(const Key('wobble-test')));

      // Start pressing
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 200));

      // Move finger slightly within tolerance
      await gesture.moveBy(const Offset(5, 5));
      await tester.pump();

      // Wait for long-press duration
      await tester.pump(const Duration(milliseconds: 400));

      // Long press should still trigger
      expect(longPressed, isTrue);

      await gesture.up();
    });

    testWidgets('cancels tap when finger moves (prevents nav during scroll)', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddToTripGestureWrapper(
              itemData: testItemData,
              movementTolerance: 10.0,
              onTap: () => tapped = true,
              child: Container(
                key: const Key('scroll-tap-test'),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byKey(const Key('scroll-tap-test')));

      // Start pressing
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 50));

      // Move finger more than tolerance (simulating scroll)
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();

      // Release finger
      await gesture.up();
      await tester.pump();

      // Tap should NOT have been triggered due to movement
      expect(tapped, isFalse);
    });
  });

  group('DayPickerBottomSheet', () {
    late TripItemData locationItem;
    late TripItemData reviewItem;

    setUp(() {
      locationItem = TripItemData.fromLocation(
        id: 'loc-1',
        name: 'Bà Nà Hills',
        imageUrl: 'https://example.com/bana.jpg',
        categoryEmoji: '⛰️',
        destinationId: 'da-nang',
        destinationName: 'Đà Nẵng',
      );

      reviewItem = TripItemData.fromReview(
        id: 'rev-1',
        name: 'Minh Anh',
        imageUrl: 'https://example.com/avatar.jpg',
        destinationId: 'ha-noi',
        destinationName: 'Hà Nội',
      );
    });

    testWidgets('displays correct title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DayPickerBottomSheet.show(
                    context: context,
                    itemData: locationItem,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm vào chuyến đi'), findsOneWidget);
    });

    testWidgets('displays location item correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DayPickerBottomSheet.show(
                    context: context,
                    itemData: locationItem,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Bà Nà Hills'), findsOneWidget);
      expect(find.text('Địa điểm'), findsOneWidget);
    });

    testWidgets('displays review item correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DayPickerBottomSheet.show(
                    context: context,
                    itemData: reviewItem,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Minh Anh'), findsOneWidget);
      expect(find.text('Bài review'), findsOneWidget);
    });

    testWidgets('displays day pills and time slots', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DayPickerBottomSheet.show(
                    context: context,
                    itemData: locationItem,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify day pills exist
      expect(find.text('Ngày 1'), findsOneWidget);
      expect(find.text('Ngày 2'), findsOneWidget);
      expect(find.text('Ngày 3'), findsOneWidget);

      // Verify time slots exist
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Trưa'), findsOneWidget);
      expect(find.text('Chiều'), findsOneWidget);
      expect(find.text('Tối'), findsOneWidget);
    });

    testWidgets('closes on confirm with time slot selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DayPickerBottomSheet.show(
                    context: context,
                    itemData: locationItem,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm vào chuyến đi'), findsOneWidget);

      // Select a time slot to enable confirm button
      await tester.tap(find.text('Sáng'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm vào lịch trình'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm vào chuyến đi'), findsNothing);
    });

    testWidgets('has correct border radius (24px)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DayPickerBottomSheet(itemData: locationItem)),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;

      expect(borderRadius.topLeft.x, 24);
      expect(borderRadius.topRight.x, 24);
    });
  });
}
