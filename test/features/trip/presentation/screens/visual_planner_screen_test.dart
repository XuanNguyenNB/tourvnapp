import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/trip/presentation/helpers/visual_planner_snackbars.dart';
import 'package:tour_vn/features/trip/presentation/screens/visual_planner_screen.dart';

void main() {
  group('VisualPlannerScreen Widget Tests', () {
    testWidgets('renders screen without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: VisualPlannerScreen.fromPending()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app bar with back button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: VisualPlannerScreen.fromPending()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows empty-trip state when pending trip is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: VisualPlannerScreen.fromPending()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Không tìm thấy chuyến đi'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('VisualPlannerSnackBars Helper Tests', () {
    testWidgets('showSuccess displays snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VisualPlannerSnackBars.showSuccess(context),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showError displays snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VisualPlannerSnackBars.showError(context),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showError with custom message displays snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VisualPlannerSnackBars.showError(
                  context,
                  message: 'Test Error',
                ),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Test Error'), findsOneWidget);
    });

    testWidgets('showNotSaved displays snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VisualPlannerSnackBars.showNotSaved(context),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showUndoDelete displays snackbar with action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => VisualPlannerSnackBars.showUndoDelete(
                  context: context,
                  activityName: 'Test',
                  onUndo: () {},
                ),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(SnackBarAction), findsOneWidget);
    });

    testWidgets('showNotSupported displays snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    VisualPlannerSnackBars.showNotSupported(context),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
