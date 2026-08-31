import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/widgets/states/error_state.dart';

void main() {
  Widget wrapInApp(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  group('ErrorState', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ErrorState(
          message: 'Something went wrong',
          onRetry: SizedBox.shrink,
        ),
      ));

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays Oops title', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ErrorState(
          message: 'Error',
          onRetry: SizedBox.shrink,
        ),
      ));

      expect(find.text('Oops!'), findsOneWidget);
    });

    testWidgets('displays error icon', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ErrorState(
          message: 'Error',
          onRetry: SizedBox.shrink,
        ),
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('retry button calls onRetry', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(wrapInApp(
        ErrorState(
          message: 'Error',
          onRetry: () => retryCalled = true,
        ),
      ));

      await tester.tap(find.text('Retry'));
      expect(retryCalled, true);
    });

    testWidgets('displays different messages', (tester) async {
      await tester.pumpWidget(wrapInApp(
        const ErrorState(
          message: 'Local network access is required',
          onRetry: SizedBox.shrink,
        ),
      ));

      expect(find.text('Local network access is required'), findsOneWidget);
    });
  });
}
