import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_vn/features/auth/presentation/widgets/sign_in_prompt_bottom_sheet.dart';

void main() {
  group('SignInPromptBottomSheet', () {
    late bool onSignInSuccessCalled;
    late bool onDismissCalled;

    setUp(() {
      onSignInSuccessCalled = false;
      onDismissCalled = false;
    });

    Widget createWidget({
      VoidCallback? onSignInSuccess,
      VoidCallback? onDismiss,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SignInPromptBottomSheet(
                      onSignInSuccess:
                          onSignInSuccess ??
                          () {
                            onSignInSuccessCalled = true;
                          },
                      onDismiss:
                          onDismiss ??
                          () {
                            onDismissCalled = true;
                          },
                    ),
                  );
                },
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders all required UI elements', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify drag handle exists
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 40 &&
              widget.constraints?.maxHeight == 4,
        ),
        findsOneWidget,
      );

      // Verify icon exists
      expect(find.byIcon(Icons.bookmark_add_rounded), findsOneWidget);

      // Verify title text in Vietnamese
      expect(find.text('Đăng nhập để lưu chuyến đi'), findsOneWidget);

      // Verify subtitle text in Vietnamese
      expect(
        find.text('Chuyến đi sẽ được đồng bộ trên mọi thiết bị của bạn'),
        findsOneWidget,
      );

      // Verify Google sign-in button
      expect(find.text('Đăng nhập với Google'), findsOneWidget);

      // Verify Facebook sign-in button
      expect(find.text('Đăng nhập với Facebook'), findsOneWidget);

      // Verify dismiss button
      expect(find.text('Để sau'), findsOneWidget);
    });

    testWidgets('dismiss button calls onDismiss callback', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Tap dismiss button
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();

      // Verify onDismiss was called
      expect(onDismissCalled, isTrue);
    });

    testWidgets('bottom sheet closes when dismiss is tapped', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet is shown
      expect(find.text('Đăng nhập để lưu chuyến đi'), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();

      // Verify sheet is closed
      expect(find.text('Đăng nhập để lưu chuyến đi'), findsNothing);
    });

    testWidgets('Google sign-in button is tappable', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify Google button exists and is enabled
      final googleButton = find.widgetWithText(
        ElevatedButton,
        'Đăng nhập với Google',
      );
      expect(googleButton, findsOneWidget);

      // Check button is not disabled
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Đăng nhập với Google'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Facebook sign-in button is tappable', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify Facebook button exists and is enabled
      final facebookButton = find.widgetWithText(
        ElevatedButton,
        'Đăng nhập với Facebook',
      );
      expect(facebookButton, findsOneWidget);

      // Check button is not disabled
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Đăng nhập với Facebook'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('has proper border radius', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Find the container with border radius
      final container = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          final borderRadius = decoration.borderRadius;
          if (borderRadius is BorderRadius) {
            return borderRadius.topLeft.x == 24 &&
                borderRadius.topRight.x == 24;
          }
        }
        return false;
      });

      expect(container, findsOneWidget);
    });

    testWidgets('icon has gradient background', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Find container with gradient
      final gradientContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.gradient != null;
        }
        return false;
      });

      expect(gradientContainer, findsAtLeast(1));
    });
  });
}
