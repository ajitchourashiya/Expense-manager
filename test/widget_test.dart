import 'package:flutter_test/flutter_test.dart';

import 'package:sumit_cash_flow/core/app.dart';

void main() {
  testWidgets('Expense Manager app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ExpenseManagerApp(),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ExpenseManagerApp), findsOneWidget);
  });
}
