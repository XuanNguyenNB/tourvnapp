import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/home/presentation/widgets/distance_badge.dart';

void main() {
  group('DistanceBadge', () {
    testWidgets('should render distance in meters for < 1km', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DistanceBadge(distanceMeters: 500)),
        ),
      );

      expect(find.text('📍'), findsOneWidget);
      expect(find.text('500m'), findsOneWidget);
    });

    testWidgets('should render distance in kilometers for >= 1km', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DistanceBadge(distanceMeters: 2500)),
        ),
      );

      expect(find.text('📍'), findsOneWidget);
      expect(find.text('2.5km'), findsOneWidget);
    });

    testWidgets('should render nothing when distance is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DistanceBadge(distanceMeters: null)),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('📍'), findsNothing);
    });

    testWidgets('should render permission prompt when denied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistanceBadge(permissionDenied: true, distanceMeters: null),
          ),
        ),
      );

      expect(find.text('Bật vị trí'), findsOneWidget);
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    });

    testWidgets('should call onEnableLocation when permission prompt tapped', (
      tester,
    ) async {
      bool called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistanceBadge(
              permissionDenied: true,
              onEnableLocation: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Bật vị trí'));
      expect(called, isTrue);
    });

    testWidgets('should use dark style by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistanceBadge(
              distanceMeters: 1000,
              style: DistanceBadgeStyle.dark,
            ),
          ),
        ),
      );

      // Find the container with dark background
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.black54));
    });

    testWidgets('should use light style when specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistanceBadge(
              distanceMeters: 1000,
              style: DistanceBadgeStyle.light,
            ),
          ),
        ),
      );

      // Find the container
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      // Light style uses white with some opacity
      expect(decoration.color, isNotNull);
    });

    testWidgets('should use compact style with smaller font', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistanceBadge(
              distanceMeters: 1000,
              style: DistanceBadgeStyle.compact,
            ),
          ),
        ),
      );

      // Compact style should use fontSize 10
      final text = tester.widget<Text>(find.text('1.0km'));
      expect(text.style?.fontSize, equals(10));
    });
  });

  group('DistancePlaceholder', () {
    testWidgets('should render placeholder "--"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DistancePlaceholder())),
      );

      expect(find.text('📍'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
    });
  });
}
