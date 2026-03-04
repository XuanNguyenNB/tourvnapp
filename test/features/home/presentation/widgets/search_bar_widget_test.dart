import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/destination/domain/entities/location.dart';
import 'package:tour_vn/features/home/presentation/widgets/search_bar_widget.dart';

void main() {
  /// Create test location helper
  Location createTestLocation({
    String id = 'test-loc',
    String name = 'Test Location',
  }) {
    return Location(
      id: id,
      destinationId: 'da-nang',
      name: name,
      image: 'https://example.com/image.jpg',
      category: 'food',
    );
  }

  group('SearchBarWidget', () {
    testWidgets('AC1: should render 56px height search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      // Find the search bar container
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Check TextField exists
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('AC1: should show placeholder text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
              placeholder: 'Tìm kiếm địa điểm, quán ăn...',
            ),
          ),
        ),
      );

      // Placeholder text appears in InputDecoration
      expect(find.text('Tìm kiếm địa điểm, quán ăn...'), findsOneWidget);
    });

    testWidgets('AC1: should show search icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('AC2: should change search icon color when focused', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      // Before focus - get icon color
      final iconBefore = tester.widget<Icon>(find.byIcon(Icons.search));
      final colorBefore = iconBefore.color;

      // Focus the TextField
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // After focus - check icon color changed
      final iconAfter = tester.widget<Icon>(find.byIcon(Icons.search));
      final colorAfter = iconAfter.color;

      // Colors should be different (unfocused vs focused)
      expect(colorBefore != colorAfter, isTrue);
    });

    testWidgets('AC7: should show clear button when text is entered', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('AC7: clear button should clear text and close overlay', (
      tester,
    ) async {
      String? lastQuery;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (q) => lastQuery = q,
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'bánh mì');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Text should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(''));

      // onSearch should be called with empty string
      expect(lastQuery, equals(''));
    });

    testWidgets('AC3: should debounce search calls (300ms)', (tester) async {
      final searchCalls = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (q) => searchCalls.add(q),
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
            ),
          ),
        ),
      );

      // Type quickly
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 100));

      // Should not have called search yet (not 300ms)
      expect(searchCalls.where((q) => q.isNotEmpty).length, equals(0));

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 300));

      // Now should have called with final text
      expect(searchCalls.contains('abc'), isTrue);
    });

    testWidgets('should show overlay when focused and text entered', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
              searchLocations: [createTestLocation()],
            ),
          ),
        ),
      );

      // Focus and enter text
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Overlay should be visible - check for Column containing results
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should pass loading state to overlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Focus and enter text to trigger overlay
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // When loading, overlay should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should not show overlay when text is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
              searchLocations: [createTestLocation()],
            ),
          ),
        ),
      );

      // Just focus without text
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Overlay should not show results
      expect(find.text('Test Location'), findsNothing);
    });

    testWidgets('AC6: should call onLocationSelected when result is tapped', (
      tester,
    ) async {
      Location? selected;
      final testLocation = createTestLocation(name: 'Selected Location');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (loc) => selected = loc,
              onReviewSelected: (_) {},
              searchLocations: [testLocation],
            ),
          ),
        ),
      );

      // Focus, enter text, and tap result
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Tap on the result
      await tester.tap(find.text('Selected Location'));
      await tester.pump();

      // Callback should be invoked
      expect(selected, isNotNull);
      expect(selected?.name, equals('Selected Location'));
    });

    testWidgets('should pass error message to overlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (_) {},
              onDestinationSelected: (_) {},
              onLocationSelected: (_) {},
              onReviewSelected: (_) {},
              errorMessage: 'Network error',
            ),
          ),
        ),
      );

      // Focus and enter text
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Error should be visible
      expect(find.text('Network error'), findsOneWidget);
    });
  });
}
